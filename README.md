SimpleLogin
===========

This is a self-hosted docker-compose configuration for [SimpleLogin](https://simplelogin.io).

## Prerequisites

- a Linux server (either a VM or dedicated server). This doc shows the setup for Ubuntu 18.04 LTS but the steps could be adapted for other popular Linux distributions. As most of components run as Docker container and Docker can be a bit heavy, having at least 2 GB of RAM is recommended. The server needs to have the port 25 (email), 80, 443 (for the webapp), 22 (so you can ssh into it) open.

- a domain for which you can config the DNS. It could be a sub-domain. In the rest of the doc, let's say it's `mydomain.com` for the email and `app.mydomain.com` for SimpleLogin webapp. Please make sure to replace these values by your domain name and subdomain name whenever they appear in the doc. A trick we use is to download this README file on your computer and replace all `mydomain.com` and `app.mydomain.com` occurrences by your domain.

Except for the DNS setup that is usually done on your domain registrar interface, all the below steps are to be done on your server. The commands are to run with `bash` (or any bash-compatible shell like `zsh`) being the shell. If you use other shells like `fish`, please make sure to adapt the commands.

### Some utility packages

These packages are used to verify the setup. Install them by:

```bash
sudo apt update \
  && sudo apt install -y net-tools dnsutils
```

## DNS Configuration

### MX record

Create a **MX record** that points `mydomain.com.` to `app.mydomain.com.` with priority 10.

To verify if the DNS works, the following command:

```bash
dig @1.1.1.1 mydomain.com mx
```

should return:

```
mydomain.com.	3600	IN	MX	10 app.mydomain.com.
```

### A record

Create an **A record** that points `app.mydomain.com.` to your server IP.
To verify, the following command:

```bash
dig @1.1.1.1 app.mydomain.com a
```

should return your server IP.

> **Please note** that DNS changes could take up to 24 hours to propagate. In practice, it's a lot faster though (~1 minute or so in our test). In DNS setup, we usually use domain with a trailing dot (`.`) at the end to to force using absolute domain.

### PTR record

From Wikipedia https://en.wikipedia.org/wiki/Reverse_DNS_lookup

> A reverse DNS lookup or reverse DNS resolution (rDNS) is the querying technique of the Domain Name System (DNS) to determine the domain name associated with an IP address – the reverse of the usual "forward" DNS lookup of an IP address from a domain name.

Create a **PTR record** that point your IP address to your domain name.
**Important** Some providers require PTR configuration to be done from their dashboard and ignore DNS records. Please, make sure to properly configure reverse DNS lookup for your domain.

To verify, the following command:

```bash
dig @1.1.1.1 -x $( ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
```

should return your domain name.

### DKIM

From Wikipedia https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail

> DomainKeys Identified Mail (DKIM) is an email authentication method designed to detect forged sender addresses in emails (email spoofing), a technique often used in phishing and email spam.

Setting up DKIM is highly recommended to reduce the chance for your emails ending up in the recipient's Spam folder.

First you need to generate a private and public key for DKIM:

```bash
openssl genrsa -traditional -out dkim.key 1024
openssl rsa -in dkim.key -pubout -out dkim.pub.key
```

You will need the files `dkim.key` and `dkim.pub.key` for the next steps.

For email gurus, we have chosen 1024 key length instead of 2048 for DNS simplicity as some registrars don't play well with long TXT record.

Set up DKIM by adding a **TXT record** for `dkim._domainkey.mydomain.com.` with the following value:

```
v=DKIM1; k=rsa; p=PUBLIC_KEY
```

with `PUBLIC_KEY` being your `dkim.pub.key` but
- remove the `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----`
- join all the lines on a single line.

For example, if your `dkim.pub.key` is

```
-----BEGIN PUBLIC KEY-----
ab
cd
ef
gh
-----END PUBLIC KEY-----
```

then the `PUBLIC_KEY` would be `abcdefgh`.

You can get the `PUBLIC_KEY` by running this command:

```bash
sed "s/-----BEGIN PUBLIC KEY-----/v=DKIM1; k=rsa; p=/g" $(pwd)/dkim.pub.key | \
  sed 's/-----END PUBLIC KEY-----//g' | \
  tr -d '\n' | awk 1
```

To verify, the following command:

```bash
dig @1.1.1.1 dkim._domainkey.mydomain.com txt
```

should return the above value.

### SPF

From Wikipedia https://en.wikipedia.org/wiki/Sender_Policy_Framework

> Sender Policy Framework (SPF) is an email authentication method designed to detect forging sender addresses during the delivery of the email

Similar to DKIM, setting up SPF is highly recommended.

Create a **TXT record** for `mydomain.com.` with the value:

```
v=spf1 mx -all
```

What it means is only your server can send email with `@mydomain.com` domain.
To verify, the following command

```bash
dig @1.1.1.1 mydomain.com txt
```

should return the above value.

### DMARC

From Wikipedia https://en.wikipedia.org/wiki/DMARC

> It (DMARC) is designed to give email domain owners the ability to protect their domain from unauthorized use, commonly known as email spoofing

Setting up DMARC is also recommended.

Create a **TXT record** for `_dmarc.mydomain.com.` with the following value

```
v=DMARC1; p=quarantine; adkim=r; aspf=r
```

This is a `relaxed` DMARC policy. You can also use a more strict policy with `v=DMARC1; p=reject; adkim=s; aspf=s` value.

To verify, the following command

```bash
dig @1.1.1.1 _dmarc.mydomain.com txt
```

should return the set value.

For more information on DMARC, please consult https://tools.ietf.org/html/rfc7489

### HSTS

From Wikipedia https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security

> HTTP Strict Transport Security (HSTS) is a policy mechanism that helps to protect websites against man-in-the-middle attacks such as protocol downgrade attacks and cookie hijacking.

HTTP Strict Transport Security is an extra step you can take to protect your web app from certain man-in-the-middle attacks. It does this by specifying an amount of time (usually a really long one) for which you should only accept HTTPS connections, not HTTP ones.

This repository already enables HSTS, thanks to the following line to the `server` block of the Nginx configuration file:

```
add_header Strict-Transport-Security "max-age: 31536000; includeSubDomains" always;
```

(The `max-age` is the time in seconds to not permit a HTTP connection, in this case it's one year.)

### CAA

From Wikipedia https://en.wikipedia.org/wiki/DNS_Certification_Authority_Authorization

> DNS Certification Authority Authorization (CAA) is an Internet security policy mechanism that allows domain name holders to indicate to certificate authorities whether they are authorized to issue digital certificates for a particular domain name.

[Certificate Authority Authorization](https://letsencrypt.org/docs/caa/) is a step you can take to restrict the list of certificate authorities that are allowed to issue certificates for your domains.

Use [SSLMate’s CAA Record Generator](https://sslmate.com/caa/) to create a **CAA record** with the following configuration:

- `flags`: `0`
- `tag`: `issue`
- `value`: `"sectigo.com"`

To verify if the DNS works, the following command:

```bash
dig @1.1.1.1 mydomain.com caa
```

should return:

```
mydomain.com.	3600	IN	CAA	0 issue "sectigo.com"
```

**Warning**: setting up a CAA record will restrict which certificate authority can successfully issue SSL certificates for your domain.
This will prevent certificate issuance from Let’s Encrypt staging servers. You may want to differ this DNS record until after SSL certificates are successfully issued for your domain.


### MTA-STS

From Wikipedia https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol#SMTP_MTA_Strict_Transport_Security

> SMTP MTA Strict Transport Security defines a protocol for mail servers to declare their ability to use secure channels in specific files on the server and specific DNS TXT records.

[SMTP MTA Strict Transport Security](https://datatracker.ietf.org/doc/html/rfc8461) is an extra step you can take to broadcast the ability of your instance to receive and, optionally enforce, TSL-secure SMTP connections to protect email traffic.

**Note**: a file `/var/www/.well-known/mta-sts.txt.tpl` is included in this repository with a content
similar to the text shown hereafter.

```txt
version: STSv1
mode: testing
mx: app.mydomain.com
max_age: 86400
```

It is recommended to start with `mode: testing` for starters to get time to review failure reports.

You **do not need to edit this file** as it will be used to derive an appropriate file upon startup.
However, you _do need_ to create an **A record** that points `mta-sts.mydomain.com.` to your server IP.

To verify, the following command:

```bash
dig @1.1.1.1 mta-sts.mydomain.com a
```

should return your server IP.


Create a **TXT record** for `_mta-sts.mydomain.com.` with the following value:

```txt
v=STSv1; id=UNIX_TIMESTAMP
```

With `UNIX_TIMESTAMP` being the current date/time.

Use the following command to generate the record:

```bash
echo "v=STSv1; id=$(date +%s)"
```

To verify if the DNS works, the following command:

```bash
dig @1.1.1.1 _mta-sts.mydomain.com txt
```

should return a result similar to this one:

```
_mta-sts.mydomain.com.	3600	IN	TXT	"v=STSv1; id=1689416399"
```

### TLSRPT

[SMTP TLS Reporting](https://datatracker.ietf.org/doc/html/rfc8460) is used by SMTP systems to report failures in establishing TLS-secure sessions as broadcast by the MTA-STS configuration.

Configuring MTA-STS in `mode: testing` as shown in the previous section gives you time to review failures from some SMTP senders.

Create a **TXT record** for `_smtp._tls.mydomain.com.` with the following value:

```txt
v=TSLRPTv1; rua=mailto:YOUR_EMAIL
```

The TLSRPT configuration at the DNS level allows SMTP senders that fail to initiate TLS-secure sessions to send reports to a particular email address.  We suggest creating a `tls-reports` alias in SimpleLogin for this purpose.

To verify if the DNS works, the following command

```bash
dig @1.1.1.1 _smtp._tls.mydomain.com txt
```

should return a result similar to this one:

```
_smtp._tls.mydomain.com.	3600	IN	TXT	"v=TSLRPTv1; rua=mailto:tls-reports@mydomain.com"
```

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

## Setup

This procedure will guide you through running the entire stack using Docker containers.
This includes:

- nginx
- [acme.sh](https://acme.sh) to request and issue SSL certs.
- The [SimpleLogin app](https://github.com/simple-login/app) containers
- postfix

### Run SimpleLogin Docker containers

1. Clone this repository in `/opt/simplelogin`
1. Copy `.env.example` to `.env` and set appropriate values.

- set the `DOMAIN` variable to your domain.
- set the `SUBDOMAIN` variable to your domain. The default value is `app`.
- set the `POSTGRES_USER` variable to match the postgres credentials.
- set the `POSTGRES_PASSWORD` to match the postgres credentials.
- set the `FLASK_SECRET` to an arbitrary secret key.

The SSL certs are issued by the ACME server using either:

- HTTP-01 ACME challenge
- DNS-01 ACME challenge using acme.sh DNS integration

Set the following variables in `.env` to appropriate values:

- set the `LE_STAGING` to `true` or `false`.
- set the `ACME_CHALLENGE` variable to either `DNS-01` (default) or `HTTP-01`.
- set the `ACME_SERVER` variable to any of the [supported servers by acme.sh](https://github.com/acmesh-official/acme.sh/wiki/Server). Default value is `zerossl`.

**DNS-01 ACME challenge**

If you are using DNS-01 ACME challenge, set `ACME_SH_DNS_API` to one of the
[supported acme.sh DNS API](https://github.com/acmesh-official/acme.sh#8-automatic-dns-api-integration) plugins.

This repository currently supports
[Microsoft Azure](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#37-use-azure-dns
) and
[Cloudflare](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#a-using-a-restrictive-api-token) DNS integrations.


<details><summary>Microsoft Azure DNS configuration</summary>
If using Microsoft Azure, update the following values in `.env`:

- set `AZUREDNS_TENANTID` to the Azure tenant hosting the domain DNS zone.
- set `AZUREDNS_SUSCRIPTIONID` to the Azure subscription hosting the domain DNS zone.
- set `AZUREDNS_CLIENTID` to the client id of a service principal with permissions to update the DNS zone.
- set `AZUREDNS_CLIENTSECRET` to the client secret of a service principal with permissions to update the DNS zone.
</details>

<details><summary>Cloudflare DNS configuration</summary>
If using Cloudflare, update the following values in `.env`:

- set `CF_Token` to the Cloudflare API token.
- set `CF_Zone_ID` to the Cloudflare DNS Zone identifier.
- set `CF_Account_ID` to your Cloudflare account identifier.
</details>

The SSL certificates will be available at the following locations:

- `/etc/acme.sh/*.mydomain.com_ecc/fullchain.cer`
- `/etc/acme.sh/*.mydomain.com_ecc/*.domain.tld.key`

**HTTP-01 ACME challenge**

If you are using HTTP-01 challenge, update the SSL certificate and key locations in following files:

- `nginx/conf.d/default.conf.tpl`
- `postfix/conf.d/main.cf.tpl`

Specifically, using HTTP-01, the SSL certificates are available at the following locations:

- `/etc/acme.sh/mydomain.com_ecc/fullchain.cer`
- `/etc/acme.sh/mydomain.com_ecc/domain.tld.key`

3. Run the application:

The `up.sh` shell script updates important configuration files from templates provided in this repository,
so that it uses the correct domain and postgresql credentials. Here are the template files:

- `acme.sh/www/.well-known/mta-sts.txt.tpl`
- `nginx/conf.d/default.conf.tpl`
- `postfix/conf.d/aliases`
- `postfix/conf.d/main.cf.tpl`
- `postfix/conf.dl/pgsql-relay-domains.cf.tpl`
- `postfix/conf.dl/pgsql-transport-maps.cf.tpl`
- `postfix/conf.d/virtual.tpl`
- `postfix/conf.d/virtual-regexp.tpl`

Run the application using the following commands:

```sh
./up.sh --build && docker logs -f acme.sh
```

If you used the staging server to issue certificates, please review and troubleshoot.
Once you are happy, set the `LE_STAGING` variable in `.env` to `false` and re-issue the certificates:

```sh
rm -rf acme.sh/conf.d/
./down.sh && ./up.sh && docker logs -f acme.sh
```

You may also want to setup [Certificate Authority Authorization (CAA)](#caa) at this point.

## Wildcard subdomains

**Note** the following section documents wildcard certificates and subdomains. You may want to use builtin facility within SimpleLogin to achieve the same results.

This repository suppports issuing wildcard certificates for any number of subdomains using Letsencrypt DNS-01 challenge using acme.sh DNS integration.
It also suppports issuing certificates for the following subdomains `app.mydomain.com` and `mta-sts.mydomain.com` using Letsencrypt HTTP-01 challenge.

If your DNS supports it, you can add a **MX record** to point `*.mydomain.com` to `app.mydomain.com` so that you can receive mails from any number of subdomains.
To verify, the following command:

```sh
dig @1.1.1.1 *.mydomain.com mx
```

Should return:

```
*.mydomain.com. 3600  IN  MX    10 app.mydomain.com
```

Alternatively, you can update the `acme.sh/Dockerfiles/docker-entrypoint.sh` script and update the list of subdomains you want to issue SSL certificates for.

The postfix configuration supports virtual aliases using the `postfix/conf.d/virtual` and `postfix/conf.d/virtual-regexp` files.
Those files are automatically created on startup based upon the corresponding [`postfix/conf.d/virtual.tpl`](./postfix/conf.d/virtual.tpl)
and [`postfix/conf.d/virtual-regexp.tpl`](./postfix/conf.d/virtual-regexp.tpl) template files.

The default configuration is as follows:

### virtual.tpl

The `virtual` file supports postfix `virtual_alias_maps` settings.
It includes a rule that maps `unknown@mydomain.com` to `contact@mydomain.com` to demonstrate receiving
and email from a specific address that does not correspond to an existing alias, to another one that does.

```
unknown@mydomain.com  contact@mydomain.com
```

### virtual-regexp.tpl

The `virtual-regexp` file supports postfix `virtual_alias_maps` settings.
It includes a rule that rewrite emails addressed to an arbitrary subdomain, which does not correspond
to an existing alias, to a new alias that belongs to a directory whose name is taken from the subdomain.
That alias may be created on the fly if it does not exist.

```
/^([^@]+)@([^.]+)\.mydomain.com/   $2/$1@mydomain.com
```

For instance, emails sent to `someone@directory.mydomain.com` will be routed to `directory/someone@mydomain.com` by postfix.

## Enjoy!

If all the above steps are successful, open http://app.mydomain.com/ and create your first account!

By default, new accounts are not premium so don't have unlimited aliases. To make your account premium,
please go to the database, table "users" and set "lifetime" column to "1" or "TRUE":

```
docker compose exec -it postgres psql -U myuser simplelogin
> UPDATE users SET lifetime = TRUE;
> \q
```

Once you've created all your desired login accounts, add these lines to `.env` to disable further registrations:

```
DISABLE_REGISTRATION=1
DISABLE_ONBOARDING=true
```

Then restart the web app to apply: `docker compose restart app`

## How-to Upgrade from 3.4.0

- Change the image version in `.env`

```env
SL_VERSION=4.6.5-beta
```

- Check and apply [migration commands](https://github.com/simple-login/app/blob/master/docs/upgrade.md)

For instance, to upgrade from `3.4.0` to `4.6.x-beta`, the following change must be done in `simplelogin-compose.yaml`:

```patch
    volumes:
      - ./db:/var/lib/postgresql/data
    restart: unless-stopped

  migration:
    image: simplelogin/app:$SL_VERSION
-   command: [ "flask", "db", "upgrade" ]
+   command: [ "alembic", "upgrade", "head" ]
    container_name: sl-migration
    env_file: .env
```

The following changes must be done in `pgsql-transport-maps.cf`:

```patch
  dbname = simplelogin
  
  query = SELECT 'smtp:127.0.0.1:20381' FROM custom_domain WHERE domain = '%s' AND verified=true
+     UNION SELECT 'smtp:127.0.0.1:20381' FROM public_domain WHERE domain = '%s'
      UNION SELECT 'smtp:127.0.0.1:20381' WHERE '%s' = 'mydomain.com' LIMIT 1;
```

The following changes must be done in `pgsql-relay-maps.cf`:

```patch
  dbname = simplelogin
  
  query = SELECT domain FROM custom_domain WHERE domain = '%s' AND verified=true
+     UNION SELECT domain FROM public_domain WHERE domain = '%s'
      UNION SELECT '%s' WHERE '%s' = 'mydomain.com' LIMIT 1;
```

Finally, the following command must be run in the database:

```
docker exec -it sl-db psql -U myuser simplelogin
> UPDATE email_log SET alias_id=(SELECT alias_id FROM contact WHERE contact.id = email_log.contact_id);
> \q
```


- Restart containers

```sh
./down.sh && ./up.sh
```


After successfully upgrading to `v4.6.x-beta` you might want to upgrade
to the latest stable version. Change the `SL_IMAGE` and `SL_VERSION`
variables from the `.env` file:

```
SL_VERSION=v4.36.6
SL_IMAGE=app-ci
```

And restart the containers.

