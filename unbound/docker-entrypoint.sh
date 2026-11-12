#!/bin/sh -eu

# Renders the unbound/templates/*.tpl files into /config at container start,
# instead of relying on a host bind mount of ./unbound/conf.d/. This keeps
# the no-host-bind-mount deployment model used throughout this project.
#
# Rendered files are picked up via the base image's own
# `include: /config/*.conf`, additively alongside its default listener on
# 5053 - so the image's built-in healthcheck (which probes 5053) is
# unaffected.
# Recipe: https://github.com/springcomp/self-hosted-simplelogin/pull/46#issuecomment-3707216659
#
# module-config/identity/root-hints match what the previous
# bind-mounted unbound/conf.d/00-unbound.conf set, to not weaken
# anything the upstream maintainer deliberately configured:
# - module-config trims the cachedb module the image loads by default
#   (unused without a configured cache backend)
# - root-hints pins the image's own dns-root-hints package file, which
#   the image refreshes monthly via its own cron
#   (/etc/periodic/monthly/dns-root-hints) - the compiled-in fallback
#   Unbound would otherwise use only updates when the image itself does

TEMPLATE_DIR="/templates"
CONFIG_DIR="/config"

mkdir -p "$CONFIG_DIR"

for tpl in "$TEMPLATE_DIR"/*.tpl; do
  [ -e "$tpl" ] || continue
  name="$(basename "$tpl" .tpl)"
  cp "$tpl" "$CONFIG_DIR/$name"
done

unbound-anchor -a /var/run/unbound/root.key || true

# the base image's own entrypoint (unbound-checkconf + exec unbound) must run
# as the unprivileged "unbound" user; we only need root above to write into
# /config and the trust anchor file.
exec su -s /bin/sh unbound -c "sh /entrypoint.sh"
