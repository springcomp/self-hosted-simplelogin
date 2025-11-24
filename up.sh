#!/bin/env bash

ere_quote() {
  # this escapes regex reserved characters
  # it also escapes / for subsequent use with sed
  sed 's/[][\/\.|$(){}?+*^]/\\&/g' <<< "$*"
}

has_wildcard_san() {
  cert="$1"    # Pfad zu .crt oder fullchain
  domain="$2"  # z.B. domain.tld
  openssl x509 -in "$cert" -noout -text 2>/dev/null | grep -E -q 'DNS:[[:space:]]*\*\.'"$domain"'(,|$)' >/dev/null
}

DOMAIN=$(grep "^DOMAIN" .env | awk -F '=' '{print $2}')
SUBDOMAIN=$(grep "^SUBDOMAIN" .env | awk -F '=' '{print $2}')
PG_USERNAME=$(grep "^POSTGRES_USER" .env | awk -F '=' '{print $2}')
PG_PASSWORD=$(grep "^POSTGRES_PASSWORD" .env | awk -F '=' '{print $2}')

if [ -z "$DOMAIN" ]; then
  echo "ERROR: ENV Var DOMAIN must be set!"
  exit 1
fi

if [ -z "$SUBDOMAIN" ]; then
  SUBDOMAIN="app"
fi

sed -e "s/app.domain.tld/${SUBDOMAIN}.${DOMAIN}/g" -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/main.cf.tpl > ./postfix/conf.d/main.cf

if dig +short DS "$DOMAIN" | grep -q .; then
  echo "DNSSEC DS record found for $DOMAIN"
  # Enable DANE + DNSSEC in Postfix
  sed -i \
      -e 's/^smtp_dns_support_level.*/smtp_dns_support_level = dnssec/' \
      -e 's/^smtp_tls_security_level.*/smtp_tls_security_level = dane/' \
      ./postfix/conf.d/main.cf

  # If entries do not exist, append them
  grep -q "^smtp_dns_support_level" ./postfix/conf.d/main.cf || \
      echo "smtp_dns_support_level = dnssec" >> ./postfix/conf.d/main.cf

  grep -q "^smtp_tls_security_level" ./postfix/conf.d/main.cf || \
      echo "smtp_tls_security_level = dane" >> ./postfix/conf.d/main.cf

  echo "Postfix updated: DANE enabled."
fi

CERT_SUB="/certs/${SUBDOMAIN}.${DOMAIN}"
CERT_DOMAIN="/certs/${DOMAIN}"

if [ -s $CERT_DOMAIN.fullchain.pem ] && ( [ ! -s $CERT_SUB.fullchain.pem ] || has_wildcard_san $CERT_DOMAIN.fullchain.pem $DOMAIN); then
  sed -i -e "s,${CERT_SUB},${CERT_DOMAIN},g" ./postfix/conf.d/main.cf
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
