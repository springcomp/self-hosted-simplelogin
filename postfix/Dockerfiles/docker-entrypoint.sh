#!/usr/bin/env sh

[ -f "/etc/postfix/conf.d/aliases" ] && postalias /etc/postfix/conf.d/aliases
[ -f "/etc/postfix/conf.d/virtual" ] && postmap /etc/postfix/conf.d/virtual

/usr/sbin/postfix start-fg
