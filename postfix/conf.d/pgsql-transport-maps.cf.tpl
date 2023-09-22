# postgres config
hosts = sl-db
user = myuser
password = mypassword
dbname = simplelogin

# forward to smtp:sl-email:20381 for custom domain AND email domain
query = SELECT 'smtp:sl-email:20381' FROM custom_domain WHERE domain = '%s' AND verified=true
    UNION SELECT 'smtp:sl-email:20381' FROM public_domain WHERE domain = '%s'
    UNION SELECT 'smtp:sl-email:20381' WHERE '%s' = 'domain.tld'
    LIMIT 1;
