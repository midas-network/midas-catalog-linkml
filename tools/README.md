# tools/

Build and release tooling. Nothing here is generated; nothing here is a model.

## `build.sh`

Generates every published artifact from `src/midas-catalog.yaml` and builds the site.
Shared by `.github/workflows/publish.yml` and local dry runs, so a maintainer's laptop
build and the release build are the same build. Deploys nothing.

## `check_release_version.sh`

The release gate: a `v*` tag, no `-SNAPSHOT` in tag or schema, and tag version equal to
the schema's `version:`. Run first in the release workflow; runnable locally to rehearse
a release.

## `transform_context.py`

A **verbatim copy** of `tools/linkml/transform_context.py` from the private canonical
repo (`midas-contact-db`). Kept byte-identical so drift is detectable:

```bash
diff tools/transform_context.py \
     ../midas-contact-db/tools/linkml/transform_context.py
```

That is why its docstring refers to paths and decision logs in the private repo — it has
not been rewritten for this one.

### Why it is copied here at all

`gen-jsonld-context` coerces slots declared `range: uri`/`uriorcurie` to
`"@type": "xsd:anyURI"` — typed literals. That matches neither the schema.org JSON-LD
MIDAS actually serves (plain literals) nor LinkML's own native RDF output (IRI nodes).
This script applies the allow-listed corrections: DCAT predicates whose range is a real
resource become IRI nodes; schema.org URL-shaped datatypes lose the coercion and stay
literals.

Publishing the raw generator output would therefore ship a context that contradicts the
live one. The private pipeline treats this step as mandatory, and so does
`tools/build.sh`.

The script fails rather than silently doing nothing if the generated context stops
matching its expectations (a renamed slot, a changed `slot_uri`, a LinkML behaviour
change), so a divergence breaks the release build instead of reaching the public site.

**Maintenance:** because this is a copy, a change to the canonical script must be copied
over too. The `diff` above belongs in the release checklist. If that coupling ever
becomes a problem, the alternative is to stop publishing the context from this repo and
publish the canonical pipeline's output instead — but not to run the generator without
the transform.

## Verifying a build against the canonical pipeline

A dry run on this repo should reproduce the artifacts the private pipeline produces from
the same yaml. Two of the three compare byte-for-byte; one does not, for a reason worth
knowing before you go hunting:

```bash
P=../midas-contact-db/src/main/resources/linkml

diff generated/midas-catalog.schema.json     $P/generated/midas-catalog.schema.json
diff generated/midas-catalog.context.jsonld  $P/runtime/midas-catalog.context.jsonld
#   → expect ONE hunk: the embedded generation_date. Anything else is a real divergence.
```

**Do not byte-diff the OWL.** rdflib's Turtle serializer does not order anonymous
restriction blank nodes stably, so two runs over the same model differ textually while
asserting the same triples. Compare the graphs instead:

```bash
python -c "
from rdflib import Graph
from rdflib.compare import to_isomorphic
a = Graph().parse('generated/midas-catalog.owl.ttl')
b = Graph().parse('$P/generated/midas-catalog.owl.ttl')
print(len(a), len(b), to_isomorphic(a) == to_isomorphic(b))
"
```

Verified on 2026-09-15 against the `1.0.0-SNAPSHOT` seed: JSON Schema identical, context
identical but for the timestamp, OWL isomorphic at 2054 triples.
