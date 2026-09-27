# openapi-schema-monzo

An OpenAPI 3.1 description of the [Monzo Developer
API](https://docs.monzo.com), and a conformance suite that checks Monzo against
it.

Monzo publishes prose. `monzo_api.yaml` is that prose turned into something
machine-readable: all 21 operations the reference documents, the schemas its
examples and property tables describe, and the `transaction.created` webhook.
Nothing is invented — a field the reference does not mention is not described,
and no object forbids properties it does not name, because the reference says
outright that transactions carry more than it documents.

It already disagrees with the reference in one place, and says so where it
does: an invalid access token answers `400 bad_request.invalid_token`, not the
`401` the reference describes.

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
MONZO_TOKEN=...                              # reads only
MONZO_TOKEN=... MONZO_MUTATE=1               # and writes it can undo
MONZO_TOKEN=... MONZO_MUTATE=1 MONZO_MONEY=1 # and the two pot operations
bundle exec rspec
```

A token from the [API playground](https://developers.monzo.com) is enough.

Read-only by default, in two steps, because Monzo answers `200` to a create
just as it does to a read and nothing in the document tells them apart:

* every method other than `GET` waits for `MONZO_MUTATE=1`, and everything the
  suite creates it takes back — the receipt it writes it deletes, the
  attachment it registers it deregisters, the webhook it registers it deletes,
  and a failed cleanup fails the run;
* the two pot operations move real money, so they wait for `MONZO_MONEY=1` as
  well. They move one penny, and the pair of them puts it back.

Ids are neither hand-written nor guessed. `spec/fixtures.yml` asks for
`$account_id`, `$pot_id`, `$transaction_id` and the rest, and the suite
discovers them from the account the token belongs to — `/accounts` for an
account, `/pots` for a pot, `/transactions` for a transaction, `/webhooks` for
a webhook. An operation whose discovery comes back empty skips with the reason;
a 404 that passes because 404 is documented proves nothing. Override any of it
with a literal in the same file.

`bundle exec rake` lints the document and runs the suite; `rake generate`
regenerates `spec/api`. CI does the same on GitHub Actions, GitLab and Travis,
and checks that `spec/api` is what the document generates. Set `MONZO_TOKEN` as
a secret to have CI actually talk to Monzo.

## The gem

`monzo.gemspec` packages the document, for anything that wants to read it
rather than eyeball it:

```ruby
YAML.safe_load_file(Monzo::SCHEMA)
```

## Not covered

Monzo's [Open Banking API](https://docs.monzo.com/open-banking) is a separate
document on a separate host, and is not described here.

## Licence

LGPL-2.1-or-later, for the description and the suite. The API it describes is
Monzo's.
