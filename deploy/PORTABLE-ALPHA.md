# Portable Harbor public-payment alpha

The portable package contains the import-only wallet, separate mainnet/devnet profiles, public payments, PIN approval, saved submission records and receipt reconciliation. Wallet generation, private payments, Circles execution and the Octra bridge remain outside this minimal release. The separate prototype still contains their earlier UI work.

The wallet and signing keys persist inside Gall and the pier. The host operator and other local Gall apps can access them. The payment PIN is an application approval check, not a second factor or encryption of the event log. Keep the original recovery material and use a dedicated, minimally funded test wallet.

## Reproduce the package

Run the Python 3 builder from a repository checkout. It defaults to the twelve bundled public base files under `vendor/urbit-base`, pinned to the independently verified Urbit commit in `integrations/distribution-notices/base-source-provenance.json`. No ship connection or dependency download is needed to build the desk. The tested base is zuse 408; other base versions require compatibility checks.

Use a fresh output directory because the builder refuses to overwrite an existing artifact:

```sh
python3 deploy/build-portable-alpha.py \
  --ship '~your-planet' \
  --origin 'https://your-ship.example' \
  --output /path/to/new-harbor-alpha-desk
```

For a separately reviewed compatible base, supply `--base-source /path/to/public-base-export`. This directory must contain the twelve public files listed in the builder; do not supply a pier or wallet export. Bundled-base and explicit-export builds produced identical manifests in validation.

Replace the ship placeholder with its actual `@p` name. The builder validates the token's syntax; compilation on the target ship verifies the identity. Only HTTPS DNS or IPv4 origins are supported in this alpha. Include the external port when it is not 443. The reverse proxy must preserve that Host and Origin and forward the normal Eyre login/session routes. No secret belongs in the configuration file.

`manifest.json` records SHA-256 and byte length for each packaged file. `lib/harbor-alpha-config.hoon` contains the target ship, desk, allowed origin/host, RPC endpoints and devnet availability. The package uses the installed base's Kelvin requirement rather than a guessed version. The currently tested base is zuse 408.

Mainnet is enabled by default. Devnet is disabled unless `--enable-devnet` is supplied. That flag requires the separately configured, loopback-only allowlisted gateway at `127.0.0.1:18840`; it does not provision or expose a gateway. A managed-host customer needs the host's cooperation to provide this transport. The UI labels an unavailable network and the agent rejects actions against it. The user can switch away from an unavailable selected network.

## Install scope

The generated desk is named `%harbor-alpha`, its agent is `%harbor-alpha`, and its authenticated web route is `/harbor-alpha/`. It includes the required public base libraries and marks, `sys.kelvin`, and `desk.bill`. Docket metadata and an OTA distribution ship are not configured. Do not overwrite an existing desk or another app named `%harbor-alpha` without first reviewing its state and backing up the authoritative stopped pier.

The private development workspace's `tests/portable-install.py` is deliberately restricted to the existing local fakes `~nec` and `~zod`; it is not a general live-ship installer. The coordinator has compiled and installed the generated minimal desk there. `tests/portable-filesystem.py` also passes the normal filesystem mount/commit/unmount path, verifies all 35 manifest-listed files plus the manifest, and preserves the empty wallet state. It too is restricted to those existing fake ships. A fresh desk install on the second fake `~zod` also passed all 68 HTTP checks and exact filesystem package verification. HTTP tests check login, static assets, exact origin/host protection, stale network rejection and disabled devnet behavior. Funded settlement was tested separately on the real test moon, with a Hoon-signed devnet payment and a matching native/network transaction ID. One mainnet payment was also confirmed on 4 November 2026: 0.001 OCT plus 0.001 OCT fee, one submission, with clean restart persistence.

## Manual installation for a test ship

Use a disposable or dedicated test ship with compatible base/runtime, an HTTPS route to Eyre, and access to its mounted desk directory. Managed hosting requires the provider to support manual desk installation. This is not an OTA install and does not add a Landscape tile.

These commands use the Hood generators whose underlying operations were exercised on the isolated fakes. Installation on an unrelated owner's ship and provider-specific proxy configuration remain unverified. Do not use them to migrate an existing Harbor wallet or overwrite an existing `%harbor-alpha` desk, agent or route.

1. Build the desk with the target ship's actual name and the exact browser origin, including any nonstandard HTTPS port. Preserve the original wallet recovery material; if the ship already holds valuable state, take an identity-safe backup before changing its apps.
2. In the ship's Dojo, create and mount the new desk:

   ```hoon
   |new-desk %harbor-alpha
   |mount %harbor-alpha
   ```

   If asked to overwrite an existing desk, decline and investigate. Do not use a force/overwrite option.
3. On the host, copy the **contents** of the generated desk into the newly mounted `harbor-alpha` directory. For example, after replacing both paths:

   ```sh
   harbor_desk='/absolute/path/to/generated-desk'
   harbor_pier='/absolute/path/to/test-pier'
   cp -R "$harbor_desk"/. "$harbor_pier"/harbor-alpha/
   ```

   The source is the generated desk containing `desk.bill` and `manifest.json`, not the source repository or an archive wrapper directory. Do not copy any wallet or recovery files into the mount.
4. In Dojo, commit and install the local desk:

   ```hoon
   |commit %harbor-alpha
   |install our %harbor-alpha
   |unmount %harbor-alpha
   ```

5. Open `https://your-ship.example/harbor-alpha/` using the configured origin, sign in through the ship's normal Eyre login and verify the displayed ship/network. The initial profiles should be empty. Follow the [user guide](../docs/ALPHA-USER-GUIDE.md) to import only a dedicated test wallet.

A blank page or rejected action is not a reason to reset the ship. Check the exact origin/Host forwarding, Eyre login/session route, Kelvin compatibility and the installed agent's compilation status first. Preserve any saved payment records while investigating. See the [release checklist](../docs/ALPHA-RELEASE-CHECKLIST.md) for upgrade and recovery limits.

The owner selected GPL-2.0-or-later for original Harbor contributions; upstream notices are preserved. A general distribution still needs review of the complete bundled notices, published installation metadata, an upgrade/rollback procedure for another owner's ship, and independent security review. This experimental prerelease is not audited custody software.

## Source archive and repository

Download `harbor-alpha-source.tar.gz` and `SHA256SUMS` from the
[GitHub prerelease](https://github.com/sv0boda/harbor/releases/tag/v0.1.0-alpha.1).
In the download directory, verify the archive before extracting it:

```sh
shasum -a 256 -c SHA256SUMS
```

Extract outside your pier, then run the included portable builder as above.
The repository contains the same source kit at its tagged commit. Both include
runtime sources, pinned base dependencies, notices and selected evidence and
user/security documentation. Neither is an installable desk until built for
your ship. Private development history, operational installers, wallet files
and worker traces are excluded. The source archive was produced by an explicit
allowlist builder in the private development workspace; that archive builder
is not needed to build or install this package.
