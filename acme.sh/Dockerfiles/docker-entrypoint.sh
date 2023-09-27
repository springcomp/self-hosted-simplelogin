#!/bin/bash

directory_path="/root/.acme.sh/*.${DOMAIN}_ecc"
challenge="${ACME_CHALLENGE}"
staging="${LE_STAGING}"

request_zerossl_certificate() {

  params=( acme.sh --issue --force --log --renew-hook \"docker restart nginx\" --email contact@$DOMAIN )

  if [ $staging = 'true' ]; then
    params=( "${params[@]}" --debug --staging)
  fi

  if [ $challenge = 'HTTP-01' ]; then

    echo 'Requesting bootstrap zerossl certificates using HTTP-01 ACME challenge'
    params=( "${params[@]}" --domain $DOMAIN \ --webroot /var/www/acme.sh/ )
    
  fi

  if [ $challenge = 'DNS-01' ]; then

    echo 'Requesting bootstrap zerossl certificates using DNS-01 ACME challenge against Azure DNS'
    params=( "${params[@]}" --domain *.$DOMAIN --domain $DOMAIN --dns dns_azure )
    
  fi

  eval "${params[@]}"
  docker restart nginx
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

