#!/usr/bin/env bash
#
# Release gate: refuse to publish anything that is not a frozen, non-SNAPSHOT release.
#
# Publishing is one-way and versioned — once the reference site is up at a version,
# that version is what the world cites. A -SNAPSHOT model is by definition still
# moving, so it must never reach Pages. This script is the single place that decides
# "is this publishable", so CI and a maintainer checking locally apply the same rule.
#
# Checks, in order:
#   1. the git tag looks like v<semver-ish>            (v1.0.0, v1.0.1-rc.1)
#   2. neither the tag nor the schema says -SNAPSHOT   (case-insensitive)
#   3. the tag version EQUALS src/midas-catalog.yaml's `version:`
#
# Check 3 is the one that catches the real mistake: tagging v1.0.0 while the seeded
# yaml still holds the pre-freeze copy. The tag does not define the release — the
# published yaml does — so they have to agree.
#
# Usage: tools/check_release_version.sh <tag>   (e.g. v1.0.0)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMA="$REPO/src/midas-catalog.yaml"
TAG="${1:-}"

die() { echo "RELEASE GATE FAILED: $*" >&2; exit 1; }

[ -n "$TAG" ]     || die "no tag given (usage: $0 <tag>)"
[ -f "$SCHEMA" ]  || die "schema not found at $SCHEMA"

[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] \
  || die "tag '$TAG' is not a vMAJOR.MINOR.PATCH release tag"

TAG_VERSION="${TAG#v}"

# `version:` at column 0 — the schema's own version, not a slot named version.
SCHEMA_VERSION="$(sed -n 's/^version:[[:space:]]*//p' "$SCHEMA" | head -1 | tr -d '"'"'"' \r')"
[ -n "$SCHEMA_VERSION" ] || die "no top-level 'version:' found in $SCHEMA"

shopt -s nocasematch
[[ "$TAG_VERSION"    != *snapshot* ]] || die "tag '$TAG' is a -SNAPSHOT; snapshots are never published"
[[ "$SCHEMA_VERSION" != *snapshot* ]] || die \
  "schema version '$SCHEMA_VERSION' is a -SNAPSHOT — src/midas-catalog.yaml still holds a pre-freeze copy. Copy the frozen yaml from the private canonical before tagging."
shopt -u nocasematch

[ "$TAG_VERSION" = "$SCHEMA_VERSION" ] || die \
  "tag version '$TAG_VERSION' != schema version '$SCHEMA_VERSION' — the tag must name the version of the yaml being published"

echo "release gate passed: tag $TAG, schema version $SCHEMA_VERSION"
