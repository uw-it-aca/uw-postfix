#!/bin/bash
set -e

if [ ! -d '/var/spool/postfix/etc' ]
then
  mkdir /var/spool/postfix/etc
fi

if [ ! -e '/var/spool/postfix/etc/services' ]
then
    ln -s /etc/services /var/spool/postfix/etc/
fi

/usr/sbin/postfix start-fg
