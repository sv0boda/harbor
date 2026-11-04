<p align="center">
  <img src="assets/harbor-logo.png" alt="Harbor — white Carthage harbor symbol on a blue square" width="160" height="160">
</p>

# Harbor

An Octra wallet on Urbit: import an existing wallet and make public payments, with signing and persistent wallet state in Gall.

**v0.1.0-alpha.1 — experimental prerelease.** This standalone OFFLINE source kit builds a desk for your ship; it is not preconfigured. Use a dedicated test ship and a minimally funded wallet.

## Build

Extract this archive outside your pier, then from the extracted harbor-alpha-source/ directory run:

    python3 deploy/build-portable-alpha.py --ship '~your-planet' \
        --origin https://your-ship.example --output /path/to/new-desk

The builder includes the pinned zuse408 base dependencies offline under vendor/urbit-base/. It generates the desk %harbor-alpha with route /harbor-alpha/. This source kit is NOT itself an installable desk.

## Scope and trust

- Mainnet is the default; devnet requires a separate loopback gateway.
- No wallet generation, no private payments, no bridge, no circle execution.
- PIN is not 2FA and not encryption.
- All local Gall apps can read plaintext saved keys; trust every installed app, the kernel and host.
- External recovery is required.
- Verified: one small funded mainnet payment and funded devnet payment, plus clean restart persistence. No audit.

## Install

Follow the [installation guide](deploy/PORTABLE-ALPHA.md), then the [user guide](docs/ALPHA-USER-GUIDE.md) for import and payments. Read the [release notes](RELEASE-NOTES-ALPHA.md) and [Gall custody findings](docs/GALL-KEY-SAFETY.md) before importing keys.

## License and attribution

The source kit ships its license and third-party attribution notices (LICENSE and integrations/distribution-notices/).
