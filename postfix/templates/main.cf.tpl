# POSTFIX config file, adapted for SimpleLogin
smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# Increase max. mail size limit from default 10M to 25M
message_size_limit=26214400

# ---- Modern compatibility level ----
# Enables modern, secure Postfix defaults for TLS, ciphers, logging, and behavior.
compatibility_level = 3.6

# ---- Certificate configuration ----
smtpd_tls_cert_file = /certs/app.domain.tld.fullchain.pem
smtpd_tls_key_file  = /certs/app.domain.tld.key

# ---- Enable TLS for inbound and outbound SMTP ----
# "may" = Opportunistic TLS: offer TLS but do not require it.
smtpd_tls_security_level = may
smtp_tls_security_level  = may

# TLS session caching (LMDB is fast and modern)
smtpd_tls_session_cache_database = lmdb:${data_directory}/smtpd_scache
smtp_tls_session_cache_database  = lmdb:${data_directory}/smtp_scache

# ---- Allowed protocol versions ----
# Only allow TLSv1.2 and TLSv1.3 (older versions are insecure or deprecated).
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols  = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1

# ---- Cipher suites ----
# "medium" is sufficient and balanced; OpenSSL >= 1.1.1 already enforces secure defaults.
# "high" is unnecessarily restrictive and may reduce compatibility without adding security.
smtpd_tls_mandatory_ciphers = medium
smtp_tls_mandatory_ciphers  = medium

# Explicitly exclude known-weak ciphers (mostly redundant with modern OpenSSL).
smtpd_tls_mandatory_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP
smtp_tls_mandatory_exclude_ciphers  = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP

# ---- Perfect Forward Secrecy / Key exchange ----
# No manual DH parameter files are needed; OpenSSL automatically uses secure
# ECDHE or RFC 7919 FFDHE groups.
smtpd_tls_eecdh_grade = strong

# ---- Additional TLS hardening ----
# Prefer server cipher order and disable TLS compression/renegotiation
# to prevent CRIME and renegotiation attacks.
tls_preempt_cipherlist = yes
tls_ssl_options = NO_COMPRESSION, NO_RENEGOTIATION

# ---- Logging ----
# Log TLS negotiations; set to 2 for more detailed debugging if needed.
smtpd_tls_loglevel = 1

# Adds TLS information to Received: headers (optional but useful for diagnostics)
smtpd_tls_received_header = yes

alias_maps = lmdb:/etc/postfix/conf.d/aliases
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 10.0.0.0/24

# set domain here
myhostname = app.domain.tld
mydomain = domain.tld
myorigin = domain.tld

relay_domains = pgsql:/etc/postfix/conf.d/pgsql-relay-domains.cf
transport_maps = pgsql:/etc/postfix/conf.d/pgsql-transport-maps.cf

rbl_reply_maps = lmdb:/etc/postfix/conf.d/dnsbl-reply-map

disable_vrfy_command = yes

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
   reject_rbl_client your_DQS_key.zen.dq.spamhaus.net=127.0.0.[2..11],
   reject_rhsbl_sender your_DQS_key.dbl.dq.spamhaus.net=127.0.1.[2..99],
   reject_rhsbl_helo your_DQS_key.dbl.dq.spamhaus.net=127.0.1.[2..99],
   reject_rhsbl_reverse_client your_DQS_key.dbl.dq.spamhaus.net=127.0.1.[2..99],
   reject_rhsbl_sender your_DQS_key.zrd.dq.spamhaus.net=127.0.2.[2..24],
   reject_rhsbl_helo your_DQS_key.zrd.dq.spamhaus.net=127.0.2.[2..24],
   reject_rhsbl_reverse_client your_DQS_key.zrd.dq.spamhaus.net=127.0.2.[2..24],
   reject_rbl_client bl.spamcop.net,
   permit

# Log output
maillog_file=/dev/stdout

virtual_alias_domains = 
virtual_alias_maps = lmdb:/etc/postfix/conf.d/virtual, regexp:/etc/postfix/conf.d/virtual-regexp
