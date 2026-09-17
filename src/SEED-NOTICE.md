# ⚠️ `midas-catalog.yaml` here is a PRE-FREEZE SEED — not for publish

`src/midas-catalog.yaml` in this repo is a **byte-identical copy** of the
`1.0.0-SNAPSHOT` model as it stood in the private canonical repo
(`midas-contact-db`, `src/main/resources/linkml/midas-catalog.yaml`) when this
repository was scaffolded on **2026-09-15**.

It is here as a **build seed only** — something real for the toolchain to generate
from, so the pipeline and the site could be verified before the freeze. It is **not a
release**, and it is **not the published model**.

`-SNAPSHOT` means the model is still moving. Publishing from it would put a version on
the public record that the project intends to keep changing.

## This is enforced, not just documented

`tools/check_release_version.sh` — which every release runs first — fails if the
schema's `version:` contains `-SNAPSHOT`, and fails if the tag version and the schema
version disagree. So a `v1.0.0` tag pushed against this seed does not publish: it stops
at the gate.

## What happens at the freeze

1. The model is frozen in the private canonical repo with a non-SNAPSHOT `version:`.
2. That yaml is copied over this file's neighbour verbatim.
3. **This notice file is deleted** — it describes a state that no longer exists.
4. The release is tagged `v<version>`, matching the yaml exactly.

## Why byte-identical

The copy carries no local edits — no banner, no marker comment — precisely so a
maintainer can verify the publish is a faithful copy and not a fork:

```bash
diff src/midas-catalog.yaml \
     ../midas-contact-db/src/main/resources/linkml/midas-catalog.yaml
```

Any output from that command at release time is a problem. That check is worth more
than a comment inside the file, which is why the warning lives here instead.
