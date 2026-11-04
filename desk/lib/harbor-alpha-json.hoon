/+  ac=harbor-alpha-core, ob=harbor-alpha-outbox, op=harbor-octra-public
|%
++  field
  |=  [j=json name=@t]
  ^-  (unit json)
  ?.  ?=(%o -.j)  ~
  (~(get by p.j) name)
++  string
  |=  [j=json name=@t]
  ^-  (unit @t)
  =/  f  (field j name)
  ?~  f  ~
  ?.  ?=(%s -.u.f)  ~
  `p.u.f
++  number
  |=  [j=json name=@t]
  ^-  (unit @ud)
  =/  f  (field j name)
  ?~  f  ~
  ?+  -.u.f  ~
    %s  (decimal p.u.f)
    %n  (decimal p.u.f)
  ==
++  decimal
  |=  text=@t
  ^-  (unit @ud)
  ?:  (gth (met 3 text) 16)  ~
  =/  n  (rush text dem)
  ?~  n  ~
  ?.  (lte u.n 1.000.000.000.000.000)  ~
  n
++  micros
  |=  n=@ud
  s+(digits:op n)
++  snapshot
  |=  [w=wallet:ac ship=@p network=@t]
  ^-  json
  =/  ch=json
    ?~  review.w  ~
    =/  d  u.review.w
    (pairs:enjs:format ~[['nonce' s+nonce.d] ['message' s+message.d] ['expires' (numb:enjs:format (seconds:ac expires.d))] ['requiresPin' b+&] ['to' s+to.tx.d] ['amount' (micros amount.tx.d)] ['fee' (micros ou.tx.d)] ['txNonce' (numb:enjs:format nonce.tx.d)]])
  =/  entries
    %+  turn  items.w
    |=  e=entry:ob
    (pairs:enjs:format ~[['id' s+id.e] ['hash' s+hash.packet.e] ['to' s+to.tx.e] ['amount' (micros amount.tx.e)] ['fee' (micros ou.tx.e)] ['nonce' (numb:enjs:format nonce.tx.e)] ['phase' s+phase.e] ['attempts' (numb:enjs:format attempts.e)]])
  %-  pairs:enjs:format
  :~  ['ship' s+(scot %p ship)]
      ['network' s+network]
      ['imported' b+?=(^ key.w)]
      ['address' s+?~(key.w '' address.u.key.w)]
      ['pinConfigured' b+?=(^ key.w)]
      ['salt' s+?~(key.w '' salt.u.key.w)]
      ['balance' ?~(funds.w ~ (micros balance.u.funds.w))]
      ['nonce' (numb:enjs:format ?~(funds.w 0 nonce.u.funds.w))]
      ['pendingNonce' (numb:enjs:format ?~(funds.w 0 pending.u.funds.w))]
      ['fee' ?~(funds.w ~ (micros fee.u.funds.w))]
      ['syncedAt' (numb:enjs:format ?~(funds.w 0 ?:(=(at.u.funds.w `@da`0) 0 (seconds:ac at.u.funds.w))))]
      ['busy' b+?=(^ flight.w)]
      ['blocking' b+(blocked:ob items.w)]
      ['failures' (numb:enjs:format failures.w)]
      ['lockedUntil' (numb:enjs:format ?:(=(locked.w `@da`0) 0 (seconds:ac locked.w)))]
      ['error' s+error.w]
      ['challenge' ch]
      ['outbox' a+entries]
  ==
++  balance
  |=  [j=json expected=@t]
  ^-  (unit [raw=@ud nonce=@ud pending=@ud])
  =/  addr  (string j 'address')
  =/  raw  (number j 'balance_raw')
  =/  nonce  (number j 'nonce')
  =/  pending  (number j 'pending_nonce')
  ?.  ?&(?=(^ addr) ?=(^ raw) ?=(^ nonce) ?=(^ pending))  ~
  ?.  ?&(=(u.addr expected) (lte u.nonce u.pending) (lte u.pending 2.147.483.647))  ~
  `[u.raw u.nonce u.pending]
++  receipt
  |=  [j=json e=entry:ob]
  ^-  (unit phase:ob)
  =/  hash  (string j 'tx_hash')
  =/  status  (string j 'status')
  ?.  ?&(?=(^ hash) ?=(^ status) =(u.hash hash.packet.e))  ~
  ?.  ?|(=(u.status 'pending') =(u.status 'confirmed') =(u.status 'rejected') =(u.status 'dropped'))  ~
  ?:  !=(u.status 'confirmed')  `;;(phase:ob u.status)
  =/  from  (string j 'from')
  =/  to  (string j 'to')
  =/  amount  (number j 'amount_raw')
  =/  nonce  (number j 'nonce')
  =/  ou  (number j 'ou')
  =/  epoch  (number j 'epoch')
  ?.  ?&(?=(^ from) ?=(^ to) ?=(^ amount) ?=(^ nonce) ?=(^ ou) ?=(^ epoch))  ~
  ?.  ?&(=(u.from from.tx.e) =(u.to to.tx.e) =(u.amount amount.tx.e) =(u.nonce nonce.tx.e) =(u.ou ou.tx.e) (gth u.epoch 0))  ~
  `%confirmed
--
