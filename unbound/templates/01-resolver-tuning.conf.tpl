# `infra-cache-max-rtt` caps Unbound **calculated timeout for an upstream DNS request**,
# in milliseconds. Unbound tracks that timeout per nameserver IP in its infrastructure
# cache and normally increases it after a timeout.
# The [Ubuntu manpage](https://manpages.ubuntu.com/manpages/noble/man5/unbound.conf.5.html)
# gives a default cap of **2 minutes**.

# Lowering cap to **1 second**, so Unbound will not keep extending an individual upstream
# wait beyond 1 second; it may retry or select another server sooner.
# This is **not** a 1-second limit on the entire client DNS lookup, nor a cache TTL.
# The [Unbound timeout guide](https://unbound.docs.nlnetlabs.nl/en/latest/reference/history/info-timeout-server-selection.html)
# explains the per-IP estimates, backoff, and server selection.

# Trade-off: quicker response to an unresponsive server,
# but more premature retries when a server is merely slow.

  infra-cache-max-rtt: 1000

# `discard-timeout` controls **how long Unbound keeps a client’s reply waiting while
# recursive DNS resolution runs**.
# At the [manpage’s default of 1900 ms](https://manpages.ubuntu.com/manpages/noble/man5/unbound.conf.5.html#discard),
# Unbound drops a still-waiting reply after 1.9 seconds **without answering that client**;
# the recursion work item continues.

# Set at `0` **disables that discard rule**. It does *not* disable the upstream request
# timeouts, retries, or server selection described in
# [NLnet Labs’ timeout guide](https://www.nlnetlabs.nl/documentation/unbound/info-timeout/).
# It also cannot prevent a client from timing out on its own.

# Trade-off: slow resolutions get more time to produce a client reply.
# More waiting replies can accumulate.
# The `1900ms` default may also cut off replies while `serve-expired` is waiting
# for a slow fresh answer; manpage recommends setting `discard-timeout` above
# `serve-expired-client-timeout` when that feature is enabled. 

  discard-timeout: 0
  serve-expired: no
