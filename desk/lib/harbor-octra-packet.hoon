/+  op=harbor-octra-public, au=harbor-octra-auth
::  Pure public-transfer packet. No custody, approval, nonce allocation or IO.
|%
+$  packet
  [canonical=@t hash=@t body=@t public-key=@t signature=@t]
++  ledger-canonical
  |=  [tx=transfer:op signature=@t public-key=@t]
  ^-  @t
  =/  canonical  (canonical:op tx)
  =/  suffix  ',"op_type":"standard"}'
  =/  prefix  (cut 3 [0 (sub (met 3 canonical) (met 3 suffix))] canonical)
  %-  crip
  %-  zing
  %+  turn
    :~  prefix  ',"signature":"'  signature
        '","op_type":"standard","public_key":"'  public-key
        '","message":null,"encrypted_data":null}'
    ==
  trip
++  seal
  |=  [tx=transfer:op seed=@]
  ^-  packet
  ?>  (lte (met 3 seed) 32)
  ?>  =(from.tx (address:op (public-key:op seed)))
  =/  canonical  (canonical:op tx)
  =/  signature  (signature-base64:op tx seed)
  =/  public-key  (public-base64:op seed)
  ::  The node hashes the full signed ledger record, not the signing preimage.
  =/  ledger  (ledger-canonical tx signature public-key)
  =/  hash  (hex32:au (shay (met 3 ledger) ledger))
  ::  Keep the exact approved canonical fields, adding only signed-envelope fields.
  =/  head  (cut 3 [0 (dec (met 3 canonical))] canonical)
  =/  body
    %-  crip
    %-  zing
    %+  turn
      :~  head  ',"signature":"'  signature
          '","public_key":"'  public-key  '"}'
      ==
    trip
  [canonical hash body public-key signature]
--
