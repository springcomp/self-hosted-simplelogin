server {
    server_name domain.tld;

    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;

    ssl_certificate /etc/acme.sh/*.domain.tld_ecc/fullchain.cer; # issued by acme.sh
    ssl_certificate_key /etc/acme.sh/*.domain.tld_ecc/*.domain.tld.key; # issued by acme.sh

    include /etc/nginx/ssl/options-ssl-nginx.conf;
    ssl_dhparam /etc/nginx/ssl/ssl-dhparams.pem;

    return 301 $scheme://app.domain.tld;
}

server {
    server_name  app.domain.tld;

    add_header Strict-Transport-Security "max-age: 31536000; includeSubDomains" always;

    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;

    ssl_certificate /etc/acme.sh/*.domain.tld_ecc/fullchain.cer; # issued by acme.sh
    ssl_certificate_key /etc/acme.sh/*.domain.tld_ecc/*.domain.tld.key; # issued by acme.sh

    include /etc/nginx/ssl/options-ssl-nginx.conf;
    ssl_dhparam /etc/nginx/ssl/ssl-dhparams.pem;

    location / {
        proxy_pass http://sl-app:7777;
    }
}
server {
    if ($host = domain.tld) {
        return 301 https://$host$request_uri;
    }

    server_name domain.tld;
    listen 80;
    listen [::]:80;
    return 404;
}

server {
    if ($host = app.domain.tld) {
        return 301 https://$host$request_uri;
    }

    server_name app.domain.tld;
    listen 80;
    listen [::]:80;
    return 404;
}
server {
    server_name mta-sts.domain.tld;
    root /var/www;

    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;

    ssl_certificate /etc/acme.sh/*.domain.tld_ecc/fullchain.cer; # issued by acme.sh
    ssl_certificate_key /etc/acme.sh/*.domain.tld_ecc/*.domain.tld.key; # issued by acme.sh

    include /etc/nginx/ssl/options-ssl-nginx.conf;
    ssl_dhparam /etc/nginx/ssl/ssl-dhparams.pem;

    location ^~ /.well-known {
    }
}
server {
    if ($host = mta-sts.domain.tld) {
        return 301 https://$host$request_uri;
    }


    server_name mta-sts.domain.tld;
    listen 80;
    listen [::]:80;
    return 404; 
}
