
# postscreen_bare_newline_enable, postscreen_non_smtp_command_enable and
# postscreen_pipelining_enable are deliberately disabled below: merely
# enabling any one of them forces postscreen's PASS_NEW temp-reject/retry
# cycle on every first-time client, regardless of whether that client
# actually violates the test. Since the retry timing is entirely up to the
# sending MTA's own backoff schedule, this caused real deliveries to be
# held up by hours (observed: up to ~20h) - recurring, not a one-off, for
# any correspondent postscreen hasn't already cached as trusted. Verified
# locally that dropping these three, while keeping greet_action below,
# still passes clean clients straight through with no forced reconnect.

#postscreen_bare_newline_enable = yes
#postscreen_bare_newline_action = enforce

#postscreen_non_smtp_command_enable = yes
#postscreen_non_smtp_command_action = enforce

#postscreen_pipelining_enable = yes
#postscreen_pipelining_action = enforce

postscreen_greet_action = enforce

# Reputable senders (list.dnswl.org) get a negative score and skip the
# before-greeting tests + the mandatory first-contact retry entirely,
# instead of waiting out postscreen_greet_wait on every new source IP —
# this matters most for big providers (M365, Google, ...) that spread
# retries across a large, frequently-rotating outbound IP pool, since
# each such IP otherwise looks "new" to postscreen's own cache.
postscreen_dnsbl_sites =
  list.dnswl.org=127.0.[0..255].0*-2,
  list.dnswl.org=127.0.[0..255].1*-3,
  list.dnswl.org=127.0.[0..255].2*-4,
  list.dnswl.org=127.0.[0..255].3*-5
postscreen_dnsbl_threshold = 1
postscreen_dnsbl_action = enforce
# A negative combined score by itself does not let a client skip anything
# (with only negative weights above, postscreen_dnsbl_threshold never blocks
# either): the allowlist threshold is what turns the DNSWL score into a
# pass. Any list.dnswl.org listing scores <= -2, so -1 lets every listed
# client skip the before- and after-220-greeting tests and go straight to
# smtpd; unlisted clients (score 0) are unaffected.
postscreen_dnsbl_allowlist_threshold = -1
