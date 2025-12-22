
# ---- Certificate configuration ----
smtpd_tls_cert_file = /certs/app.domain.tld.fullchain.pem
smtpd_tls_key_file  = /certs/app.domain.tld.key

# use secure ECDHE or RFC 7919 FFDHE groups
smtpd_tls_eecdh_grade = strong

# ---- Logging ----
# Log TLS negotiations;
# set to 2 for more detailed debugging if needed.
smtpd_tls_loglevel = 1

# Explicitly exclude known-weak ciphers (mostly redundant with modern OpenSSL).
smtp_tls_mandatory_exclude_ciphers  = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP
smtpd_tls_mandatory_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP

# ---- Allowed protocol versions ----
# Only allow TLSv1.2 and TLSv1.3 (older versions are insecure or deprecated).
smtp_tls_protocols  = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1

# Adds TLS information to Received: headers (optional but useful for diagnostics)
smtpd_tls_received_header = yes

smtpd_tls_security_level = may # "may" = Opportunistic TLS: offer TLS but do not require it.

# TLS session caching (LMDB is fast and modern)
smtp_tls_session_cache_database  = lmdb:${data_directory}/smtp_scache
smtpd_tls_session_cache_database = lmdb:${data_directory}/smtpd_scache

# ---- Additional TLS hardening ----
# Prefer server cipher order and disable TLS compression/renegotiation
# to prevent CRIME and renegotiation attacks.
tls_preempt_cipherlist = yes
tls_ssl_options = NO_COMPRESSION, NO_RENEGOTIATION
