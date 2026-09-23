# MIDAS Catalog LinkML Model

A formal, machine-readable model of a MIDAS Coordination Center catalog record — its
classes, slots, ranges, cardinalities and the vocabulary IRIs each term maps to —
published as [LinkML](https://linkml.io/) with generated reference documentation.

This site is generated from a single source file, `src/midas-catalog.yaml`, at each
tagged release. The [Schema Reference](reference/index.md) is the bulk of it: one page
per class, slot and type.

## Two representations of the same catalog

MIDAS publishes its catalog metadata in two renderings. They describe the same records
and agree on content; they differ in serialization and audience.

**schema.org JSON-LD** is the consumer-facing published record — embedded in landing
pages, harvested by search engines, scored by FAIR tooling. It is the authoritative
public artifact, and it is deliberately the richer serialization: nodes carry dual
types (a place is both `schema:Place` and `geonames:Feature`), every nested node is
explicitly typed, and the whole record is an IRI-linked graph.

**This LinkML model** is the formal model layer alongside it. Its value is not richness
of serialization but formality: it states the structure once, in a form that tools can
read. LinkML expresses a single `class_uri` per class and emits `@type` at the top
level only, so it does not — and is not meant to — reproduce the schema.org rendering.

Neither is generated from the other, and neither replaces the other. If you are
consuming MIDAS catalog records, you want the schema.org JSON-LD. If you are working
with the model *as a model*, you want this.

## Why LinkML

- **The model becomes inspectable.** Structure that would otherwise be implicit in the
  catalog's emitter code is a first-class specification you can read, diff and cite.
- **Artifacts come from one source.** The JSON Schema, OWL, JSON-LD context and these
  reference pages are all generated from the same YAML, so they cannot disagree with it.
- **It is a shared language.** LinkML is the modeling language used across OBO, Biolink
  and a range of NIH data-standard efforts, which makes this model alignable rather than
  bespoke.

## How to use it

**Read the model.** Start at the [Schema Reference](reference/index.md) — `CreativeWork`
is the shared base every MIDAS resource type inherits, and `Thing` carries the identity
and naming slots common to every node.

**Import it.** The schema is published at its permanent identifier,
`https://w3id.org/midas-catalog/schema`.

**Build against the generated artifacts** (each regenerated at release from the model on
this page):

| Artifact | Use |
| --- | --- |
| [`midas-catalog.yaml`](generated/midas-catalog.yaml) | The model itself — import it, or generate your own clients from it |
| [`midas-catalog.schema.json`](generated/midas-catalog.schema.json) | JSON Schema — validate MIDAS-shaped data at an integration boundary |
| [`midas-catalog.context.jsonld`](generated/midas-catalog.context.jsonld) | JSON-LD context — project plain slot-keyed data to linked data |
| [`midas-catalog.owl.ttl`](generated/midas-catalog.owl.ttl) | OWL/RDF — load into a triplestore or ontology tool |

**Generate typed clients.** With the [LinkML toolchain](https://linkml.io/linkml/)
installed, `gen-pydantic`, `gen-java` and `gen-typescript` produce typed classes from
the YAML, so downstream code constructs MIDAS-shaped records as objects rather than
hand-written dictionaries.

## A note on controlled vocabularies

**The model constrains where a term comes from, not which term it is.** Where a slot carries
a controlled-vocabulary value, the model requires the term's identifier to originate from an
**approved ontology** for that field — OBO, GeoNames, schema.org, the MIDAS vocabulary, and so
on, depending on the axis — expressed as a per-slot `pattern` on the namespace. It does **not**
enumerate the specific terms.

This is deliberate. Constraining the *source* rather than the *set of values* keeps the model
open: a term newly drawn from an already-approved ontology validates with no change to the
model, so the model need not be re-released each time a legitimate new term comes into use. An
`enumeration` would do the opposite — pin validation to the exact terms in use today and reject
everything else, **including terms from the same approved sources that simply haven't been used
yet**. We chose not to tie the model to that fixed list.

As a result, this model defines **no enumerations** — the Enumerations section of the
[Schema Reference](reference/index.md) is intentionally empty — and no subsets. (A secondary
benefit of patterns over enums: an `enumeration` also causes the generated JSON-LD context to
be scoped under `schema:DefinedTerm`, whereas per-slot patterns leave the published context
unchanged.)

## More

- Background and narrative: [LinkML at MIDAS](https://midasnetwork.us/linkml-at-midas/)
- LinkML itself: [linkml.io](https://linkml.io/) ·
  [generator documentation](https://linkml.io/linkml/generators/)
- The MIDAS network: [midasnetwork.us](https://midasnetwork.us/)
- The MIDAS Catalog: [catalog.midasnetwork.us](https://catalog.midasnetwork.us/)
- 
!!! note "Versioning"
    This site is published only from a tagged, frozen release — never from a
    `-SNAPSHOT` model. The version shown in the reference is the version of the model
    these artifacts were generated from.
