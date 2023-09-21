#!/bin/sh

directory_path="/root/.acme.sh/*.${DOMAIN}_ecc"

request_zerossl_certificate() {
  ## echo 'Requesting bootstrap zerossl certificates using acme-challenge'
  ## acme.sh --issue \
  ##   --force \
  ##   --debug --staging --log \
  ##   --email contact@$DOMAIN \
  ##   --domain $DOMAIN \
  ##   --webroot /var/www/acme.sh/

  echo 'Requesting bootstrap zerossl certificates using Azure DNS challenge'
  acme.sh --issue \
    --force \
    --log \
    --email contact@$DOMAIN \
    --domain *.$DOMAIN --domain $DOMAIN \
    --dns dns_azure
}


renew_zerossl_certificate() {
  echo 'Renewing zerossl certificate...'
  acme.sh --cron
}

[ -d "$directory_path" ] || request_zerossl_certificate

trap exit TERM
while :
do
  renew_zerossl_certificate
  sleep 6h
done

