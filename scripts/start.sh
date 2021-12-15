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

echo "config files: "
ls -l /config

echo "/cofig/main.cf"
cat /config/main.cf


echo "Starting postfix"
/usr/sbin/postfix start-fg
