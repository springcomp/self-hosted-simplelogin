#!/bin/sh

postconf maillog_file=/dev/stdout
postconf myhostname=app.${DOMAIN}
postconf mydomain=${DOMAIN}
postconf myorigin=${DOMAIN}

# Rely on the Postfix 3.4+ default master.cf containing the line
# 'postlog   unix-dgram [...]'

exec /usr/sbin/postfix start-fg "$@"
