#!/bin/env bash

ere_quote() {
  # this escapes regex reserved characters
  # it also escape / for subsequent use with sed
  sed 's/[][\/\.|$(){}?+*^]/\\&/g' <<< "$*"
}

DOMAIN=$(grep "^DOMAIN" .env | awk -F '=' '{print $2}')
PG_USERNAME=$(grep "^POSTGRES_USER" .env | awk -F '=' '{print $2}')
PG_PASSWORD=$(grep "^POSTGRES_PASSWORD" .env | awk -F '=' '{print $2}')

sed -i -e "s/domain.tld/${DOMAIN}/g" ./acme.sh/www/.well-known/mta-sts.txt
sed -i -e "s/domain.tld/${DOMAIN}/g" ./nginx/conf.d/default.conf
sed -i -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/main.cf
sed -i -e "s/myuser/${PG_USERNAME}/g" ./postfix/conf.d/pgsql-relay-domains.cf
sed -i -e "s/mypassword/$(ere_quote ${PG_PASSWORD})/g" ./postfix/conf.d/pgsql-relay-domains.cf
sed -i -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/pgsql-relay-domains.cf
sed -i -e "s/myuser/${PG_USERNAME}/g" ./postfix/conf.d/pgsql-transport-maps.cf
sed -i -e "s/mypassword/$(ere_quote ${PG_PASSWORD})/g" ./postfix/conf.d/pgsql-transport-maps.cf
sed -i -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/pgsql-transport-maps.cf

docker compose up --detach
