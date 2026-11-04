# Gall key safety: evidence and options

Research checkpoint, 3 November 2026. This is a threat-model review, not an audit
or a claim that Harbor isolates keys from other installed apps.

Harbor currently stores the signing seed in its Gall state. An ordinary local
Gall agent can read another agent's saved state through the vane-level `%gv`
endpoint. The existing fake-ship canary demonstrated this with a public constant,
including when the target refused every `on-peek` request. See
[the original canary evidence](../evidence/custody-canary.json) and
[source review](../integrations/urbit-entropy-review/CUSTODY.md).

## What the source actually exposes

The [official Gall scry reference](https://docs.urbit.org/urbit-os/kernel/gall/scry)
distinguishes agent requests from vane requests with an empty path component.
The latter bypass the target's `on-peek`. Its `%v` endpoint returns an agent
snapshot, including saved state and activation statistics.

In the [pinned Gall source](https://github.com/urbit/urbit/blob/5a187fededc4582a34fcd6055c67bb63e0917b94/pkg/arvo/sys/vane/gall.hoon),
lines 114–135 define `agent=(each agent vase)`: the running branch is `%&`,
and `%|` holds a saved vase. Lines 3025–3043 clear the code field and return
either that saved vase or the running agent's `on-save` result. This endpoint
does **not** simply return the live agent core. A worker's contrary reading was
rejected after checking the type definition.

This distinction makes redaction worth testing. It does not establish that the
rest of the system provides a boundary against a hostile local app.

## Candidate protections

| Technique | What it can address | Limitation for Harbor |
|---|---|---|
| Restrict `src.bowl` to the local ship | Reject messages from foreign ships | Other local apps have that same ship identity. |
| Check `sap.bowl` caller provenance | Distinguish ordinary request paths in the tested API | Normal app provenance was observed; a direct low-level attempt rolled back. This limited test does not establish unforgeability or protect saved-state reads/code integrity. |
| Refuse `on-peek` | Hide an app's own query interface | Does not stop vane-level `%gv`. |
| Put the wallet on a separate desk | Organize dependencies and updates | A desk name alone does not prevent the demonstrated snapshot read. |
| Require the 4–6 digit payment PIN | Add an approval step in the intended workflow | The current verifier and seed are readable state; this is not key encryption or a second factor. |
| Encrypt saved state with a key kept outside the ship | Conceal plaintext in a saved-state snapshot while locked | Requires a reviewed unlock design, authenticated encryption, recovery, and investigation of all input/queue/log/code-integrity paths. A short PIN is unsuitable as the sole offline defense. |
| Return ciphertext/redacted state from `on-save`, keep an unlocked key in the core | Potentially narrow this specific snapshot exposure | The canary survived a clean runtime restart despite a zeroed snapshot. Gall reload and process restart differ; this is not memory-only storage or automatic locking. |
| Dedicated wallet moon with a separate HTTPS hostname and reviewed cookie scope | Reduce the set of apps sharing the wallet's Gall namespace and browser authority | Kernel, essential apps, updates, hosting operator and parent/networking authority remain trusted. Do not install untrusted apps on that moon. |
| Enforce per-app permissions in the kernel | Could provide a stronger boundary for reads and writes | This requires kernel design, compatibility work and review beyond a Harbor application change. No live kernel patch is proposed here. |

For a dedicated wallet moon, web-session separation matters too. A different
port on the same hostname creates a different browser origin, but does **not**
isolate cookies. [RFC 6265 §8.5](https://www.rfc-editor.org/rfc/rfc6265#section-8.5)
explicitly describes that limitation; sibling-domain cookie integrity also
needs review (§8.6). Use a separate hostname, host-only session cookies and
review the reverse proxy/session configuration before claiming browser
isolation. The current multi-port private access setup is not evidence of that
isolation. No owner session cookie was inspected or exercised for this research.

The [official app permission guidance](https://github.com/urbit/docs.urbit.org/blob/master/content/build-on-urbit/app-school/7-sur-and-marks.md)
explains that Ames authenticates the source ship. That establishes a useful
cross-ship identity check, rather than distinct identities for apps on one ship.
The [Clay permission documentation](https://github.com/urbit/developers.urbit.org/blob/main/content/reference/arvo/clay/tasks.md)
describes ship/group permissions; it should not be presented as an application
sandbox without further evidence.

## Tests on fresh moons

Two distinct, unfunded moons were created under the owner's authorization:
`~lordeg-nidnum-tiptux-ponryg` for clean installation, and
`~lidred-nilrev-tiptux-ponryg` for synthetic custody tests. Neither is a copy of
the existing Harbor moon. Parent and funded acceptance state are outside the
hostile-app test scope.

The clean moon passed all 68 empty-wallet HTTP checks on a fresh install; a
same-pier restart and another 68 checks also passed. Both new moons were then
cleanly stopped; their piers remain available for further tests. Custody tests use a public constant, explicit
target identities, separate target/probe desks, positive controls and
boolean-only output. A compilation failure or a probe that never executes is a
failed or inconclusive test, never evidence of isolation.

Executed results on the custody moon
([evidence](../evidence/custody-lab-moon.json)):

- A cross-desk `%gv` read from an ordinary app on a separate desk saw the
  target's plaintext saved constant and activation entropy.
- Redaction hid the saved constant and entropy in the snapshot, while a
  positive control queried the target's own boolean readiness endpoint and
  confirmed it still held the canary in its core. The probe did not read that core.
- Suspending the target left the plaintext constant readable, but the
  activation-entropy metadata no longer matched the saved entropy.
- Reloading the redacted target dropped the core canary.

A clean same-pier runtime restart was also tested with the redacted target
left active ([restart evidence](../evidence/redacted-runtime-restart-moon.json)).
The process changed from PID 11026 to 11413; before any target poke/reload,
its own readiness endpoint still reported the public canary in its core.
The separate probe still saw only zeroed saved state. Both desks were then
suspended. Thus `on-save` redaction does not make core state memory-only and
does not guarantee locking on a whole-ship restart. This does not establish
which exact checkpoint/replay mechanism retained it or expose any real key.

A separate cross-desk integrity probe
([evidence](../evidence/clay-integrity-lab-moon.json)) ran an ordinary Gall app
on its own desk: Hood accepted its write, the exact public text marker was
verified, then removed, and the probe was suspended. No wallet keys were read
in either test, and no production code was changed.

The caller-provenance experiment used another public target/probe pair
([evidence](../evidence/provenance-lab-moon.json)). A normal app poke reported
`/gall/lab-origin-probe` in the target's `sap.bowl`. A separate lower-level
Gall request carrying `/eyre` failed with a Gall reply-routing assertion and
left the target unchanged. The first attempt combined both requests and rolled
back the positive control too; the final test separated them. No spoofed
provenance was observed, and this is not a proof that provenance cannot be
forged through another path. No such check was added to Harbor as a claimed
security boundary.

A real cross-moon check then tested the proposed ship boundary
([evidence](../evidence/cross-ship-lab-moons.json)). The clean moon sent one
request to a deliberately public echo on the isolation moon, and one to the
local-only redacted canary. The public request succeeded, the protected request
received a negative acknowledgment, and the protected canary stayed locked.
The positive control ruled out missing connectivity as the explanation for
rejection. Both test moons were cleanly stopped afterward.

What this does not yet show: redaction is not encryption, and none of these
probes proves host protection, a full sandbox, or that source code cannot be
mutated. Desk separation alone is therefore insufficient. Further key
isolation needs either a reviewed integrity/unlock design or a reduced, fully
trusted app set on a dedicated wallet moon.

No custody redesign has been deployed to the owner's wallet, and no private
payment support is included in this alpha.

## Practical next architecture

Keep signing and the only persistent wallet on a dedicated wallet moon, with
a small reviewed set of essential apps and controlled updates. Give its owner
interface a distinct HTTPS hostname and reviewed session-cookie scope. This
retains an Urbit-native wallet without introducing a signing helper. It requires
a separately hosted ship/runtime; an app inside one managed ship cannot create
this boundary by choosing a different desk.

A companion app on the everyday planet may propose a payment or request public
information. Its authenticated ship identity must not by itself authorize
signing: other apps on that planet share the identity. The owner should review
and approve on the wallet moon's own interface. No remote signing API or
automatic approval has been added in this research. Future Circle or bridge
content needs its own browser execution boundary rather than access to the
wallet interface's origin or signing state.

Encryption can be additional protection, but it needs a separate design for
unlock, key derivation, historical event/checkpoint exposure, recovery and code
integrity. The current short PIN and redaction experiment do not supply that
design. Host-level protection remains a separate threat model.
