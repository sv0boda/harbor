# Harbor public-payment alpha — v0.1.0-alpha.1

Experimental source prerelease: **0.1.0-alpha.1**.

Harbor is an import-only Urbit wallet for public Octra payments. This is a
public experimental alpha: not a general release, not audited custody software, and
not production-ready.

## Scope

The minimal portable package (the `%harbor-alpha` desk, agent, and
`/harbor-alpha/` web route) includes:

- Import-only wallet: you bring an existing Octra wallet. The **original
  recovery material is required**; Harbor does not create wallets.
- Separate mainnet-alpha and devnet profiles, each with its own key, PIN
  metadata, quotes, nonce sequence, and payment history.
- Public payments with PIN approval, saved submission records, and receipt
  reconciliation.
- Mainnet enabled by default; devnet disabled unless explicitly enabled and
  wired to a separately configured, loopback-only gateway.

Outside this minimal alpha: wallet creation, private payments
(Encrypt/Decrypt), Circles execution, and the integrated Octra Bridge.

## Verified evidence

- Funded devnet acceptance on the private test moon: a Hoon-signed payment was
  submitted once and confirmed at epoch 1789783; an independent native
  Ed25519 reference reproduced the ship's signature and full network
  transaction ID against the same dedicated test wallet.
- A clean restart of the test moon preserved the payment, PIN metadata, and
  network profiles without resubmission; expired quotes are rejected.
- Funded mainnet acceptance passed on 4 November 2026: one 0.001 OCT payment,
  fee 0.001 OCT, confirmed at epoch 2308127 with one submission. Harbor and
  a separate RPC read matched the receipt and 0.003 OCT remaining balance.
  A clean moon restart preserved mainnet/devnet receipts and PIN metadata.
  This is a bounded test; no production-security claim follows.
- An unfunded clean moon passed a same-host backup/restore rehearsal:
  original pier offline, restored identity verified, 68 HTTP checks passed,
  and clean shutdown. Funded-wallet recovery and upgrades remain untested.
- The minimal portable desk compiled and installed on an isolated fake ship;
  68 HTTP checks, 58 configuration-toggle checks, and 20 packaging test groups pass,
  plus a counterfactual test proving disabled devnet cannot dispatch a
  previously queued packet.
- Packet-level checks: Hoon packet vectors with rejection cases, independent
  Python and Node signature/ledger-ID and tamper checks, gateway HTTP checks,
  and exact-submit framing checks.
- A fake-ship canary test confirmed that an ordinary local Gall app can read
  another app's saved state and activation entropy via `%gv`, even when
  `on-peek` denies reads.
- The first funded setup exposed a signing-digest/ledger-ID mismatch hidden by
  older mock coverage; Hoon and the independent oracles now use the full
  signed ledger record hash, corrected before a real Harbor payment.

Details: [current readiness](RELEASE-READINESS.md), [portable package](deploy/PORTABLE-ALPHA.md),
[custody review](integrations/urbit-entropy-review/CUSTODY.md),
[release checklist](docs/ALPHA-RELEASE-CHECKLIST.md).

## Known limitations

Public payments are recorded on Octra. This release does not provide anonymous or private transactions.

- **PIN is not 2FA or encryption.** The 4–6 digit PIN is an online approval
  control. The seed and PIN verifier persist in Gall and the pier/event log;
  a short PIN does not protect against full-pier copies.
- **Host and all other local Gall apps are trusted.** Local `%gv` can
  expose saved agent state; normal HTTP authentication, a restrictive
  `on-peek`, and the PIN do not isolate from other local apps.
- **Mainnet coverage is limited.** One small public transfer is verified;
  broad network/load/failure coverage and independent security review remain open.
- **Installation scope remains limited.** Ordinary filesystem mount/commit, typed Clay content checks and unmount pass on two isolated fake ships, including a fresh desk installation and every bundled notice and manifest. A general live-ship installer and installation on another owner’s ship have not been validated.
- Importing the same address into both profiles is rejected because current
  signed packets have no chain ID. Profile separation does not create cryptographic replay protection; keep each address exclusive to its chosen network. Mnemonic-only and encrypted wallet imports
  are unsupported.
- No reset/forget/export endpoint; a new empty agent can import recovery
  material but does not reconstruct lost local outbox history.
- History is capped at 100 entries; reaching that cap prevents further
  payments. There is no history-pruning workflow. Only one unresolved
  payment is allowed at a time.
- No production-security audit or general-release claim is made.

## Upgrade caution

- Do not overwrite an existing desk or another app named `%harbor-alpha`
  without first reviewing its state and backing up the authoritative stopped
  pier.
- Do not downgrade v2 state to v1 code; prefer a forward fix. Restore a
  stopped authoritative pier only with identity-safe procedures, never by
  booting a duplicate ship.
- Backups contain wallet secrets; keep them protected.
- Restoring an older pier can restore stale nonce and outbox records while
  the blockchain retains later payments. Stop payment activity and reconcile
  the network nonce and saved transaction hashes before approving more.
- Use a dedicated, minimally funded test wallet, and keep its original
  recovery material. Avoid using that address concurrently from other wallets
  while testing.
- The package uses the installed base's Kelvin requirement (currently tested
  base: zuse 408) rather than a guessed version.

## License

- Original Harbor contributions: **GPL-2.0-or-later**, approved by the owner.
  See the root [LICENSE](LICENSE); upstream terms remain preserved.
- Bundled Urbit base files (twelve explicit public files): MIT, matching the
  pinned official commit exactly.
- Octra-derived authentication and transaction compatibility code: upstream
  attribution preserved (GPL-2.0-or-later per the port's attribution, with the
  OpenSSL permission notice).
- A general distribution still needs review of the complete bundled notices,
  published installation metadata, an upgrade/rollback procedure for another
  owner's ship, and independent security review.

See the [notice inventory](integrations/distribution-notices/INVENTORY.md) for
provenance and the full notice record.
