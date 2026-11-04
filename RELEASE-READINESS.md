# Current release readiness — 4 November 2026

Experimental source prerelease **0.1.0-alpha.1**. This assessment describes
the tested alpha and its remaining limits.

Ready for small, supervised alpha testing on a dedicated test ship with
trusted local apps and a minimally funded test wallet. Wider deployment
still has the limits listed below.

## Scope

Alpha covers **import/recovery and public payments** on the isolated test
moon. Wallet creation, private payments, Circle execution and integrated
bridging are excluded. Private proofs remain experimental: the full bound
proof passed pinned native verification in 2h16m observed wall time, so it is
not a release gate.

## What is tested

- **Devnet funded payment.** One Hoon-signed public payment on the funded
  devnet: exact full-record transaction ID, one submission, confirmed receipt,
  native hash/signature parity, PIN rejection and clean restart persistence.
- **Mainnet funded payment.** On 4 November, the separate test wallet sent
  0.001 OCT with a 0.001 OCT fee in one submission, confirmed at epoch 2308127.
  Harbor and a separate RPC read matched the receipt; the remaining balance
  is 0.003 OCT at nonce 1. A clean moon restart preserved both funded profiles,
  PIN metadata and receipts. This is one bounded mainnet test, not an audit.
  [Mainnet test summary](evidence/mainnet-alpha-summary.json).
- **Distinct network profiles.** Mainnet and devnet wallet profiles are kept
  separate; reuse of one address across both profiles is rejected.
- **Minimal package.** Deterministic allowlist packaging with a verified
  hash/length manifest. Compiled and checked on two isolated fake ships (HTTP
  and ordinary filesystem mount/commit path) and on a fresh real moon: 68
  empty-wallet HTTP checks pass before and after a same-pier restart.
- **Offline source archive.** Extracted and builds to the same verified
  manifest.
- **Unfunded restore rehearsal.** A stopped clean moon was archived and
  restored, with its original pier kept offline. The restored identity passed
  68 HTTP checks and stopped cleanly; parent and funded moon were unchanged.
  [Restore test](evidence/clean-moon-restore-boot-20261104.json).
  This does not establish funded-wallet recovery or upgrade compatibility.
- **License.** Owner approved GPL-2.0-or-later for original Harbor code;
  bundled upstream notices and exact Urbit base provenance are recorded.
- **Custody probes.** On a separate fresh unfunded custody moon: an ordinary cross-desk app
  read the target's plaintext saved state and wrote a harmless marker to the
  other desk through Hood; redaction on save hides the constant in `%gv`
  snapshots only, while the core canary survived a whole-ship restart. Both moons stopped cleanly; the parent and funded moon are
  unchanged. A cross-moon public echo succeeded while the local-only canary
  rejected the other moon, with its state unchanged. See [Gall key safety](docs/GALL-KEY-SAFETY.md).

## Limits

- **Trust boundary.** The host and all local apps are trusted: an ordinary
  cross-desk app can read plaintext saved state. Redaction on save is not
  encryption and not broader isolation. A short payment PIN is an approval
  step, not a second factor.
- **Experimental prerelease.** Source distribution does not establish
  production custody safety or general hosting compatibility.
- **No audit claim.** Local worker reviews are not an independent security
  audit; no production audit is claimed.

## Remaining gates

1. Independent security review of custody, signing, network identity, nonce
   handling and ambiguous submissions.
2. Unrelated-host installation, upgrade compatibility and funded-wallet
   recovery testing. The unfunded same-host restore rehearsal has passed.

Source and releases: [sv0boda/harbor](https://github.com/sv0boda/harbor).

## Links

- [Alpha user guide](docs/ALPHA-USER-GUIDE.md)
- [Alpha release checklist](docs/ALPHA-RELEASE-CHECKLIST.md)
- [Gall key safety](docs/GALL-KEY-SAFETY.md)
- [Portable alpha instructions](deploy/PORTABLE-ALPHA.md)
