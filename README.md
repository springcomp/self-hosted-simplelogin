# SimpleLogin

This is a self-hosted docker-compose configuration for [SimpleLogin](https://simplelogin.io).

## Prerequisites

- a Linux server (either a VM or dedicated server). This doc shows the setup for Ubuntu 18.04 LTS but the steps could be adapted for other popular Linux distributions. As most of components run as Docker container and Docker can be a bit heavy, having at least 2 GB of RAM is recommended. The server needs to have the port 25 (email), 80, 443 (for the webapp), 22 (so you can ssh into it) open.

- a domain for which you can config the DNS. It could be a sub-domain. In the rest of the doc, let's say it's `mydomain.com` for the email and `app.mydomain.com` for SimpleLogin webapp. Please make sure to replace these values by your domain name and subdomain name whenever they appear in the doc. A trick we use is to download this README file on your computer and replace all `mydomain.com` and `app.mydomain.com` occurrences by your domain.

Except for the DNS setup that is usually done on your domain registrar interface, all the below steps are to be done on your server. The commands are to run with `bash` (or any bash-compatible shell like `zsh`) being the shell. If you use other shells like `fish`, please make sure to adapt the commands.

- Some utility packages used to verify the setup. Install them by:

```bash
sudo apt update \
  && sudo apt install -y net-tools dnsutils
```

## DNS Configuration

_Refer to the [reference documentation](https://github.com/springcomp/self-hosted-simplelogin/wiki/DNS-Configuration) for more details_

> **Please note** that DNS changes could take up to 24 hours to propagate. In practice, it's a lot faster though (~1 minute or so in our test). In DNS setup, we usually use domain with a trailing dot (`.`) at the end to to force using absolute domain.

You will need to setup the following DNS records:

- **A**: Maps your domain to your server's IPv4 address.
- **AAAA**: Maps your domain to your server's IPv6 address.
- **MX**: Directs incoming emails to your mail server (including `*` wildcards).
- **PTR**: Maps your server's IP address back to your domain name.

Set up mandatory security policies:

- **DKIM**: Digitally signs outgoing emails to verify authenticity.
- **DMARC**: Defines how email receivers should handle messages failing authentication.
- **SPF**: Authorizes specific mail servers to send emails from your domain.

Additional steps:

- **CAA**: Specifies which certificate authorities are allowed to issue SSL certificates for your domain.
- **MTA-STS**: Enforces secure, encrypted connections between mail servers.
- **TLS-RPT**: Reports TLS connection failures to improve email delivery security.

**Warning**: setting up a CAA record will restrict which certificate authority can successfully issue SSL certificates for your domain.
This will prevent certificate issuance from Let’s Encrypt staging servers. You may want to differ this DNS record until after SSL certificates are successfully issued for your domain.

## Docker

If you don't already have Docker installed on your server, please follow the steps on [Docker CE for Ubuntu](https://docs.docker.com/v17.12/install/linux/docker-ce/ubuntu/) to install Docker.

You can also install Docker using the [docker-install](https://github.com/docker/docker-install) script which is

```bash
curl -fsSL https://get.docker.com | sh
```

Enable IPv6 for [the default bridge network](https://docs.docker.com/config/daemon/ipv6/#use-ipv6-for-the-default-bridge-network)

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "experimental": true,
  "ip6tables": true
}
```

This procedure will guide you through running the entire stack using Docker containers.
This includes:

- traefik
- The [SimpleLogin app](https://github.com/simple-login/app) containers
- postfix

Run SimpleLogin from Docker containers:

1. Clone this repository in `/opt/simplelogin`
1. Copy `.env.example` to `.env` and set appropriate values.

    - set the `DOMAIN` variable to your domain.
    - set the `SUBDOMAIN` variable to your domain. The default value is `app`.
    - set the `POSTGRES_USER` variable to match the postgres credentials (when starting from scratch, use `simplelogin`).
    - set the `POSTGRES_PASSWORD` to match the postgres credentials (when starting from scratch, set to a random key).
    - set the `FLASK_SECRET` to an arbitrary secret key.

### Postgres SQL

This repository runs a postgres SQL in a Docker container.

**Warning**: previous versions of this repository ran version `12.1`.
Please, refer to the [reference documentation](https://github.com/springcomp/self-hosted-simplelogin/wiki/PostgreSQL) for more details and
upgrade instructions.

### Running the application

Run the application using the following commands:

```sh
docker compose up --detach --remove-orphans --build && docker compose logs -f
```

You may want to setup [Certificate Authority Authorization (CAA)](https://github.com/springcomp/self-hosted-simplelogin/wiki/dns-caa) at this point.

## Next steps

If all the above steps are successful, open <https://app.mydomain.com/> and create your first account!

By default, new accounts are not premium so don't have unlimited aliases. To make your account premium,
please go to the database, table "users" and set "lifetime" column to "1" or "TRUE":

```bash
docker compose exec -it postgres psql -U myuser simplelogin
> UPDATE users SET lifetime = TRUE;
> \q
```

Once you've created all your desired login accounts, add these lines to `.env` to disable further registrations:

```env
DISABLE_REGISTRATION=1
DISABLE_ONBOARDING=true
```

Then, to restart the web app, apply: `docker compose restart app`

## Miscellaneous

### Postfix configuration - Spamhaus

The Spamhaus Project maintains a reliable list of IP addresses known to be the source of SPAM.
You can check whether a given IP address is in that list by submitting queries to the DNS infrastructure.

Since Spamhaus blocks queries coming from public (open) DNS-Resolvers (see: <https://check.spamhaus.org/returnc/pub>) and your postfix container may use
a public resolver by default, it is recommended to sign up for the free
[Spamhaus Data Query Service](https://www.spamhaus.com/free-trial/sign-up-for-a-free-data-query-service-account/)
and obtain a Spamhaus DQS key.

Paste this key as `SPAMHAUS_DQS_KEY` in your `.env`

If no DQS-key is provided, your postfix container will check if the Spamhaus public mirrors are accepting its queries and use them instead.
If Spamhaus rejects queries from your postfix container to the public mirrors, it will be disabled entirely.

### Postfix configuration - Virtual aliases

The postfix configuration supports virtual aliases using the `postfix/conf.d/virtual` and `postfix/conf.d/virtual-regexp` files.
Those files are automatically created on startup based upon the corresponding [`postfix/templates/virtual.tpl`](./postfix/templates/virtual.tpl)
and [`postfix/templates/virtual-regexp.tpl`](./postfix/templates/virtual-regexp.tpl) template files.

The default configuration is as follows:

#### virtual.tpl

The `virtual` file supports postfix `virtual_alias_maps` settings.
It includes a rule that maps `unknown@mydomain.com` to `contact@mydomain.com` to demonstrate receiving
and email from a specific address that does not correspond to an existing alias, to another one that does.

```postfix-conf
unknown@mydomain.com  contact@mydomain.com
```

#### virtual-regexp.tpl

The `virtual-regexp` file supports postfix `virtual_alias_maps` settings.
It includes a rule that rewrite emails addressed to an arbitrary subdomain, which does not correspond
to an existing alias, to a new alias that belongs to a directory whose name is taken from the subdomain.
That alias may be created on the fly if it does not exist.

```postfix-conf
/^([^@]+)@([^.]+)\.mydomain.com/   $2/$1@mydomain.com
```

For instance, emails sent to `someone@directory.mydomain.com` will be routed to `directory/someone@mydomain.com` by postfix.

## How-to Upgrade from 3.4.0

- Change the image version in `.env`

```env
SL_VERSION=4.6.5-beta
```

- Check and apply [migration commands](https://github.com/simple-login/app/blob/master/docs/upgrade.md)

For instance, to upgrade from `3.4.0` to `4.6.x-beta`, the following change must be done in `simple-login-compose.yaml`:

```patch
  migration:
    image: simplelogin/app:$SL_VERSION
-   command: [ "flask", "db", "upgrade" ]
+   command: [ "alembic", "upgrade", "head" ]
    container_name: sl-migration
    env_file: .env
```

Finally, the following command must be run in the database:

```bash
docker compose exec -it postgres psql -U myuser simplelogin
> UPDATE email_log SET alias_id=(SELECT alias_id FROM contact WHERE contact.id = email_log.contact_id);
> \q
```

- Restart containers

```sh
docker compose stop && docker compose up --detach
```

After successfully upgrading to `v4.6.x-beta` you might want to upgrade
to the latest stable version. Change the `SL_IMAGE` and `SL_VERSION`
variables from the `.env` file:

```env
SL_VERSION=v4.70.0
SL_IMAGE=app-ci
```

**Caution**: some [underpowered VPS](https://github.com/springcomp/self-hosted-simplelogin/issues/12#issuecomment-3160394621) might exhibit some WORKER_TIMEOUT errors
when running the `sl-app` image. To mitigate this issue, you may want to
increase the starting timeout value in [`simple-login-compose.yaml`](https://github.com/springcomp/self-hosted-simplelogin/blob/main/simple-login-compose.yaml#L49):

```patch
  app:
    image: simplelogin/$SL_IMAGE:$SL_VERSION
    container_name: sl-app
    env_file: .env
    volumes:
      - ./pgp:/sl/pgp
      - ./upload:/code/static/upload
      - ./dkim.key:/dkim.key
      - ./dkim.pub.key:/dkim.pub.key
+   command: ["gunicorn","wsgi:app","-b","0.0.0.0:7777","-w","2","--timeout","30"]
    restart: unless-stopped
```

And restart the containers.

This will pull up the latest versions of the docker images,
potentially running the updated `sl-migration` steps, and
startup the application.

## How-to Upgrade from previous NGinx-based setup

This section outlines the migration steps from a previous installation of `self-hosted-simplelogin` using the NGinx-based setup, to the current Traefik-based setup.

### Backup your server

1. Backup the database using the following command:

```powershell
mkdir /tmp/sl-backup/

docker compose \
  -f /opt/simplelogin/docker-compose.yaml exec postgres \
  pg_dump -U <postgres-user-name> simplelogin -F c -b >/tmp/sl-backup/simplelogin.sql
```

1. Backup your DKIM public and private keys.

1. Backup your PGP keys, avatar picture and undelivered emails from the `upload/` and `pgp/` folders.

1. Backup your existing `.env` file.

### Postfix

The `postfix` container is running a private image that has changed from the previous NGinx-based setup to the current Traefik-based setup.

That image needs to be regenerated. You can remove the previous version using the command:

```sh
docker rmi private/postfix:latest
```

### In-place upgrade

In-place upgrade refers to the fact that you will upgrade the stack from the previous setup to the current setup in the same directoy.

This is the easiest upgrade path as you only need to change the docker-compose and setup files. If you cloned this repository, you most likely need to use `git pull` to upgrade to the latest version.

**Prerequisites**: make sure you are running a recent version of SimpleLogin. This section assumes you are running `app-ci:v4.70.0`.

1. Stop the stack using `. ./down.sh`.
1. Upgrade to the latest version of the files.
1. Create and update the `.env` file from `.env.example`.

The new `.env` file supports specifying parameters for certificate renewal using either the `DNS-01` or `TLS–ALPN-01` ACME challenge from Let’sEncrypt using [LEGO](https://go-acme.github.io/lego/dns/) , a Let’sEncrypt client library written in Go. Please, review the LEGO documentation for supported providers and their parameters.

1. Start the stack using `. ./up.sh`.

You can now cleanup the folders that are no longer useful:

```sh
rm -rf acme.sh/
rm -rf nginx/
```

### Backup / restore upgrade

If you want to keep the existing setup in a known working directory, you can use the backup - restore path to test the new setup from a separate folder.

1. Clone this repository to get the latest version of the files.
1. Create and update the `.env` file from `.env.example`.

The new `.env` file supports specifying parameters for certificate renewal using either the `DNS-01` or `TLS–ALPN-01` ACME challenge from Let’sEncrypt using [LEGO](https://go-acme.github.io/lego/dns/) , a Let’sEncrypt client library written in Go. Please, review the LEGO documentation for supported providers and their parameters.

1. Restore the `pgp/` and `upload/` folders.
2. Restore the `dkim.pub.key` and `dkim.key` files.
3. Restore the postfix `virtual` and `virtual-regexp` files.
4. Start the stack using `. ./up.sh`.

This will create the `private/postfix:latest` image and request new certificates from Let’s Encrypt.

Once the application is running successfully, you need to restore the database. The easiest way it to copy the backup file in the `db/` folder:

```sh
sudo cp /tmp/sl-backup/simplelogin.sql db/
docker compose exec -it pg_restore -U <postgres-user-name> \
  --dbname=simplelogin \
  --clean \
  --verbose \
  /var/lib/postgresql/data/simplelogin.sql
```
