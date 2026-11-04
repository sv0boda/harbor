# Harbor alpha dependency and notice inventory

This inventory records upstream declarations and provenance. The owner approved GPL-2.0-or-later for original Harbor contributions on 3 November 2026; the root LICENSE applies that choice. Publication has not been authorized by that license decision alone.

| Material | Included in minimal package | Declared notice / provenance |
| --- | --- | --- |
| Urbit base marks, server/default-agent/skeleton/dbug libraries and Kelvin manifest | Twelve explicit public files, also pinned under `vendor/urbit-base` for offline packaging | MIT; every file matches official commit `5a187fededc4582a34fcd6055c67bb63e0917b94` exactly after resolving repository links. See `base-source-provenance.json` and `URBIT-LICENSE.txt`. |
| Octra-derived authentication and transaction compatibility code | Public-payment Hoon libraries | Pinned webcli `549536d6fbe265a4aace02bc9b85b5313ebb4868`; the port's attribution identifies GPL-2.0-or-later. `OCTRA-COPYING` preserves upstream attribution and its OpenSSL permission; `GPL-2.0.txt` is the referenced license text. |
| Harbor Gall agent, browser UI, packaging and gateway | Original project sources | GPL-2.0-or-later, approved by the owner; see the root LICENSE. The current deployment remains a private alpha. |
| Native OpenSSL, webcli executable, PVAC private-proof libraries, REA tooling and prototype Bridge/Circles UI | Not bundled in minimal desk | Reference/test material elsewhere in the workspace is not part of the minimal runtime package. |

The Urbit source files were exported from the installed test moon, independently compared with the pinned official repository, and used to compile/install the minimal desk on isolated fake `~nec`. The exported base's Kelvin requirement is `[%zuse 408]`. The official repository stores many `pkg/arvo` paths as links to `pkg/base-dev`; the recorded source chains resolve those links before hashing. Comparing the short link text itself would give a false mismatch.

The Octra snapshot had already been checked against its pinned Git tree. Its local `COPYING` notice was copied verbatim; an unsuccessful web-cache lookup was not substituted for that evidence. All hashes and retrieval URLs are in `provenance.json`.

Before publishing, review the complete combined distribution and its notices. The root license was applied only after the owner explicitly approved the proposed terms. This inventory is a factual source record, not an independent legal review.

Sources: [Urbit license at the pinned commit](https://github.com/urbit/urbit/blob/5a187fededc4582a34fcd6055c67bb63e0917b94/LICENSE.txt), [pinned Octra COPYING](https://github.com/octra-labs/webcli/blob/549536d6fbe265a4aace02bc9b85b5313ebb4868/COPYING), [GNU GPL version 2 text](https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt).
