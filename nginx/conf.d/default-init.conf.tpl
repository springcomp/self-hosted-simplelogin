server {
    server_name domain.tld;
    listen 80;
    listen [::]:80;

    location /.well-known/acme-challenge/ {
      alias /var/www/.well-known/acme-challenge/;
    }
}
server {
    server_name mta-sts.domain.tld;
    listen 80;
    listen [::]:80;

    location /.well-known/ {
      alias /var/www/.well-known/;
    }
}
