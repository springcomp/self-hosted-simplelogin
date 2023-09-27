#!/bin/sh

directory_path="/root/.acme.sh/*.${DOMAIN}_ecc"
challenge="${ACME_CHALLENGE}"

request_zerossl_certificate() {

  if [ $challenge = 'HTTP-01' ]; then

    echo 'Requesting bootstrap zerossl certificates using HTTP-01 ACME challenge'
    
    acme.sh --issue \
      --force \
      --debug --staging --log \
      --renew-hook "docker restart nginx" \
      --email contact@$DOMAIN \
      --domain $DOMAIN \
      --webroot /var/www/acme.sh/

  else

    echo 'Requesting bootstrap zerossl certificates using DNS-01 ACME challenge against Azure DNS'

    acme.sh --issue \
      --force \
      --debug --staging --log \
      --renew-hook "docker restart nginx" \
      --email contact@$DOMAIN \
      --domain *.$DOMAIN --domain $DOMAIN \
      --dns dns_azure
  fi
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

