# Gall custody boundary — 1 November 2026

The fake-ship test confirms that an ordinary local Gall agent can read another agent's saved state through the vane-level `%gv` scry. Refusing all `on-peek` requests does not block this path. The snapshot also exposes the target's most recent activation entropy. This is an application trust boundary, not evidence of remote unauthenticated access.

`tests/test_custody_canary.py` installed two disposable agents on fake zod. The target saved only the public integer 123456789 and its test activation entropy. The probe compared the snapshot internally and returned booleans only. Both comparisons passed; both agents were suspended afterward. No wallet, owner data, live planet or real secret was accessed. See `evidence/custody-canary.json`.

The public official Arvo source pinned in `manifest.json` corroborates the result: Gall's `%v` scry returns an `egg-any` with the target's `on-save` vase and activation statistics. An ordinary agent's namespace resolver permits the local snapshot. Source files are reference data only, not installed software. [Pinned Gall source](https://github.com/urbit/urbit/blob/5a187fededc4582a34fcd6055c67bb63e0917b94/pkg/arvo/sys/vane/gall.hoon).

Consequences for Harbor:

- Plaintext keys in persistent Gall state are readable by other local apps. Normal HTTP authentication, a restrictive `on-peek`, and the payment PIN do not establish isolation from those apps.
- Deriving a key solely from the last activation entropy does not conceal it from a reader of that snapshot.
- The 4–6 digit PIN is an online approval control, not a cryptographic defense against local apps, full-pier copies or the host administrator. A readable PIN verifier must not be described as protecting against local apps either.
- A dedicated wallet ship can reduce the number of trusted apps. It does not eliminate trust in its kernel, essential apps, host, backups or installed updates, and must not be represented as an app sandbox.
- A proposal to encrypt saved state needs a separately reviewed unlock/recovery and event-log design. Merely encrypting `on-save` with the short PIN or storing the wrapping key elsewhere in the same ship does not resolve this finding.

The owner requested a dedicated test moon. ~tamdex-nartev-tiptux-ponryg is provisioned on VM103 with a separate OS account and pier, private HTTPS, and verified authenticated login after a clean post-sync restart. It retains the default system/Landscape/Webterm/Groups apps; all remain inside the local-app trust boundary, along with the host, backups and parent networking authority. No Harbor custody agent or real Octra wallet is installed there yet. Public transaction and recovery work can continue.
