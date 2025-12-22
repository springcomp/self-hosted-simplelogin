
# Recipient restrictions:
smtpd_recipient_restrictions =
  reject_unauth_pipelining,
  reject_non_fqdn_recipient,
  reject_unknown_recipient_domain,
  permit_mynetworks,
  reject_unauth_destination,
  reject_rbl_client zen.spamhaus.org,
  reject_rbl_client bl.spamcop.net,
  permit
