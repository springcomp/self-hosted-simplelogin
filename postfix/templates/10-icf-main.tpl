# POSTFIX config file, adapted for SimpleLogin
# ============================================

biff = no
compatibility_level = 3.11
disable_vrfy_command = yes

# Increase max. mail size limit from default 10M to 25M
message_size_limit=26214400

myhostname = app.domain.tld
mydomain = domain.tld
myorigin = domain.tld
mail_name = MailVeil

mynetworks =
  10.0.0.0/24,
  127.0.0.0/8,
  [::1]/128,
  [::ffff:127.0.0.0]/104

relay_domains = pgsql:/etc/postfix/conf.d/pgsql-relay-domains.cf
transport_maps = pgsql:/etc/postfix/conf.d/pgsql-transport-maps.cf

#start postmarkapps settings
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = static:POST_USER:POST_PASS
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = may
smtp_tls_loglevel = 1
relayhost = [POST_URL]:POST_PORT
##end postmarkapp settings
