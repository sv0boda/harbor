/+  op=harbor-octra-public
::  Authentication message bytes, pinned webcli 549536d6 (GPL-2.0-or-later).
::  Pure codecs/signing primitives only. Caller owns permissions and secret custody.
|%
+$  octets  [size=@ud data=@]
++  hex32
  |=  value=@
  ^-  @t
  ?>  (lte (met 3 value) 32)
  =/  alphabet  "0123456789abcdef"
  =/  index=@ud  0
  =/  reversed=tape  ~
  |-  ^-  @t
  ?:  =(index 32)  (crip (flop reversed))
  =/  byte  (cut 3 [index 1] value)
  $(index +(index), reversed [(snag (dis byte 15) alphabet) (snag (rsh [0 4] byte) alphabet) reversed])
++  frame
  |=  [domain=@t fields=(list octets)]
  ^-  octets
  ?>  ?&((lte (met 3 domain) 64) (lte (lent fields) 8))
  =/  pieces=(list [@ud @])  ~[[(met 3 domain) domain]]
  =/  size=@ud  (met 3 domain)
  |-  ^-  octets
  ?~  fields  [size (can 3 pieces)]
  =/  f  i.fields
  ?>  ?&((lte size.f 4.096) (lte (met 3 data.f) size.f))
  =/  prefix  (cat 3 '|' (cat 3 (digits:op size.f) ':'))
  =/  width=@ud  (met 3 prefix)
  $(fields t.fields, size (add size (add width size.f)), pieces (weld pieces ~[[width prefix] [size.f data.f]]))
++  balance-message
  |=  addr=@t
  ^-  octets
  ?>  (valid-address:op addr)
  =/  text  (cat 3 'octra_encryptedBalance|' addr)
  [(met 3 text) text]
++  register-message
  |=  [addr=@t blob=octets]
  ^-  octets
  ?>  ?&((valid-address:op addr) (lte size.blob 33.554.432) (lte (met 3 data.blob) size.blob))
  =/  text  (cat 3 'register_pvac|' (cat 3 addr (cat 3 '|' (hex32 (shay size.blob data.blob)))))
  [(met 3 text) text]
++  circle-message
  |=  fields=(list octets)
  ^-  octets
  ?>  =(4 (lent fields))
  (frame 'octra_circle_auth_v2' fields)
++  sign-message
  |=  [message=octets seed=@]
  ^-  @
  ?>  ?&((lte (met 3 seed) 32) (lte size.message 17.408) (lte (met 3 data.message) size.message))
  (sign-octs:ed:crypto [size.message data.message] seed)
++  signature-base64
  |=  [message=octets seed=@]
  ^-  @t
  (en:base64:mimes:html [64 (sign-message message seed)])
--
