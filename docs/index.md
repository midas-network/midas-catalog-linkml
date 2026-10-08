# MIDAS Catalog LinkML Model

This is the formal data model behind the [MIDAS Catalog](https://catalog.midasnetwork.us/), written in
[LinkML](https://linkml.io/). It describes what a catalog record contains: its classes and fields, what
values each field can hold, and which established vocabulary each term comes from.

Everything on this site is generated from one file, `src/midas-catalog.yaml`, at each release. Most of the
site is the [Schema Reference](reference/index.md), with one page per class, field (slot) and type. The model's
version number is shown in the reference.

## How this relates to the catalog's JSON-LD

The MIDAS Catalog publishes every record in two forms, and both describe the same records:

- **The schema.org JSON-LD** is the main, public form. It's embedded in every catalog page, and it's what
  search engines and FAIR assessment tools read. If you want to use catalog records, start there.
- **The LinkML form**, built from this model, follows the model exactly. It's for people who want to
  validate records against the model, generate code from it, or build on it.

Neither is generated from the other, and neither replaces the other. For more background, see
[LinkML for MIDAS Catalog](https://midasnetwork.us/linkml-for-midas-catalog/).

## Why LinkML

- **The rules are written down.** Without a model, the structure of a record lives only in the code that
  produces it. Here it's a specification you can read, compare between versions, and cite.
- **Everything comes from one source.** The JSON Schema, OWL ontology, JSON-LD context and these reference
  pages are all generated from the same file, so they can't disagree with each other.
- **It's a shared language.** LinkML is used across OBO, Biolink and a range of NIH data-standard efforts,
  so this model can line up with others instead of standing alone.

## How to use it

**Read the model.** Start at the [Schema Reference](reference/index.md). `CreativeWork` is the shared base
that every MIDAS resource type builds on, and `Thing` holds the identity and naming fields every node has.

**Import it.** The model's permanent identifier is `https://w3id.org/midas-catalog/schema`.

**Use the generated files.** Each is regenerated from the model at every release:

| File | What it's for |
| --- | --- |
| [`midas-catalog.yaml`](generated/midas-catalog.yaml) | The model itself: import it, or generate your own code from it |
| [`midas-catalog.schema.json`](generated/midas-catalog.schema.json) | JSON Schema: check that a record follows the model |
| [`midas-catalog.context.jsonld`](generated/midas-catalog.context.jsonld) | JSON-LD context: turns plain field names into linked data |
| [`midas-catalog.owl.ttl`](generated/midas-catalog.owl.ttl) | OWL/RDF: load into a triplestore or an ontology tool |

**Generate code.** With [LinkML installed](https://linkml.io/linkml/intro/install.html), its
[generators](https://linkml.io/linkml/generators/) (`gen-pydantic`, `gen-java`, `gen-typescript`) create classes
from the model, so your code can build and read catalog-shaped records
as objects instead of hand-written dictionaries.

## A note on controlled vocabularies

**The model checks where a term comes from, not which term it is.** For fields that take a
controlled-vocabulary value, the model requires the term's identifier to come from an approved source for
that field (OBO ontologies, GeoNames, schema.org, the MIDAS vocabulary and so on): it checks that the
identifier starts with that source's web address. The model doesn't list the individual terms.

That's deliberate. A list of allowed terms (an *enumeration*) would accept only the terms in use today, and
would reject a perfectly good new term from the same approved source until the model was re-released.
Checking the source instead keeps the model open: a new term from an approved ontology validates with no
change to the model.

So this model has **no enumerations**, and the Enumerations section of the
[Schema Reference](reference/index.md) is intentionally empty. It also has no subsets.

## More

- Background: [LinkML for MIDAS Catalog](https://midasnetwork.us/linkml-for-midas-catalog/)
- LinkML: [linkml.io](https://linkml.io/) · [generator documentation](https://linkml.io/linkml/generators/)
- The MIDAS network: [midasnetwork.us](https://midasnetwork.us/)
- The MIDAS Catalog: [catalog.midasnetwork.us](https://catalog.midasnetwork.us/)