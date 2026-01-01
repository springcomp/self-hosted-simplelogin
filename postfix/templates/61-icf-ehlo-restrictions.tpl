
smtpd_helo_required = yes
smtpd_helo_restrictions =
  permit_mynetworks,
  reject_non_fqdn_helo_hostname,
  reject_invalid_helo_hostname,
  permit
