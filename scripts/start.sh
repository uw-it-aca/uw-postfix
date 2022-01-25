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

if [ ! -e '/var/spool/postfix/etc/services' ]
then
    echo "exec: ln -s /etc/services /var/spool/postfix/etc/"
    ln -s /etc/services /var/spool/postfix/etc/
fi

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

echo "Starting postfix in foreground"
/usr/sbin/postfix start-fg

echo "Postfix finished ($?)"
