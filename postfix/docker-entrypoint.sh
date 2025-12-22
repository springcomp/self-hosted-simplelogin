#!/bin/sh -eu

# expected ENV (injected by container runtime)
: "${DOMAIN:?Need DOMAIN}"
SUBDOMAIN="${SUBDOMAIN:-app}"
PG_USERNAME="${POSTGRES_USER:?Need POSTGRES_USER}"
PG_PASSWORD="${POSTGRES_PASSWORD:?Need POSTGRES_PASSWORD}"

# define paths (templates, config)
TEMPLATE_DIR="/templates"
MAIL_CONFIG="/etc/postfix/conf.d"

SPAMHAUS_DQS_KEY="${SPAMHAUS_DQS_KEY:-}"

CERT_SUB="/certs/${SUBDOMAIN}.${DOMAIN}"
CERT_DOMAIN="/certs/${DOMAIN}"

ere_quote() {
  # this escapes regex reserved characters
  # it also escapes / for subsequent use with sed
  # shellcheck disable=SC1117
  printf '%s' "$1" | sed 's/[][\/\.|$(){}?+*^]/\\&/g'
}

has_wildcard_san() {
  cert="$1"    # path to .crt or fullchain
  domain="$2"  # i.e. domain.tld
  openssl x509 -in "$cert" -noout -text 2>/dev/null | grep -E -q 'DNS:[[:space:]]*\*\.'"$domain"'(,|$)' >/dev/null
}

check_spamhaus_dns() {
  TEST_IP="$(wget -qO- https://api.ipify.org 2>/dev/null || true)"
  [ ! -z "$TEST_IP" ] || TEST_IP="8.8.8.8"

  REV="$(echo "$TEST_IP" | awk -F. '{print $4"."$3"."$2"."$1}')"
  OUT="$(dig +time=3 +tries=1 A "$REV.zen.spamhaus.org" 2>&1 || true)"

  # hard error => not usable
  echo "$OUT" | grep -qiE 'SERVFAIL|REFUSED|timed out|connection timed out' && return 1

  # Spamhaus policy / query refused
  echo "$OUT" | grep -q '127.255.255.254' && return 1

  # NXDOMAIN -> okay (not listet, or lookup answered)
  echo "$OUT" | grep -q 'status: NXDOMAIN' && return 0

  # NOERROR and 127.0.0.x -> lookup works
  echo "$OUT" | grep -qE '127\.0\.0\.[0-9]+' && return 0

  # NOERROR without answer (NODATA) -> ok for us
  echo "$OUT" | grep -q 'status: NOERROR' && return 0

  # all other response types: stay conservative, do not use spamhaus
  return 1
}

# generate main.cf from templates
[ -f "$TEMPLATE_DIR/main.cf.tpl" ] && rm "$TEMPLATE_DIR/main.cf.tpl"
find "$TEMPLATE_DIR" -type f -name '*-icf-*.tpl' | sed 's:.*/::' | sort -t- -k1,1n | while read -r f; do
  cat "$TEMPLATE_DIR/$f"
  printf '\n'
done > "$TEMPLATE_DIR/main.cf.tpl"

sed \
  -e "s/app.domain.tld/${SUBDOMAIN}.${DOMAIN}/g" \
  -e "s/domain.tld/${DOMAIN}/g" \
  "$TEMPLATE_DIR/main.cf.tpl" > "$MAIL_CONFIG/main.cf"

if [ -s $CERT_DOMAIN.fullchain.pem ] && ( [ ! -s $CERT_SUB.fullchain.pem ] || has_wildcard_san $CERT_DOMAIN.fullchain.pem $DOMAIN); then
  sed -i -e "s,${CERT_SUB},${CERT_DOMAIN},g" "$MAIL_CONFIG/main.cf"
fi

if dig +short DS "${DOMAIN}" | grep -q .; then
  # Enable DNSSEC in Postfix
  sed -i \
      -e 's/^smtp_dns_support_level.*/smtp_dns_support_level = dnssec/' \
      "$MAIL_CONFIG/main.cf"

  # If entry does not exist, append it
  grep -q "^smtp_dns_support_level" "$MAIL_CONFIG/main.cf" || \
      echo "smtp_dns_support_level = dnssec" >> "$MAIL_CONFIG/main.cf"

  echo "DNSSEC DS record found for ${DOMAIN}: Postfix updated, DNSSEC enabled."
fi

# generate optional files only if they do not exist
[ -f "$MAIL_CONFIG/virtual" ] || \
  sed -e "s/domain.tld/${DOMAIN}/g" \
  "$TEMPLATE_DIR/virtual.tpl" > "$MAIL_CONFIG/virtual"

[ -f "$MAIL_CONFIG/virtual-regexp" ] || \
  sed -e "s/domain.tld/${DOMAIN}/g" \
  "$TEMPLATE_DIR/virtual-regexp.tpl" > "$MAIL_CONFIG/virtual-regexp"

# generate pgsql related config
PW_ESCAPED="$(ere_quote "$PG_PASSWORD")"

sed \
  -e "s/myuser/${PG_USERNAME}/g" \
  -e "s/mypassword/${PW_ESCAPED}/g" \
  -e "s/domain.tld/${DOMAIN}/g" \
  "$TEMPLATE_DIR/pgsql-relay-domains.cf.tpl" > "$MAIL_CONFIG/pgsql-relay-domains.cf"

sed \
  -e "s/myuser/${PG_USERNAME}/g" \
  -e "s/mypassword/${PW_ESCAPED}/g" \
  -e "s/domain.tld/${DOMAIN}/g" \
  "$TEMPLATE_DIR/pgsql-transport-maps.cf.tpl" > "$MAIL_CONFIG/pgsql-transport-maps.cf"

[ -f "$MAIL_CONFIG/aliases" ] && postalias $MAIL_CONFIG/aliases
[ -f "$MAIL_CONFIG/virtual" ] && postmap $MAIL_CONFIG/virtual

if [ -n "$SPAMHAUS_DQS_KEY" ]; then
  # use provided DQS_KEY, disable public mirror
  sed -i -e '/spamhaus.org/d' "$MAIL_CONFIG/main.cf"
  sed -i "s/your_DQS_key/${SPAMHAUS_DQS_KEY}/g" "$MAIL_CONFIG/main.cf"

  if [ -f "$TEMPLATE_DIR/dnsbl-reply-map.tpl" ]; then
    sed "s/your_DQS_key/${SPAMHAUS_DQS_KEY}/g" \
      "$TEMPLATE_DIR/dnsbl-reply-map.tpl" > "$MAIL_CONFIG/dnsbl-reply-map"
    postmap "$MAIL_CONFIG/dnsbl-reply-map"
  fi
  echo "Configured DSNBL using Spamhaus Data Query Service (DQS)."
elif check_spamhaus_dns; then
  # use public mirrors
  sed -i -e '/your_DQS_key/d' -e '/dnsbl-reply-map/d' "$MAIL_CONFIG/main.cf"
  echo "Configured DNSBL using Spamhaus public mirrors."
else
  # disable spamhaus completely
  sed -i -e '/spamhaus/d' -e '/dnsbl-reply-map/d' "$MAIL_CONFIG/main.cf"
  echo "Spamhaus DSNBL checks disabled."
fi

# hand over to container CMD (postfix start-fg)
exec "$@"
