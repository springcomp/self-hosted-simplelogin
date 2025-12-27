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

mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 10.0.0.0/24

relay_domains = pgsql:/etc/postfix/conf.d/pgsql-relay-domains.cf
transport_maps = pgsql:/etc/postfix/conf.d/pgsql-transport-maps.cf
