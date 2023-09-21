SimpleLogin
===========

This is a self-hosted docker-compose configuration for [SimpleLogin](https://simplelogin.io).

## Prerequisites

This procedure supports Ubuntu 20.04+ servers.

- Install [docker]()
- [Enable IPv6 for the default bridge network](https://docs.docker.com/config/daemon/ipv6/#use-ipv6-for-the-default-bridge-network)

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "experimental": true,
  "ip6tables": true
}
```

## Setup

This procedure currently supports:

- Running Postfix on the host Ubuntu server.
- Running everything else in Docker containers.

This includes:

- nginx
- [acme.sh](https://acme.sh) to request and issue SSL certs.

### Postfix

Install and setup postfix [using official instructions](https://github.com/simple-login/app).

### Nginx

1. Copy `.env.example` to `.env` and set appropriate values.

- set the `DOMAIN` variable to your domain.
- set the `POSTGRES_PASSWORD` to a unique password.
- set the `FLASK_SECRET` to an arbitrary secret key.

The SSL certs are issued by ZeroSSL using either:

- ACME challenge
- [Azure DNS challenge](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#37-use-azure-dns)

Please, uncomment the appropriate section from `./acme.sh/Dockerfiles/docker-entrypoint.sh`.

If you are using Azure DNS challenge, update the following values in `.env`:

- set `AZUREDNS_TENANTID` to the Azure tenant hosting the domain DNS zone.
- set `AZUREDNS_SUSCRIPTIONID` to the Azure subscription hosting the domain DNS zone.
- set `AZUREDNS_CLIENTID` to the client id of a service principal with permissions to update the DNS zone.
- set `AZUREDNS_CLIENTSECRET` to the client secret of a service principal with permissions to update the DNS zone.

2. Run the application:

```sh
./up.sh
```

## How-to Upgrade

- Change the image version in `.env`

```env
SL_VERSION=4.6.2-beta
```

- Check migration command
- Restart containers

```sh
./down.sh && ./up.sh
```
