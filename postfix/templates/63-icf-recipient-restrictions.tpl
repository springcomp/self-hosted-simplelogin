rbl_reply_maps = lmdb:/etc/postfix/conf.d/dnsbl-reply-map

smtpd_recipient_restrictions =
  reject_unauth_pipelining,
  reject_non_fqdn_recipient,
  reject_unknown_recipient_domain,
  permit_mynetworks,
  reject_unauth_destination,
  reject_rbl_client zen.spamhaus.org=127.0.0.[2..11],
  reject_rhsbl_sender dbl.spamhaus.org=127.0.1.[2..99],
  reject_rhsbl_helo dbl.spamhaus.org=127.0.1.[2..99],
  reject_rhsbl_reverse_client dbl.spamhaus.org=127.0.1.[2..99],
  warn_if_reject reject_rbl_client zen.spamhaus.org=127.255.255.[1..255],
  reject_rbl_client your_DQS_key.zen.dq.spamhaus.net=127.0.0.[2..11],
  reject_rhsbl_sender your_DQS_key.dbl.dq.spamhaus.net=127.0.1.[2..99],
  reject_rhsbl_helo your_DQS_key.dbl.dq.spamhaus.net=127.0.1.[2..99],
  reject_rhsbl_reverse_client your_DQS_key.dbl.dq.spamhaus.net=127.0.1.[2..99],
  reject_rhsbl_sender your_DQS_key.zrd.dq.spamhaus.net=127.0.2.[2..24],
  reject_rhsbl_helo your_DQS_key.zrd.dq.spamhaus.net=127.0.2.[2..24],
  reject_rhsbl_reverse_client your_DQS_key.zrd.dq.spamhaus.net=127.0.2.[2..24],
  reject_rbl_client bl.spamcop.net=127.0.0.2,
  permit
