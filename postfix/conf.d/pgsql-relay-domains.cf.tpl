# postgres config
hosts = sl-db
user = myuser
password = mypassword
dbname = simplelogin

query = SELECT domain FROM custom_domain WHERE domain = '%s' AND verified=true
    UNION SELECT domain FROM public_domain WHERE domain = '%s'
    UNION SELECT '%s' WHERE '%s' = 'domain.tld'
    LIMIT 1;
