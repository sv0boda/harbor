::  Import-only network-isolated wallet. No key creation/export or automatic resend.
/+  default-agent, server, ac=harbor-alpha-core, aj=harbor-alpha-json, ob=harbor-alpha-outbox, an=harbor-alpha-network, nj=harbor-alpha-profile-json, cf=harbor-alpha-config
=|  profile:an
=*  profile  -
=*  state  active.profile
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def  ~(. (default-agent this %|) bowl)
    network  (wire-network:an selected.profile)
    endpoint  ?:(=(%mainnet selected.profile) mainnet-endpoint:cf devnet-endpoint:cf)
    respond
      |=  [p=profile:an id=@ta code=@ud error=@t]
      ^-  (list card:agent:gall)
      (give-simple-payload:app:server id [[code ~[['content-type' 'application/json'] ['cache-control' 'no-store'] ['x-content-type-options' 'nosniff']]] `(json-to-octs:server (pairs:enjs:format ~[['ok' b+=(error '')] ['error' s+error] ['state' (snapshot:nj p our.bowl devnet-enabled:cf)]]))])
    watchers
      |=  [target=path who=@p]
      (levy ~(val by sup.bowl) |=([ship=@p path=path] ?|(!=(path target) =(ship who))))
    start-rpc
      |=  [w=wallet:ac kind=?(%balance %fee %submit %lookup) hash=@t method=@t params=(list json)]
      ^-  [(list card:agent:gall) wallet:ac]
      ?>  ?=(~ flight.w)
      =/  seq  +(sequence.w)
      =/  body  (json-to-octs:server (pairs:enjs:format ~[['jsonrpc' s+'2.0'] ['id' (numb:enjs:format seq)] ['method' s+method] ['params' a+params]]))
      :_  w(sequence seq, flight `[kind seq hash], error '')
      :~  [%pass /rpc/[selected.profile]/(scot %ud seq) %arvo %i %request [%'POST' endpoint ~[['content-type' 'application/json']] `body] [0 0]]
          [%pass /timeout/[selected.profile]/(scot %ud seq) %arvo %b %wait (add now.bowl ~s20)]
      ==
    fail-rpc
      |=  [w=wallet:ac reason=@t]
      ^-  (quip card:agent:gall agent:gall)
      =/  updated
        w(flight ~, error reason)
      =?  updated  ?=(^ flight.w)
        ?:  =(%submit kind.u.flight.w)
          updated(items (turn items.w recover:ob))
        ?:  ?|(=(%balance kind.u.flight.w) =(%fee kind.u.flight.w))
          updated(funds ~)
        updated
      `this(state updated)
++  on-init
  ?>  =(our.bowl ship:cf)
  :_  this(profile initial:an)
  ~[[%pass /bind %arvo %e %connect [~ /harbor-alpha] dap.bowl]]
++  on-save  !>(profile)
++  on-load
  |=  old=vase
  ?>  =(our.bowl ship:cf)
  =/  loaded=profile:an
    ?:  ?=([%1 *] +.old)  (migrate:an !<(wallet:ac old))
    (recover:an !<(profile:an old))
  :_  this(profile loaded)
  :~  [%pass /bind %arvo %e %connect [~ /harbor-alpha] dap.bowl]
      [%pass /dispatch/[selected.loaded] %arvo %b %wait (add now.bowl ~s1)]
  ==
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card:agent:gall agent:gall)
  ?>  =(mark %handle-http-request)
  =/  req  !<([id=@ta in=inbound-request:eyre] vase)
  =/  url  url.request.in.req
  ?.  ?&(authenticated.in.req =(src.bowl our.bowl))
    ?:  ?|(=(url '/harbor-alpha/') =(url '/harbor-alpha'))
      [(give-simple-payload:app:server id.req [[307 ~[['location' '/~/login?redirect=/harbor-alpha/'] ['cache-control' 'no-store']]] ~]) this]
    ::  No wallet snapshot for unauthenticated callers.
    [(give-simple-payload:app:server id.req [[401 ~[['content-type' 'application/json'] ['cache-control' 'no-store']]] `(json-to-octs:server (pairs:enjs:format ~[['error' s+'Owner login required']]))]) this]
  ?.  (watchers /http-response/[id.req] our.bowl)  [(respond profile id.req 403 'Response subscription denied') this]
  ?:  =(method.request.in.req %'GET')
    ?:  =(url '/harbor-alpha/api/state')  [(respond profile id.req 200 '') this]
    =/  asset=(unit [type=@t file=@ta])
      ?+  url  ~
        %'/harbor-alpha/'  `['text/html; charset=utf-8' %index]
        %'/harbor-alpha/app.mjs'  `['text/javascript' %app]
        %'/harbor-alpha/alpha-view.mjs'  `['text/javascript' %alpha-view]
        %'/harbor-alpha/network-picker.mjs'  `['text/javascript' %network-picker]
        %'/harbor-alpha/pin-client.mjs'  `['text/javascript' %pin-client]
        %'/harbor-alpha/style.css'  `['text/css' %style]
      ==
    ?~  asset  [(respond profile id.req 404 'Not found') this]
    =/  content  .^(@t %cx /(scot %p our.bowl)/[desk:cf]/(scot %da now.bowl)/web/harbor-alpha/[file.u.asset]/hoon)
    :_  this
    (give-simple-payload:app:server id.req [[200 ~[['content-type' type.u.asset] ['cache-control' 'no-store'] ['x-content-type-options' 'nosniff'] ['referrer-policy' 'no-referrer'] ['content-security-policy' (crip "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")]]] `[(met 3 content) content]])
  ?.  ?&(=(method.request.in.req %'POST') =(url '/harbor-alpha/api/action'))  [(respond profile id.req 405 'Method not allowed') this]
  =/  headers  header-list.request.in.req
  ?.  ?&  =(`origin:cf (get-header:http 'origin' headers))
          =(`host:cf (get-header:http 'host' headers))
          =(`'1' (get-header:http 'x-harbor' headers))
          =(`'application/json' (get-header:http 'content-type' headers))
      ==
    [(respond profile id.req 403 'Same-origin JSON request required') this]
  =/  body  body.request.in.req
  ?~  body  [(respond profile id.req 400 'JSON required') this]
  ?:  (gth p.u.body 4.096)  [(respond profile id.req 413 'Request too large') this]
  =/  json  (de:json:html q.u.body)
  ?~  json  [(respond profile id.req 400 'Invalid JSON') this]
  =/  j  u.json
  =/  op  (string:aj j 'op')
  ?~  op  [(respond profile id.req 400 'Action required') this]
  =/  expected  (string:aj j 'expectedNetwork')
  ?.  =(`network expected)
    [(respond profile id.req 409 'Network changed; refresh before continuing') this]
  ?:  ?&(=(%devnet selected.profile) !devnet-enabled:cf !=(u.op %network))
    [(respond profile id.req 409 'Devnet is not available on this ship') this]
  =/  done
    |=  outcome=[error=@t next=wallet:ac]
    ^-  (quip card:agent:gall agent:gall)
    =/  next  this(state next.outcome)
    [(respond profile(active next.outcome) id.req ?:(=(error.outcome '') 200 422) error.outcome) next]
  ?+  u.op  [(respond profile id.req 400 'Unknown action') this]
    %import
      =/  text  (string:aj j 'privateKey')
      =/  addr  (string:aj j 'address')
      =/  salt  (string:aj j 'salt')
      =/  verifier  (string:aj j 'verifier')
      ?.  ?&(?=(^ text) ?=(^ addr) ?=(^ salt) ?=(^ verifier))  [(respond profile id.req 400 'Import fields required') this]
      ?:  ?&(?=(^ key.inactive.profile) =(address.u.key.inactive.profile u.addr))
        [(respond profile id.req 422 'Use a different wallet address for each network') this]
      (done (import-key:ac state u.text u.addr u.salt u.verifier))
    %network
      =/  target  (string:aj j 'network')
      ?.  ?|  =(`'mainnet-alpha' target)
              =(`'devnet' target)
          ==
        [(respond profile id.req 400 'Unknown network') this]
      =/  chosen=network:an  ?:(=(`'devnet' target) %devnet %mainnet)
      ?:  ?&(=(%devnet chosen) !devnet-enabled:cf)
        [(respond profile id.req 409 'Devnet is not available on this ship') this]
      ?:  =(chosen selected.profile)  [(respond profile id.req 200 '') this]
      ?^  review.state  [(respond profile id.req 409 'Close the payment review and refresh before changing networks') this]
      =/  outcome  (switch:an profile chosen)
      [(respond next.outcome id.req ?:(=('' error.outcome) 200 409) error.outcome) this(profile next.outcome)]
    %prepare
      =/  id  (string:aj j 'id')
      =/  to  (string:aj j 'to')
      =/  amount  (number:aj j 'amount')
      ?.  ?&(?=(^ id) ?=(^ to) ?=(^ amount))  [(respond profile id.req 400 'Payment fields required') this]
      (done (prepare:ac state our.bowl network u.id u.to u.amount now.bowl eny.bowl))
    %approve
      =/  token  (string:aj j 'nonce')
      =/  proof  (string:aj j 'proof')
      ?.  ?&(?=(^ token) ?=(^ proof))  [(respond profile id.req 400 'Approval fields required') this]
      =/  outcome  (approve:ac state u.token u.proof now.bowl)
      =/  result  (done outcome)
      ?.  =(error.outcome '')  result
      [[[%pass /dispatch/[selected.profile] %arvo %b %wait (add now.bowl ~s1)] -.result] +.result]
    %sync
      ?~  key.state  [(respond profile id.req 422 'Import a wallet first') this]
      ?^  flight.state  [(respond profile id.req 409 'Network check in progress') this]
      =/  next  (start-rpc state(funds ~, review ~) %balance '' 'octra_balance' ~[s+address.u.key.state])
      [(weld (respond profile(active +.next) id.req 200 '') -.next) this(state +.next)]
    %reconcile
      ?^  flight.state  [(respond profile id.req 409 'Network check in progress') this]
      =/  hash  (string:aj j 'hash')
      ?~  hash  [(respond profile id.req 400 'Hash required') this]
      =/  entry  (skim items.state |=(e=entry:ob =(hash.packet.e u.hash)))
      ?~  entry  [(respond profile id.req 404 'Unknown payment') this]
      ?:  =(phase.i.entry %ready)  [(respond profile id.req 409 'Submission not started') this]
      =/  next  (start-rpc state %lookup u.hash 'octra_transaction' ~[s+u.hash])
      [(weld (respond profile(active +.next) id.req 200 '') -.next) this(state +.next)]
  ==
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card:agent:gall agent:gall)
  ?:  ?=([%eyre %bound *] sign-arvo)  `this
  ::  A deployment can disable devnet while a previously approved packet is
  ::  still queued. Preserve the record, but do not dispatch or continue RPCs.
  ?:  ?&(=(%devnet selected.profile) !devnet-enabled:cf)  `this
  ?:  =(wire /dispatch/[selected.profile])
    ?^  flight.state
      [~[[%pass /dispatch/[selected.profile] %arvo %b %wait (add now.bowl ~s2)]] this]
    =/  found  (skim items.state |=(e=entry:ob =(phase.e %ready)))
    ?~  found  `this
    =/  e  i.found
    =/  sent  (dispatch:ob e)
    ?~  sent  `this
    =/  next=wallet:ac
      state(items (turn items.state |=(old=entry:ob ?:(=(id.old id.e) u.sent old))))
    =/  body  (de:json:html body.packet.e)
    ?~  body  `this(state next(error 'Saved packet invalid; payment paused', items (turn items.next recover:ob)))
    =/  rpc  (start-rpc next %submit hash.packet.e 'octra_submit' ~[u.body])
    [-.rpc this(state +.rpc)]
  ?~  flight.state  `this
  =/  f  u.flight.state
  =/  serial  (scot %ud serial.f)
  ?:  =(wire /timeout/[selected.profile]/[serial])
    =/  failed  (fail-rpc state 'Network request timed out. Refresh account data or reconcile an existing payment.')
    [[[%pass /rpc/[selected.profile]/[serial] %arvo %i %cancel-request ~] -.failed] +.failed]
  ?.  ?&(=(wire /rpc/[selected.profile]/[serial]) ?=([%iris %http-response *] sign-arvo))  `this
  =/  rep  client-response.sign-arvo
  ?-  -.rep
    %cancel  (fail-rpc state 'Network request cancelled. Refresh account data or reconcile an existing payment.')
    %progress
      ?.  (gth bytes-read.rep 65.536)  `this
      =/  failed  (fail-rpc state 'Response exceeded size limit')
      [[[%pass /rpc/[selected.profile]/[serial] %arvo %i %cancel-request ~] -.failed] +.failed]
    %finished
      ?.  =(status-code.response-header.rep 200)  (fail-rpc state 'RPC HTTP error; check status')
      ?~  full-file.rep  (fail-rpc state 'Empty RPC response')
      ?:  (gth p.data.u.full-file.rep 65.536)  (fail-rpc state 'Response exceeded size limit')
      =/  decoded  (de:json:html q.data.u.full-file.rep)
      ?~  decoded  (fail-rpc state 'Invalid RPC JSON')
      =/  j  u.decoded
      =/  version  (string:aj j 'jsonrpc')
      =/  rid  (number:aj j 'id')
      ?.  ?&(=(`'2.0' version) =(`serial.f rid))  (fail-rpc state 'RPC response identity mismatch')
      =/  result  (field:aj j 'result')
      =/  error  (field:aj j 'error')
      ?.  ?&(?=(^ result) ?=(~ error))
        =/  reason=@t
          ?-  kind.f
            %balance
              ?~  error  'Balance refresh returned no result. Try Refresh again.'
              ?:  ?&(=(`100 (number:aj u.error 'code')) =(`'sender not found' (string:aj u.error 'message')))
                'Octra has no account record for this address (RPC 100). If this wallet is new, receive OCT at this address, then Refresh.'
              'Octra rejected the balance refresh. Try Refresh again.'
            %fee  'Octra rejected the fee request. Try Refresh again.'
            %submit  'Octra rejected or did not acknowledge submission. Reconcile the saved payment before sending again.'
            %lookup  'Octra could not find or return this payment. Its saved record is unchanged; reconcile again later.'
          ==
        (fail-rpc state reason)
      =/  next  state(flight ~, error '')
      ?-  kind.f
        %balance
          ?~  key.state  (fail-rpc state 'Wallet missing')
          =/  balance  (balance:aj u.result address.u.key.state)
          ?~  balance  (fail-rpc state 'Invalid account response')
          =/  rpc  (start-rpc next(funds `[raw.u.balance nonce.u.balance pending.u.balance 0 `@da`0]) %fee '' 'octra_recommendedFee' ~[s+'standard'])
          [-.rpc this(state +.rpc)]
        %fee
          =/  fee  (number:aj u.result 'recommended')
          ?.  ?&(?=(^ fee) (gth u.fee 0) (lte u.fee 1.000.000) ?=(^ funds.state))  (fail-rpc state 'Invalid fee quote')
          `this(state next(funds `u.funds.state(fee u.fee, at now.bowl)))
        %submit
          =/  hash  (string:aj u.result 'tx_hash')
          ?.  =(`hash.f hash)  (fail-rpc state 'Submission hash mismatch; reconcile saved payment')
          =/  entries
            %+  turn  items.state
            |=  e=entry:ob
            ?.  =(hash.packet.e hash.f)  e
            (fall (observe:ob e hash.f %pending) e)
          `this(state next(items entries))
        %lookup
          =/  found  (skim items.state |=(e=entry:ob =(hash.packet.e hash.f)))
          ?~  found  (fail-rpc state 'Saved payment missing')
          =/  seen  (receipt:aj u.result i.found)
          ?~  seen  (fail-rpc state 'Transaction receipt did not match saved payment')
          =/  entries
            %+  turn  items.state
            |=  e=entry:ob
            ?.  =(hash.packet.e hash.f)  e
            (fall (observe:ob e hash.f u.seen) e)
          `this(state next(items entries, funds ~))
      ==
  ==
++  on-watch
  |=  =path
  ?>  ?=([%http-response @ ~] path)
  ?>  (watchers path src.bowl)
  `this
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ~
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-fail  on-fail:def
--
