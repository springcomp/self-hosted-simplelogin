#!/bin/env bash

DOMAIN=$(grep "^DOMAIN" .env | awk -F '=' '{print $2}')

sed -i -e "s/domain.tld/${DOMAIN}/g" ./acme.sh/www/.well-known/mta-sts.txt
sed -i -e "s/domain.tld/${DOMAIN}/g" ./nginx/conf.d/default.conf

#docker compose up --detach
