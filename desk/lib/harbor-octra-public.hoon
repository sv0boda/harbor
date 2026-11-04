::  Standard public-transfer wire primitives. No network or persistent keys.
::  Compatibility target: octra-labs/webcli 549536d6, lib/tx_builder.hpp.
|%
+$  transfer
  [from=@t to=@t amount=@ud nonce=@ud ou=@ud seconds=@ud]
++  decimal
  |=  n=@ud
  (crip (scow %ud n))
++  digits
  |=  n=@ud
  ::  scow %ud groups thousands; the wire protocol never does.
  =/  chars  (scow %ud n)
  (crip (skim chars |=(c=@t !=(c '.'))))
++  valid-address
  |=  addr=@t
  ^-  ?
  ?.  ?&(=(47 (met 3 addr)) =('oct' (cut 3 [0 3] addr)))  |
  =/  alphabet  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  (levy (trip (rsh [3 3] addr)) |=(c=@t (lien alphabet |=(a=@t =(a c)))))
++  address
  |=  public-key=@
  ^-  @t
  ?>  (lte (met 3 public-key) 32)
  ::  SHA256 returns byte-order atoms; Base58 consumes a big-endian integer.
  =/  digest  (shay 32 public-key)
  =/  number  (rev 3 32 digest)
  =/  text=tape  (en-base58:mimes:html number)
  =/  padded  (weld (reap (sub 44 (lent text)) '1') text)
  (cat 3 'oct' (crip padded))
++  canonical
  |=  tx=transfer
  ^-  @t
  ?>  ?&((valid-address from.tx) (valid-address to.tx))
  ?>  ?&((gth amount.tx 0) (lte amount.tx 1.000.000.000.000.000))
  ?>  ?&((gth nonce.tx 0) (lte nonce.tx 2.147.483.647))
  ?>  ?&((gth ou.tx 0) (lte ou.tx 1.000.000.000.000.000))
  ?>  ?&((gte seconds.tx 1.000.000.000) (lte seconds.tx 9.999.999.999))
  %-  crip
  %-  zing
  %+  turn
    :~  '{"from":"'  from.tx  '","to_":"'  to.tx
        '","amount":"'  (digits amount.tx)
        '","nonce":'  (digits nonce.tx)
        ',"ou":"'  (digits ou.tx)
        '","timestamp":'  (digits seconds.tx)
        '.0,"op_type":"standard"}'
    ==
  trip
++  public-key
  |=  seed=@
  ?>  (lte (met 3 seed) 32)
  (puck:ed:crypto seed)
++  signature
  |=  [tx=transfer seed=@]
  ?>  (lte (met 3 seed) 32)
  =/  message  (canonical tx)
  (sign-octs:ed:crypto [(met 3 message) message] seed)
++  signature-base64
  |=  [tx=transfer seed=@]
  (en:base64:mimes:html [64 (signature tx seed)])
++  public-base64
  |=  seed=@
  (en:base64:mimes:html [32 (public-key seed)])
--
