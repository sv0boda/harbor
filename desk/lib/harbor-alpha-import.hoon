/+  op=harbor-octra-public
::  Strict canonical 32-byte seed import; never logs or exports the seed.
|%
++  read-key
  |=  [text=@t expected=@t]
  ^-  (unit [seed=@ address=@t])
  ?.  ?&(=(44 (met 3 text)) (valid-address:op expected))  ~
  =/  decoded  (de:base64:mimes:html text)
  ?~  decoded  ~
  ?.  ?&(=(p.u.decoded 32) =(text (en:base64:mimes:html [32 q.u.decoded])))  ~
  =/  derived  (address:op (public-key:op q.u.decoded))
  ?.  =(derived expected)  ~
  `[q.u.decoded derived]
--
