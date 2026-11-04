# Harbor Alpha User Guide

This guide covers the import-only public-payment alpha. It is an experimental
alpha, not a general release: no production-security audit or production-ready
claim is made.

## Prerequisites and deployment status

- A dedicated, minimally funded test wallet. Keep its original recovery
  material; Harbor import needs it. Avoid using that address concurrently from
  other wallets while testing.
- A ship with an HTTPS origin. Mainnet is enabled by default; devnet is
  disabled unless a separately configured, loopback-only gateway is supplied.
  See [deploy/PORTABLE-ALPHA.md](../deploy/PORTABLE-ALPHA.md) for the
  portable package, configuration and current installation scope.
- Current deployment status:
  - The private test moon has confirmed funded devnet and mainnet payments.
    The mainnet test sent 0.001 OCT with a 0.001 OCT fee in one submission;
    a clean restart preserved the receipts and both network profiles.
  - The minimal portable desk compiles and installs on an isolated fake ship;
    ordinary filesystem mount/commit and package-content verification also pass there. A fresh desk on a second isolated fake ship also passed. Installation on another owner’s ship remains unverified.
  - The owner approved GPL-2.0-or-later for original Harbor contributions;
    upstream licenses and notices are included.
- Outside this minimal alpha: wallet creation, private payments, Circles
  execution and the integrated Bridge.

## Wallet import

Harbor is import-only: it does not create wallets.

1. Select the intended network profile first (see below).
2. Upload the original wallet JSON, or enter a canonical 32-byte Base64/hex key. The matching `oct…` address is always required; a supported JSON export can fill it automatically. Check it before importing.
3. Supported JSON includes `priv`/`addr`,
   `private_key_b64`/`private_key_hex`/`address`, and nested
   `keyPair.secretKey`/`keyPair.publicKey` with `address`. The nested `keyPair.secretKey` is a 64-byte hexadecimal seed-plus-public-key export; its suffix must match `keyPair.publicKey`, and only the seed is imported. Raw key entry accepts the 32-byte seed, not a 64-byte secret key. Files are limited to 4 KiB. Mnemonic-only and encrypted
   `wallet.oct` imports are unsupported.
4. Choose a 4–6 digit PIN. Every payment requires it in this alpha.

Same-key reimport preserves the PIN, cooldown and history. It cannot change
the PIN or replace the active wallet. There is no reset/forget/export
endpoint.

## Separate network profiles

Mainnet and devnet are separate profiles. Each profile has its own key, PIN
metadata, quotes, nonce sequence and payment history.

- Importing the same address into both profiles is rejected, because current
  signed packets have no chain ID. Keep the addresses exclusive to their chosen networks; profile separation does not add cryptographic replay protection to Octra’s packet format.
- The UI labels an unavailable network, and the agent rejects actions against
  it. You can switch away from an unavailable selected network.
- Switching networks clears form drafts and transient quotes. An active
  review, request, or queued/sending payment blocks switching.
- Pending or unknown payments remain in their own profile and can be
  reconciled after you return to it.
- If another tab changes the network, refresh before continuing. Stale actions are rejected instead of being applied to a different profile.

## Balance refresh

Use Refresh to read the real balance and fee from the selected network before
paying. Refresh does not create, sign or submit a payment. Mainnet refresh reports an unfunded account correctly; devnet
balance/fee reads pass after the current promotion.

## Review, PIN, send, and receipt

These are public blockchain payments, not anonymous transactions. To cancel a review and change networks, close the dialog and Refresh to clear the saved review.

1. Refresh, then enter the recipient and amount.
2. Review the network, fee and nonce shown for the payment.
3. Approve with the PIN. The raw PIN is not sent to Gall; the browser derives
   a proof bound to the current review.
4. The signed packet is persisted before a separate dispatch event and is
   submitted once. Acceptance stays pending until a matching confirmed
   receipt is reconciled.

Timing and limits:

- A quote expires after 60 seconds; the confirmed and pending nonce must
  match.
- A review binds ship, network, recipient, amount, fee, nonce, timestamp and
  challenge, and expires after five minutes.
- Five bad proofs impose a five-minute cooldown.
- Only one unresolved payment is allowed at a time.
- Confirmed receipts must match sender, recipient, amount, nonce, fee and a
  positive epoch. History is capped at 100 entries; reaching the cap blocks further payments. No pruning workflow is included.

## Ambiguous payment troubleshooting and recovery

- If a reply is lost, the payment keeps an unknown record. Use Reconcile to
  query its saved transaction ID; this does not re-sign or resend.
- Rejected or dropped records deliberately block later sends until
  investigated.
- A clean restart preserves receipts, PIN metadata and network profiles. Submitted payments are not automatically resent. An approved packet that had not yet been dispatched can still be dispatched after restart. App upgrades and network switches clear transient quotes.
- A new empty agent can import the original recovery material, but it does
  not reconstruct lost local outbox history. Reconcile unresolved network
  activity before spending again.
- Restoring an older pier can restore stale nonce and outbox records while
  the blockchain retains later payments. Stop payment activity and reconcile
  the network nonce and saved transaction hashes before approving more.
  Never boot a restored copy alongside the original live ship identity.

If Devnet becomes unavailable while an approved payment is queued, the ship preserves the record and stops dispatch. Network switching may remain blocked. Ask the operator to investigate the transport/configuration; do not delete the saved record or import the key elsewhere to resend.

## Custody and trust notes

- The wallet and signing keys persist inside Gall and the pier. The host
  operator and other local Gall apps can access them; a
  local `%gv` scry can expose saved agent state.
- The payment PIN is an application approval check, not a second factor and
  not encryption of the event log. The PIN verifier persists in Gall.
- Signing occurs in Hoon on the ship; the devnet gateway never receives
  wallet secrets or signs.

The configured Octra RPC is trusted for balances, fees and receipt status. Harbor checks response fields against its saved payment, but it does not independently validate Octra consensus.

## References

- [Portable package and installation](../deploy/PORTABLE-ALPHA.md)
- [Current readiness](../RELEASE-READINESS.md)
- [Gall key safety](GALL-KEY-SAFETY.md)
