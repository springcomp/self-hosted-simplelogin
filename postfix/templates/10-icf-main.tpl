# POSTFIX config file, adapted for SimpleLogin
# ============================================

biff = no
compatibility_level = 3.11
disable_vrfy_command = yes

# queue_directory and data_directory share a single volume
# (see postfix-runtime volume in postfix-compose.yaml)
queue_directory = /postfix-runtime/queue
data_directory = /postfix-runtime/data

# Increase max. mail size limit from default 10M to 25M
message_size_limit=26214400

myhostname = app.domain.tld
mydomain = domain.tld
myorigin = domain.tld

mynetworks =
  10.0.0.0/24,
  127.0.0.0/8,
  [::1]/128,
  [::ffff:127.0.0.0]/104

relay_domains = pgsql:/etc/postfix/conf.d/pgsql-relay-domains.cf
transport_maps = pgsql:/etc/postfix/conf.d/pgsql-transport-maps.cf
