#!/bin/sh -eu

# perform recursive resolution starting from DNS root servers:
curl -o /opt/unbound/etc/unbound/var/root.hints https://www.internic.net/domain/named.root

# redirect logfile to stdout
rm /opt/unbound/etc/unbound/var/unbound.log
ln -sf /dev/stdout /opt/unbound/etc/unbound/var/unbound.log

# hand over to container CMD (/unbound.sh)
exec "$@"
