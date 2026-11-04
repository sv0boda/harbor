::  Pure network-profile library. No agent, no services, no mutable globals.
/+  ac=harbor-alpha-core, ob=harbor-alpha-outbox
|%
+$  network  ?(%mainnet %devnet)
+$  profile  [version=%2 selected=network active=wallet:ac inactive=wallet:ac]
++  initial
  ^-  profile
  [%2 %mainnet initial:ac initial:ac]
++  migrate
  |=  old=wallet:ac
  ^-  profile
  [%2 %mainnet (recover:ac old) initial:ac]
++  recover
  |=  p=profile
  ^-  profile
  p(active (recover:ac active.p), inactive (recover:ac inactive.p))
++  wire-network
  |=  n=network
  ^-  @t
  ?:  =(%mainnet n)  'mainnet-alpha'
  'devnet'
++  switch
  |=  [p=profile target=network]
  ^-  [error=@t next=profile]
  ?:  =(target selected.p)  ['' p]
  ?^  flight.active.p  ['A network request is in progress' p]
  ?^  flight.inactive.p  ['A network request is in progress' p]
  ?:  (lien items.active.p |=(e=entry:ob ?|(=(phase.e %ready) =(phase.e %sending))))
    ['A payment is in progress' p]
  ?:  (lien items.inactive.p |=(e=entry:ob ?|(=(phase.e %ready) =(phase.e %sending))))
    ['A payment is in progress' p]
  =/  a  (recover:ac active.p)
  =.  a  a(error '')
  =/  b  (recover:ac inactive.p)
  =.  b  b(error '')
  ['' [%2 target b a]]
--
