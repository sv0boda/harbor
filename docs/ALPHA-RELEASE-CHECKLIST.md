# Alpha release checklist

This checklist records the scope of the first experimental GitHub prerelease.
Source: [sv0boda/harbor](https://github.com/sv0boda/harbor). Publication is
separate from the security and compatibility work still unchecked below.

## Scope and evidence

- [x] Narrow scope to import/recovery and public payments; exclude wallet creation, private payments, Circle execution and integrated bridging.
- [x] Verify Hoon signing and the deployed node's full-record transaction ID with an independent native implementation.
- [x] Complete a small funded devnet payment, one submission, receipt matching and restart persistence on the isolated test moon.
- [x] Preserve distinct mainnet/devnet wallet profiles and reject reuse of one address across both profiles.
- [x] Test unavailable-network UI and backend rejection, including a queued-payment counterfactual.
- [x] Verify mainnet balance/error handling without sending a mainnet payment.
- [x] Complete one funded mainnet acceptance payment: 0.001 OCT, fee 0.001 OCT, one submission, confirmed receipt and clean restart persistence (4 November 2026). This does not establish production readiness.
- [ ] Obtain independent review of custody, signing, network identity, nonce handling and ambiguous submissions. Local worker reviews are not a security audit.

Receipts are under `evidence/`; current conclusions are in [release readiness](../RELEASE-READINESS.md). Historical status entries must not be used as current claims.

## Distribution

- [x] Record version `0.1.0-alpha.1` in the source kit and archive metadata.

- [x] Apply the owner's approved GPL-2.0-or-later license to original code and preserve upstream terms.
- [x] Record exact provenance for all twelve bundled Urbit base files.
- [x] Package an explicit file allowlist, configurable ship/origin and a deterministic hash/length manifest; exclude private data and worker traces.
- [x] Compile the minimal desk and check authenticated HTTP behavior on an isolated fake ship.
- [x] Verify the ordinary filesystem mount/commit path on the isolated fake ship, including notices and manifest files.
- [x] Verify a fresh desk on a second isolated fake ship; both pass HTTP and filesystem checks.
- [ ] Review installation on an unrelated host/provider before describing it as generally supported.
- [x] Use a fresh source-only Git history from the reviewed explicit allowlist; exclude private operational files and all development history. Credential-marker checks are heuristic, not an exhaustive security audit.
- [x] Obtain owner authorization for publication to `sv0boda/harbor`.
- Release procedure: tag the reviewed source commit as `v0.1.0-alpha.1`, attach its source archive and checksum, and verify the public downloads before reporting publication complete.

Installation is manual; OTA distribution is not configured.

## Upgrade and recovery rehearsal

An unfunded clean moon passed a same-host offline backup/restore, runtime
identity check, 68 HTTP checks and clean stop on 4 November 2026. Its original
pier stayed offline; no wallet was imported. Funded-wallet recovery and
upgrade compatibility remain unverified.

Before changing a key-holding ship, preserve its original wallet recovery material and make a verified backup of the authoritative stopped pier. Never boot a copied live identity alongside the original. This repository's development installers are restricted tools, not general recovery utilities.

Record the installed source version and inspect saved payment states before upgrading. Do not clear the outbox, reset a wallet or reuse a nonce to resolve an error. Reconcile submitted or uncertain payments against the network first. A timeout is not proof that a payment failed.

After an upgrade, verify wallet addresses, selected network, PIN metadata, saved receipts, asset versions and read-only balance refresh. Then use a small dedicated test payment only within the authorized network and funding scope.

Downgrading code across a state schema change is not an established rollback procedure. Restoring an older pier can also restore stale nonce/outbox information while the blockchain retains later transactions. Stop payment activity and investigate before restoring; do not resume signing until account nonce and saved submissions are reconciled. The funded moon has a protected, compared offline backup, but its restore has not been boot-tested.

## Documentation acceptance

Release notes and the user guide must identify the tested network, observed limitations, custody boundary, external recovery requirement and exact installation scope. They must not promise anonymity for public payments, describe a PIN as 2FA, claim unverified network coverage, or present experimental private proofs as a released payment feature.
