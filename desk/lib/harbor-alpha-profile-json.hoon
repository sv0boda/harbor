::  Public snapshots only; inactive seeds, verifiers and packets stay private.
/+  an=harbor-alpha-network, ac=harbor-alpha-core, aj=harbor-alpha-json, ob=harbor-alpha-outbox
|%
++  summary
  |=  [w=wallet:ac network=@t available=?]
  ^-  json
  (pairs:enjs:format ~[['network' s+network] ['available' b+available] ['imported' b+?=(^ key.w)] ['address' s+?~(key.w '' address.u.key.w)] ['pendingCount' (numb:enjs:format (lent (skim items.w |=(e=entry:ob !=(phase.e %confirmed)))))]])
++  snapshot
  |=  [p=profile:an ship=@p devnet-enabled=?]
  ^-  json
  =/  n  (wire-network:an selected.p)
  =/  other=@t  ?:(=(%mainnet selected.p) 'devnet' 'mainnet-alpha')
  =/  base  (snapshot:aj active.p ship n)
  ?>  ?=(%o -.base)
  [%o (~(put by p.base) 'networks' a+~[(summary active.p n ?|(=(%mainnet selected.p) devnet-enabled)) (summary inactive.p other ?|(=(%devnet selected.p) devnet-enabled))])]
--
