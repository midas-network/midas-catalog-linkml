# midas-catalog-linkml

**Maintainer documentation.** For the model itself and how to use it, see the published
site: <https://midas-network.github.io/midas-catalog-linkml/>

## What this repo is

The public, one-way, versioned **publish target** for the MIDAS Catalog LinkML model and
its generated reference documentation.

The canonical `midas-catalog.yaml` is authored in the private `midas-contact-db` repo
(`src/main/resources/linkml/`) and **copied here at release**. This repo is not an
authoring home:

- **Never edit `src/midas-catalog.yaml` here.** Model changes are made in the private
  canonical repo, reviewed there, and copied over at freeze. An edit made here would be
  silently overwritten by the next copy — and would mean the published artifacts describe
  a model that exists nowhere else.
- **Never hand-edit generated output.** Everything under `generated/`, `docs/reference/`,
  `docs/generated/` and `site/` is produced by `tools/build.sh` at release and is
  git-ignored. It is a function of the published yaml, not an artifact to maintain.

The only hand-written content here is `docs/index.md` (orientation), this README, and the
build configuration.

## Current state — pre-freeze

`src/midas-catalog.yaml` currently holds a **pre-freeze `1.0.0-SNAPSHOT` copy**, seeded
from the private canonical so the toolchain could be built and verified. See
[`src/SEED-NOTICE.md`](src/SEED-NOTICE.md).

**Nothing has been published from it, and nothing can be:** the release gate
(`tools/check_release_version.sh`) refuses any tag whose version is a `-SNAPSHOT`, or
whose version disagrees with the yaml being published. The first real publish happens at
the 1.0.0 freeze, when the frozen yaml is copied in and tagged `v1.0.0`.

## How a release works

Publishing is triggered **only** by pushing a `v*` release tag. There is no publish on
push to `main`, and no manual deploy path.

```
git tag v1.0.0 && git push origin v1.0.0
```

`.github/workflows/publish.yml` then:

1. **Gates the release** — `tools/check_release_version.sh v1.0.0` requires a
   `vMAJOR.MINOR.PATCH` tag, refuses `-SNAPSHOT` in either the tag or the schema's
   `version:`, and requires the two to be equal.
2. **Installs the pinned toolchain** — `requirements-linkml.txt` (a verbatim copy of the
   private repo's freeze, `linkml==1.11.1`) and `requirements-docs.txt`.
3. **Regenerates everything** — `tools/build.sh` runs `gen-jsonld-context` (plus the
   required `transform_context.py` post-step), `gen-json-schema`, `gen-owl` and `gen-doc`,
   then `mkdocs build --strict`.
4. **Deploys `site/` to GitHub Pages.**

Regenerating fresh on every release is what keeps the published artifacts consistent with
the published yaml — they are never carried forward from a previous release.

### Releasing a new model version

1. Freeze the model in the private canonical repo; set its `version:` to a non-SNAPSHOT
   value.
2. Copy the yaml over verbatim:
   `cp ../midas-contact-db/src/main/resources/linkml/midas-catalog.yaml src/midas-catalog.yaml`
3. Delete `src/SEED-NOTICE.md` if it is still present (first release only).
4. Dry-run locally (below) and confirm the build is clean.
5. Confirm the copied tooling has not drifted from the canonical repo:
   ```bash
   diff tools/transform_context.py ../midas-contact-db/tools/linkml/transform_context.py
   diff requirements-linkml.txt    ../midas-contact-db/tools/linkml/requirements.txt
   ```
6. Optionally verify the generated artifacts against the canonical pipeline's — see
   [`tools/README.md`](tools/README.md) for the comparison (and why the OWL must be compared
   as a graph, not byte-for-byte).
7. Commit, then tag `v<version>` matching the yaml's `version:` exactly and push the tag.

## Local dry run

Builds exactly what CI builds, and deploys nothing:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-linkml.txt -r requirements-docs.txt
.venv/bin/python -c "import sys; print(sys.version)"   # toolchain pinned to Python 3.11

tools/build.sh "$PWD/.venv/bin"      # gen-* + mkdocs build → site/
.venv/bin/mkdocs serve               # optional: preview at http://127.0.0.1:8000/
```

`tools/build.sh` takes an optional venv `bin` directory; with no argument it uses whatever
is on `PATH` (which is how CI runs it).

The release gate can be rehearsed without tagging:

```bash
tools/check_release_version.sh v1.0.0   # fails while the yaml is a -SNAPSHOT
```

## Layout

| Path | |
| --- | --- |
| `src/midas-catalog.yaml` | The published model. Copied from the private canonical; never edited here. |
| `docs/index.md` | The only hand-written page on the site. |
| `mkdocs.yml` | Site configuration (Material theme; nav = overview + generated reference). |
| `tools/build.sh` | Generates all artifacts and builds the site. Shared by CI and local dry runs. |
| `tools/check_release_version.sh` | The release gate. |
| `tools/transform_context.py` | Verbatim copy of the canonical context post-processor — see `tools/README.md`. |
| `requirements-linkml.txt` | Verbatim copy of the private repo's pinned LinkML freeze. |
| `requirements-docs.txt` | Pinned MkDocs toolchain. |
| `generated/`, `docs/reference/`, `docs/generated/`, `site/` | Build output. Git-ignored, regenerated every release. |

## Version reflected

`src/midas-catalog.yaml` → `1.0.0-SNAPSHOT` (pre-freeze seed; not published).
