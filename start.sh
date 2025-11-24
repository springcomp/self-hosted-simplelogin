#!/bin/env bash

## use `--remove-orphans` to remove nginx container from previous versions, to free up ports 80/443 for traefik
docker compose up --remove-orphans --detach $@
