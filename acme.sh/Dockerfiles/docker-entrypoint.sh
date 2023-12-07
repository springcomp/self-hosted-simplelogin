#!/bin/bash

challenge="${ACME_CHALLENGE}"
dns_api="${ACME_SH_DNS_API}"
server="${ACME_SERVER}"
staging="${LE_STAGING}"

request_server_certificate() {

  params=( acme.sh --issue --force --log --renew-hook \"docker restart nginx\" --email contact@$DOMAIN --server $server )

  if [ $staging = 'true' ]; then
    params=( "${params[@]}" --debug --staging)
  fi

  if [ $challenge = 'HTTP-01' ]; then

    echo 'Requesting bootstrap certificates using HTTP-01 ACME challenge'
    params=( "${params[@]}" --domain $DOMAIN --domain app.$DOMAIN --domain mta-sts.$DOMAIN \ --webroot /var/www/ )

  fi

  if [ $challenge = 'DNS-01' ]; then

    echo "Requesting bootstrap $server certificates using DNS-01 ACME challenge using acme.sh DNS API"
    params=( "${params[@]}" --domain *.$DOMAIN --domain $DOMAIN --dns $dns_api )

  fi

  echo "${params[@]}"
  eval "${params[@]}"
  mv /etc/nginx/conf.d/nginx /etc/nginx/conf.d/default.conf
  docker restart nginx
}


renew_server_certificate() {
  echo "Renewing $server certificate..."
  acme.sh --cron
}

directory_path="/root/.acme.sh/*.${DOMAIN}_ecc"
if [ $challenge = 'HTTP-01' ]; then
  directory_path="/root/.acme.sh/${DOMAIN}_ecc"
fi

[ -d "$directory_path" ] || request_server_certificate

trap exit TERM
while :
do
  renew_server_certificate
  sleep 6h
done
