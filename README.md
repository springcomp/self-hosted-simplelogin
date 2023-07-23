SimpleLogin
===========

This is a self-hosted docker-compose configuration for [SimpleLogin](https://simplelogin.io).

## Prerequisites

TODO: get VPC !
TODO: install Docker + docker-compose-plugin + IPV6
[Use IPv6 for the default bridge network](https://docs.docker.com/config/daemon/ipv6/#use-ipv6-for-the-default-bridge-network)

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "experimental": true,
  "ip6tables": true
}
```
TODO: generate DKIM
TODO: DNS
TODO: clone update .env
TODO: docker compose up --detach
TODO: enjoy!

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
