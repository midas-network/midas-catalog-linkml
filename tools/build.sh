#!/usr/bin/env bash
#
# Build the published artifacts and the reference site from src/midas-catalog.yaml.
#
# Used by BOTH the release workflow and a local dry run, so what a maintainer can
# check on their laptop is exactly what CI publishes. It never deploys and never
# writes outside generated/, docs/reference/, docs/generated/ and site/ — all of
# which are git-ignored build output.
#
# Everything under those paths is regenerated from scratch on every run. That is the
# point: the published artifacts are a function of the published yaml, so a release
# cannot drift from the model it claims to describe. Nothing here is hand-editable.
#
# THE CONTEXT STEP IS TWO STEPS
# -----------------------------
# gen-jsonld-context is followed by transform_context.py, a verbatim copy of the
# private canonical repo's post-processor (see tools/README.md). It is not cosmetics:
# the generator coerces URI-valued slots to xsd:anyURI typed literals, which matches
# neither MIDAS's served JSON-LD nor the schema's own native RDF. Skipping it would
# publish a context that contradicts the live one. The script fails loudly if the
# generated context stops matching its expectations, so it can never become a quiet
# no-op.
#
# Usage: tools/build.sh [<venv-bin-dir>]
#   tools/build.sh                                       # tools on PATH (CI)
#   tools/build.sh ~/Documents/dev/linkml-tools/venv/bin # explicit venv (local)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$REPO/tools"
SCHEMA="$REPO/src/midas-catalog.yaml"
GENERATED="$REPO/generated"
REFERENCE="$REPO/docs/reference"
DOCS_GENERATED="$REPO/docs/generated"

BIN="${1:-}"
run() { if [ -n "$BIN" ]; then "$BIN/$1" "${@:2}"; else "$@"; fi; }
PY() { if [ -n "$BIN" ]; then "$BIN/python" "$@"; else python3 "$@"; fi; }

[ -f "$SCHEMA" ] || { echo "schema not found at $SCHEMA" >&2; exit 1; }

echo "== schema: $SCHEMA"
echo "== tools:  ${BIN:-<PATH>}"

# Fresh every time — a stale class page from a previous model is worse than none.
rm -rf "$GENERATED" "$REFERENCE" "$DOCS_GENERATED"
mkdir -p "$GENERATED" "$REFERENCE"

echo "-- gen-jsonld-context"
run gen-jsonld-context "$SCHEMA" > "$GENERATED/midas-catalog.context.jsonld"

echo "-- transform_context (allow-listed term-kind fixes)"
PY "$TOOLS/transform_context.py" "$GENERATED/midas-catalog.context.jsonld"

echo "-- gen-json-schema"
run gen-json-schema "$SCHEMA" > "$GENERATED/midas-catalog.schema.json"

echo "-- gen-owl"
run gen-owl "$SCHEMA" > "$GENERATED/midas-catalog.owl.ttl"

echo "-- gen-doc"
# --truncate-descriptions false: by default gen-doc cuts every table-cell description
# at the first "." (even inside "schema.org" or "e.g.") and at 80 chars. Off, it
# emits the full text with newlines joined as <br>, which keeps table rows intact.
run gen-doc "$SCHEMA" -d "$REFERENCE" --subfolder-type-separation --truncate-descriptions false

# The machine artifacts have to be reachable from the site, or generating them in a
# release job accomplishes nothing. MkDocs only serves what is under docs/, so mirror
# them in; docs/index.md links here, and the w3id layer can resolve to these URLs.
echo "-- stage machine artifacts for publication"
mkdir -p "$DOCS_GENERATED"
cp "$GENERATED/midas-catalog.context.jsonld" \
   "$GENERATED/midas-catalog.schema.json" \
   "$GENERATED/midas-catalog.owl.ttl" \
   "$DOCS_GENERATED/"

# The published yaml is itself an artifact consumers fetch and import.
cp "$SCHEMA" "$DOCS_GENERATED/midas-catalog.yaml"

echo "-- mkdocs build"
run mkdocs build --strict -f "$REPO/mkdocs.yml"

echo "== done — site/ built, nothing deployed"
