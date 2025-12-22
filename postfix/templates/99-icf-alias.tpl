
alias_maps = lmdb:/etc/postfix/conf.d/aliases

virtual_alias_maps =
  lmdb:/etc/postfix/conf.d/virtual,
  regexp:/etc/postfix/conf.d/virtual-regexp
