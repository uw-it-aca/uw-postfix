#!/bin/bash
set -e

# telemetry
echo "startup telemetry"
echo -n "whoami: "
whoami

echo -n "ls /scripts:"
ls -l /scripts

if [ ! -d '/var/spool/postfix/etc' ]
then
  echo "exec: mkdir /var/spool/postfix/etc"
  mkdir /var/spool/postfix/etc
fi

POSTFIX_SPOOL=/var/spool/postfix

echo "copy system files to chroot'd dir"
SYS_FILES=("/etc/resolv.conf"
           "/etc/services")
for SYS_FILE in ${SYS_FILES[*]}
do
  SYS_FILE_DEST=${POSTFIX_SPOOL}${SYS_FILE}
  # be sure they're fresh
  if [ -e ${SYS_FILE_DEST} ]
  then
      echo "exec: rm ${SYS_FILE_DEST}"
      rm ${SYS_FILE_DEST}
  fi
  echo "exec: cp -p ${SYS_FILE} ${SYS_FILE_DEST}"
  cp -p ${SYS_FILE} ${SYS_FILE_DEST}
done

CONFIG_FILE_DIRECTORY=/config
CONFIG_TEMPLATE_EXTENSION=tpl
CONFIG_FILE_EXTENSION=cf
echo "processing templates in ${CONFIG_FILE_DIRECTORY}:"
for CFG_TEMPLATE_IN in $(echo ${CONFIG_FILE_DIRECTORY}/*.${CONFIG_TEMPLATE_EXTENSION})
do
    echo " ${CFG_TEMPLATE_IN}"
    awk '{
           while (match($0,"[$]{[^}]*}")) {
             var = substr($0,RSTART+2,RLENGTH -3)
             gsub("[$]{"var"}",ENVIRON[var])
           }
         }1' < $CFG_TEMPLATE_IN  > ${CONFIG_FILE_DIRECTORY}/$(basename -s .${CONFIG_TEMPLATE_EXTENSION} $CFG_TEMPLATE_IN).${CONFIG_FILE_EXTENSION}
done

echo "config files: "
ls -l $CONFIG_FILE_DIRECTORY

# verify /var/spool/postfix directories
POSTFIX_DIRECTORIES=("active"
                     "bounce"
                     "corrupt"
                     "defer"
                     "deferred"
                     "dev"
                     "etc"
                     "flush"
                     "incoming"
                     "lib"
                     "maildrop"
                     "pid"
                     "private"
                     "public"
                     "saved"
                     "usr")
POSTFIX_ROOT_ROOT_ONLY=("dev"
                        "etc"
                        "lib"
                        "pid")
POSTFIX_POSTFIX_ROOT_ONLY=("active"
                           "bounce"
                           "corrupt"
                           "defer"
                           "deferred"
                           "flush"
                           "incoming"
                           "private"
                           "saved")
POSTFIX_POSTDROP_MAILDROP=("maildrop"
                  "public")
POSTFIX_USR_SUBDIRS=("lib"
                     "lib/sasl2"
                     "lib/zoneinfo")
for POSTFIX_DIR in ${POSTFIX_DIRECTORIES[*]}
do
    POSTFIX_DIR_PATH=${POSTFIX_SPOOL}/${POSTFIX_DIR}
    mkdir -p $POSTFIX_DIR_PATH
    if [[ " ${POSTFIX_ROOT_ROOT_ONLY[*]} " =~ " $POSTFIX_DIR " ]];
    then
        chmod u=rwx,go=rx $POSTFIX_DIR_PATH
    elif [[ " ${POSTFIX_POSTFIX_ROOT_ONLY[*]} " =~ " $POSTFIX_DIR " ]];
    then
        chown postfix $POSTFIX_DIR_PATH
        chmod u=rwx,go= $POSTFIX_DIR_PATH
    else
        case $POSTFIX_DIR in
            usr)
                chmod u=rwx,go=rx $POSTFIX_DIR_PATH
                for POSTFIX_USR_SUBDIR in ${POSTFIX_USR_SUBDIRS[*]}
                do
                    POSTFIX_USR_SUBDIR_PATH=${POSTFIX_DIR_PATH}/${POSTFIX_USR_SUBDIR}
                    mkdir -p $POSTFIX_USR_SUBDIR_PATH
                    chmod u=rwx,go=rx $POSTFIX_USR_SUBDIR_PATH
                done
                ;;
             maildrop)
                chown postfix $POSTFIX_DIR_PATH
                chmod u=rwx,g=wx,+t $POSTFIX_DIR_PATH
                ;;
             public)
                 chown postfix $POSTFIX_DIR_PATH
                 chmod u=rwx,g+s,o= $POSTFIX_DIR_PATH
                 ;;
        esac
    fi
done

echo "Verify postfix configuration"
/usr/sbin/postfix check

echo "Starting postfix in foreground"
/usr/sbin/postfix start-fg

echo "Postfix finished ($?)"
