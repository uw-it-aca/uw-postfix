#!/bin/bash
set -e

if [ ! -d '/var/spool/postfix/etc' ]
then
  mkdir /var/spool/postfix/etc
fi

ln -s /var/spool/postfix/etc/services /etc/services

/usr/sbin/postfix start-fg
