# openapi-schema-monzo

An OpenAPI 3.1 description of the [Monzo Developer
API](https://docs.monzo.com), and a conformance suite that checks Monzo against
it.

Monzo publishes prose. `monzo_api.yaml` is that prose turned into something
machine-readable: every endpoint the reference documents, with the schemas its
examples and its property tables describe. Nothing is invented — a field the
reference does not mention is not described, and no object forbids properties
it does not name, because the reference says outright that transactions carry
more than it documents.

## The suite

`spec/api` is generated from the document, one example per operation:

```shell
nix develop
bin/generate-specs
```

The examples say only *which* operations exist. `spec/spec_helper.rb` says what
conforming means: it reads the same document at runtime and validates each
response against the schema in it, so the document is the assertion and no
expectation is written twice.

```shell
MONZO_TOKEN=... bundle exec rspec
```

A token from the [API playground](https://developers.monzo.com) is enough.

Read-only by default: every method other than `GET` is skipped unless
`MONZO_MUTATE=1`. Monzo answers `200` to a create just as it does to a read, so
nothing in the document distinguishes them, and the obvious way to test
"deposit into a pot" is to move real money on every run.

Path parameters and required query arguments come from `spec/fixtures.yml`,
which ships empty — the suite talks to a real account, and only you know which
pot is safe to touch. An operation with no fixture skips rather than guessing.

## Not covered

Monzo's [Open Banking API](https://docs.monzo.com/open-banking) is a separate
document on a separate host, and is not described here.

## Licence

LGPL-2.1-or-later, for the description and the suite. The API it describes is
Monzo's.
