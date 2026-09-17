#!/usr/bin/env python
"""
Post-process the gen-jsonld-context output: fix the term-kind of URI-valued slots.

WHY THIS STEP EXISTS
--------------------
LinkML's two official output paths disagree about slots declared `range: uri`
(or `uriorcurie`):

  * `gen-jsonld-context` coerces them to `"@type": "xsd:anyURI"`, i.e. a TYPED
    LITERAL;
  * the native instance->RDF path (`linkml-convert -t rdf`) emits them as IRI
    NODES.

Expanding our JSON-LD therefore produced `xsd:anyURI` literals that matched
neither the published schema.org artifact (plain literals) nor the schema's own
native RDF (IRI nodes). See the 2026-08-13 S-vs-L triple comparison.

THE SPLIT IS DELIBERATE — there is NO blanket "all uri slots" rule
-----------------------------------------------------------------
Two different intents share one LinkML range:

  FLIP_TO_NODE   DCAT predicates whose range is genuinely a *resource*. dcat:accessURL
                 and dcat:landingPage are `rdfs:range rdfs:Resource`; a literal there
                 is simply wrong, and consumers cannot traverse it. These become
                 `"@type": "@id"` -> IRI nodes.

  STRIP_DATATYPE schema.org predicates whose value is a URL-shaped *datatype*.
                 schema.org types these as Text/URL, and the published S artifact
                 emits plain literals. Dropping the coercion makes L agree with S
                 and keeps the value a literal. These lose `"@type"` entirely.

Each key is listed explicitly with the `@id` it is expected to carry. If the
generated context ever stops matching those expectations (renamed slot, changed
slot_uri, upstream LinkML behaviour change) this script FAILS rather than
silently doing nothing — the transform must never become a quiet no-op.

Idempotent: re-running against an already-transformed context is a no-op and
still exits 0.

Usage: transform_context.py <context.jsonld> [<output.jsonld>]
       (in-place when no output path is given)
"""
import json
import sys

ANYURI = "xsd:anyURI"

# key -> expected "@id" in the generated context.
FLIP_TO_NODE = {
    "accessUrl": "dcat:accessURL",
    "endpointUrl": "dcat:landingPage",
}
# These @ids track the schema's default_prefix. While it was `schema` the generator
# shortened them to bare names ("url"); since it became `midas` (2026-08-28) they
# render as CURIEs ("schema:url"). Changing default_prefix again means updating them.
STRIP_DATATYPE = {
    "sameAs": "schema:sameAs",
    "url": "schema:url",
    "codeRepository": "schema:codeRepository",
    "propertyID": "schema:propertyID",
    "inDefinedTermSet": "schema:inDefinedTermSet",
}


def main():
    in_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else in_path

    with open(in_path) as fh:
        doc = json.load(fh)
    ctx = doc["@context"]

    errors, changed, already = [], [], []

    def check(key, expected_id):
        entry = ctx.get(key)
        if entry is None:
            errors.append("%s: absent from the generated context" % key)
            return None
        if not isinstance(entry, dict):
            errors.append("%s: expected an object term definition, got %r" % (key, entry))
            return None
        if entry.get("@id") != expected_id:
            errors.append("%s: expected @id %r, found %r"
                          % (key, expected_id, entry.get("@id")))
            return None
        return entry

    for key, expected_id in sorted(FLIP_TO_NODE.items()):
        entry = check(key, expected_id)
        if entry is None:
            continue
        before = dict(entry)
        if entry.get("@type") == "@id":
            already.append(key)
            continue
        if entry.get("@type") != ANYURI:
            errors.append("%s: expected @type %r, found %r"
                          % (key, ANYURI, entry.get("@type")))
            continue
        entry["@type"] = "@id"
        changed.append((key, before, dict(entry)))

    for key, expected_id in sorted(STRIP_DATATYPE.items()):
        entry = check(key, expected_id)
        if entry is None:
            continue
        before = dict(entry)
        if "@type" not in entry:
            already.append(key)
            continue
        if entry.get("@type") != ANYURI:
            errors.append("%s: expected @type %r, found %r"
                          % (key, ANYURI, entry.get("@type")))
            continue
        del entry["@type"]
        changed.append((key, before, dict(entry)))

    if errors:
        sys.stderr.write("transform_context.py: REFUSING to write\n")
        for e in errors:
            sys.stderr.write("  ERROR %s\n" % e)
        return 1

    # Any xsd:anyURI term outside the allow-list is reported, not silently accepted
    # and not auto-fixed. As of 2026-08-31 these are broadMatch and exactMatch (`iri`
    # was retired with LicenseInfo/RightsInfo): both are URI-ranged but the converter
    # never emits them, so they produce no triples and were deliberately left out of
    # scope. A NEW name appearing here is a prompt to decide which group it belongs to.
    leftover = sorted(k for k, v in ctx.items()
                      if isinstance(v, dict) and v.get("@type") == ANYURI)

    # indent=3 and no trailing newline reproduce gen-jsonld-context's own layout as
    # it is placed under runtime/, so the only diff this step introduces is the
    # allow-listed term definitions.
    with open(out_path, "w") as fh:
        json.dump(doc, fh, indent=3)

    print("transform_context.py: %s -> %s" % (in_path, out_path))
    print("  allow-list: %d flip-to-node, %d strip-datatype"
          % (len(FLIP_TO_NODE), len(STRIP_DATATYPE)))
    for key, before, after in changed:
        print("  CHANGED %-18s %s  ->  %s"
              % (key, json.dumps(before, sort_keys=True), json.dumps(after, sort_keys=True)))
    for key in already:
        print("  already-correct %s" % key)
    if leftover:
        print("  NOTE out-of-scope xsd:anyURI terms left untouched: %s" % leftover)
    else:
        print("  xsd:anyURI terms remaining: 0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
