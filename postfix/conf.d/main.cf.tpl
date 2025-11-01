# POSTFIX config file, adapted for SimpleLogin
smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 2 on
# fresh installs.
compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/certs/app.domain.tld.fullchain.pem
smtpd_tls_key_file=/certs/app.domain.tld.key
smtpd_tls_session_cache_database = lmdb:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = lmdb:${data_directory}/smtp_scache
smtp_tls_security_level = may
smtpd_tls_security_level = may

# Harden TLS: disallow legacy protocol versions and weak ciphers.
# - disable SSLv2/SSLv3 and TLSv1.0/TLSv1.1
# - prefer "high" cipher suites and explicitly exclude known-weak ciphers
# These settings apply to both the server (smtpd_*) and client (smtp_*) sides.
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1

smtpd_tls_ciphers = high
smtpd_tls_mandatory_ciphers = high
smtp_tls_ciphers = high
smtp_tls_mandatory_ciphers = high

# Explicitly exclude weak ciphers and primitives
smtpd_tls_mandatory_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP, kRSA
smtp_tls_mandatory_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP, kRSA

# Also exclude these ciphers for opportunistic/non-mandatory TLS negotiations
smtpd_tls_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP, kRSA
smtp_tls_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP, kRSA

# Log TLS negotiation failures and usage
smtpd_tls_loglevel = 1


# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.

alias_maps = lmdb:/etc/postfix/conf.d/aliases
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 10.0.0.0/24

# set domain here
myhostname = app.domain.tld
mydomain = domain.tld
myorigin = domain.tld

relay_domains = pgsql:/etc/postfix/conf.d/pgsql-relay-domains.cf
transport_maps = pgsql:/etc/postfix/conf.d/pgsql-transport-maps.cf

# HELO restrictions
smtpd_delay_reject = yes
smtpd_helo_required = yes
smtpd_helo_restrictions =
    permit_mynetworks,
    reject_non_fqdn_helo_hostname,
    reject_invalid_helo_hostname,
    permit

# Sender restrictions:
smtpd_sender_restrictions =
    permit_mynetworks,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain,
    permit

# Recipient restrictions:
smtpd_recipient_restrictions =
   reject_unauth_pipelining,
   reject_non_fqdn_recipient,
   reject_unknown_recipient_domain,
   permit_mynetworks,
   reject_unauth_destination,
   reject_rbl_client zen.spamhaus.org,
   reject_rbl_client bl.spamcop.net,
   permit

# Log output
maillog_file=/dev/stdout

virtual_alias_domains = 
virtual_alias_maps = lmdb:/etc/postfix/conf.d/virtual, regexp:/etc/postfix/conf.d/virtual-regexp
