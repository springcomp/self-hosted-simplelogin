SimpleLogin
===========

This is a self-hosted docker-compose configuration for [SimpleLogin](https://simplelogin.io).

## Prerequisites

TODO: install Docker + docker-compose-plugin

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
