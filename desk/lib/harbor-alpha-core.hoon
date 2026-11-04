::  Import-only public-payment state. Keys never leave the ship via snapshots.
/+  op=harbor-octra-public, pk=harbor-octra-packet, imp=harbor-alpha-import, ob=harbor-alpha-outbox
|%
+$  vault  [seed=@ address=@t salt=@t verifier=@ux]
+$  quote  [balance=@ud nonce=@ud pending=@ud fee=@ud at=@da]
+$  draft  [id=@t tx=transfer:op nonce=@t expires=@da message=@t]
+$  io  [kind=?(%balance %fee %submit %lookup) serial=@ud hash=@t]
+$  wallet
  $:  version=%1
      key=(unit vault)
      funds=(unit quote)
      review=(unit draft)
      items=(list entry:ob)
      failures=@ud
      locked=@da
      sequence=@ud
      flight=(unit io)
      error=@t
  ==
++  initial
  ^-  wallet
  [%1 ~ ~ ~ ~ 0 `@da`0 0 ~ '']
++  hex32
  |=  text=@t
  ^-  (unit @ux)
  ?.  =(64 (met 3 text))  ~
  (rush text hex)
++  import-key
  |=  [w=wallet text=@t address=@t salt=@t verifier=@t]
  ^-  [error=@t next=wallet]
  =/  parsed  (read-key:imp text address)
  ?~  parsed  ['Expected a canonical 32-byte key and matching address' w]
  ?^  key.w
    ?:  ?&(=(seed.u.key.w seed.u.parsed) =(address.u.key.w address.u.parsed))  ['' w]
    ['A different wallet is already imported' w]
  =/  salt-ok  (hex32 salt)
  =/  pin  (hex32 verifier)
  ?.  ?&(?=(^ salt-ok) ?=(^ pin))  ['Invalid PIN verifier or salt' w]
  ['' w(key `[seed.u.parsed address.u.parsed salt u.pin], error '')]
++  seconds
  |=  now=@da
  (div (sub now ~1970.1.1) ~s1)
++  prepare
  |=  [w=wallet ship=@p network=@t id=@t to=@t amount=@ud now=@da entropy=@]
  ^-  [error=@t next=wallet]
  ?~  key.w  ['Import a wallet first' w]
  ?^  flight.w  ['Network check in progress' w]
  ?:  (lth now locked.w)  ['PIN locked; wait five minutes' w]
  ?:  (blocked:ob items.w)  ['Resolve the existing payment first' w]
  ?~  funds.w  ['Refresh balance and fee first' w]
  =/  q  u.funds.w
  ?:  (gth now (add at.q ~s60))  ['Balance and fee expired; refresh' w]
  ?.  =(nonce.q pending.q)  ['Account has another pending transaction' w]
  ?.  ?&((valid-address:op to) (gth amount 0) (lte amount 1.000.000.000.000.000) (gth fee.q 0) (lte fee.q 1.000.000))
    ['Invalid recipient, amount or fee' w]
  ?.  ?&((gth (met 3 id) 0) (lte (met 3 id) 100) (lte (add amount fee.q) balance.q) (lth nonce.q 2.147.483.647))
    ['Insufficient funds or invalid payment limits' w]
  ?:  (lien items.w |=(e=entry:ob ?|(=(id id.e) (gte nonce.tx.e +(nonce.q)))))
    ['Payment ID reused or node nonce behind saved history' w]
  =/  tx=transfer:op  [address.u.key.w to amount +(nonce.q) fee.q (seconds now)]
  =/  token  (scot %uv (sham [entropy now sequence.w tx id]))
  =/  expiry=@da  (add now ~m5)
  =/  message
    (cat 3 'harbor-alpha-v1|' (cat 3 (scot %p ship) (cat 3 '|' (cat 3 network (cat 3 '|' (scot %uv (sham [id tx token expiry])))))))
  ['' w(review `[id tx token expiry message], sequence +(sequence.w), error '')]
++  approve
  |=  [w=wallet token=@t proof=@t now=@da]
  ^-  [error=@t next=wallet]
  ?~  key.w  ['Import a wallet first' w]
  ?:  (lth now locked.w)  ['PIN locked; wait five minutes' w]
  ?~  review.w  ['No pending review' w]
  =/  d  u.review.w
  ?.  =(token nonce.d)  ['Review replaced; review again' w]
  ?:  (gte now expires.d)  ['Review expired' w(review ~)]
  ?:  ?|(?=(^ flight.w) (blocked:ob items.w))  ['A payment is already in progress' w]
  =/  got  (hex32 proof)
  =/  want  (hmac-sha256l:hmac:crypto [32 verifier.u.key.w] [(met 3 message.d) (swp 3 message.d)])
  ?.  ?&(?=(^ got) =(u.got want))
    =/  fails  +(?:(=(failures.w 5) 0 failures.w))
    ['Incorrect PIN' w(review ~, failures fails, locked `@da`?:(=(fails 5) (add now ~m5) 0))]
  =/  packet  (seal:pk tx.d seed.u.key.w)
  =/  e=entry:ob  [id.d tx.d packet %ready 0]
  =/  queued  (enqueue:ob items.w e)
  ?~  queued  ['Cannot queue this payment' w(review ~)]
  ['' w(items u.queued, funds ~, review ~, failures 0, locked `@da`0, error '')]
++  recover
  |=  w=wallet
  w(items (turn items.w recover:ob), funds ~, review ~, flight ~)
--
