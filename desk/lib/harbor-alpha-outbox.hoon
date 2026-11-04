/+  op=harbor-octra-public, pk=harbor-octra-packet
::  One unresolved payment; no automatic resend or terminal-error clearing.
|%
+$  phase  ?(%ready %sending %unknown %pending %confirmed %rejected %dropped)
+$  entry  [id=@t tx=transfer:op packet=packet:pk phase=phase attempts=@ud]
++  blocked
  |=  items=(list entry)
  ^-  ?
  (lien items |=(e=entry !=(phase.e %confirmed)))
++  enqueue
  |=  [items=(list entry) next=entry]
  ^-  (unit (list entry))
  ?.  ?&((lth (lent items) 100) !(blocked items) =(phase.next %ready) =(attempts.next 0))  ~
  ?.  ?&((gth (met 3 id.next) 0) (lte (met 3 id.next) 100) =(canonical.packet.next (canonical:op tx.next)))  ~
  ?:  (lien items |=(e=entry ?|(=(id.e id.next) =(hash.packet.e hash.packet.next) (gte nonce.tx.e nonce.tx.next))))  ~
  `[next items]
++  dispatch
  |=  e=entry
  ^-  (unit entry)
  ?.  ?&(=(phase.e %ready) =(attempts.e 0))  ~
  `e(phase %sending, attempts 1)
++  recover
  |=  e=entry
  ^-  entry
  ?:  =(phase.e %sending)  e(phase %unknown)
  e
++  observe
  |=  [e=entry hash=@t seen=phase]
  ^-  (unit entry)
  ?.  ?&(=(hash hash.packet.e) =(attempts.e 1) !=(phase.e %ready))  ~
  ?.  ?|(=(seen %pending) =(seen %confirmed) =(seen %rejected) =(seen %dropped))  ~
  ?:  =(phase.e %confirmed)  `e
  `e(phase seen)
--
