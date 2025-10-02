#!/bin/env bash

ere_quote() {
  # this escapes regex reserved characters
  # it also escapes / for subsequent use with sed
  sed 's/[][\/\.|$(){}?+*^]/\\&/g' <<< "$*"
}

has_wildcard_san() {
  cert="$1"    # Pfad zu .crt oder fullchain
  domain="$2"  # z.B. domain.tld
  openssl x509 -in "$cert" -noout -text 2>/dev/null | grep "DNS:*.$domain" >/dev/null
}

DOMAIN=$(grep "^DOMAIN" .env | awk -F '=' '{print $2}')
SUBDOMAIN=$(grep "^SUBDOMAIN" .env | awk -F '=' '{print $2}')
PG_USERNAME=$(grep "^POSTGRES_USER" .env | awk -F '=' '{print $2}')
PG_PASSWORD=$(grep "^POSTGRES_PASSWORD" .env | awk -F '=' '{print $2}')

if [ -z "$SUBDOMAIN" ]; then
  SUBDOMAIN="app"
fi

sed -e "s/app.domain.tld/${SUBDOMAIN}.${DOMAIN}/g" -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/main.cf.tpl > ./postfix/conf.d/main.cf

CERT_SUB="/certs/${SUBDOMAIN}.domain.tld.fullchain.pem"
CERT_DOMAIN="/certs/domain.tld.fullchain.pem"

if [ -s $CERT_DOMAIN ] && ( [ ! -s $CERT_SUB ] || has_wildcard_san $CERT_DOMAIN $DOMAIN); then
  sed -i -e "s/${CERT_SUB}/${CERT_DOMAIN}/g" ./postfix/conf.d/main.cf
fi

if [ ! -f ./postfix/conf.d/virtual ]; then
  sed -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/virtual.tpl > ./postfix/conf.d/virtual
fi
if [ ! -f ./postfix/conf.d/virtual-regexp ]; then
  sed -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/virtual-regexp.tpl > ./postfix/conf.d/virtual-regexp
fi

sed -e "s/myuser/${PG_USERNAME}/g" ./postfix/conf.d/pgsql-relay-domains.cf.tpl >./postfix/conf.d/pgsql-relay-domains.cf
sed -i -e "s/mypassword/$(ere_quote ${PG_PASSWORD})/g" ./postfix/conf.d/pgsql-relay-domains.cf
sed -i -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/pgsql-relay-domains.cf

sed -e "s/myuser/${PG_USERNAME}/g" ./postfix/conf.d/pgsql-transport-maps.cf.tpl >./postfix/conf.d/pgsql-transport-maps.cf
sed -i -e "s/mypassword/$(ere_quote ${PG_PASSWORD})/g" ./postfix/conf.d/pgsql-transport-maps.cf
sed -i -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/pgsql-transport-maps.cf

## use `--remove-orphans` to remove nginx container from previous versions, to free up ports 80/443 for traefik
docker compose up --remove-orphans --detach $@
