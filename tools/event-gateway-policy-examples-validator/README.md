# event-gateway-policy-examples-validator

Validates Event Gateway policy example YAML files against the schemas in the API spec.

## How it works

1. Reads the frontmatter of every `app/_event_gateway_policies/*/index.md`, which declares:

   ```yaml
   schema:
     api: konnect/event-gateway
     path: /schemas/EventGatewayACLsPolicy
   ```

1. Resolves `schema.api` to `api-specs/<api>/<highest version directory>/openapi.yaml`, and
   `schema.path` to a pointer under that spec's `components`.
1. Parses that spec with
   [`@apidevtools/json-schema-ref-parser`](https://github.com/APIDevTools/json-schema-ref-parser),
   which reads the YAML and inlines every `$ref`. The spec has no circular references, so the
   result is a plain schema that Ajv compiles directly, with nothing left to resolve.
1. Globs all example files matching `app/_event_gateway_policies/*/examples/*.{yaml,yml}`.
1. For each example file:
   - Keeps only the keys that describe the policy: `name`, `type`, `condition`, `config`.
     Everything else (`title`, `weight`, `requirements`, `variables`, `tools`, `min_version`,
     `parent_policy_id`) is documentation metadata with no counterpart in the spec.
   - Replaces `${...}` template variables with schema-appropriate placeholder values.
   - Validates the result against the whole policy schema using [Ajv](https://ajv.js.org/).

Validating the whole policy object rather than just `config` means the `type` enum is checked
too, which catches an example placed under the wrong policy directory.

## How to run it

From the tool directory:

```bash
cd tools/event-gateway-policy-examples-validator
npm ci
node index.js
```

To validate against a different spec than the one `schema.api` resolves to — an unreleased
spec, or a local edit of one — pass its path. It applies to every policy:

```bash
node index.js --spec ~/some-branch/api-specs/konnect/event-gateway/v1/openapi.yaml
```

This accepts an upstream source spec as well as a published one — see
[Flattened and unflattened specs](#flattened-and-unflattened-specs).

CI runs it from `.github/workflows/validate-event-gateway-policy-examples.yml`, path-filtered
on the policy examples, the policy `index.md` files, and the Event Gateway API spec.

## Caveats

### Missing schemas are a failure

A `schema.path` that does not resolve fails the run. There is no allowlist: a policy documented
before its schema lands in `api-specs` breaks CI until the spec catches up, exactly as a typo in
`schema.path` does.

A policy whose frontmatter has no `schema.api` and `schema.path` fails for the same reason: there
is nothing to validate its examples against.

Either way the failure is reported once, against the policy's `index.md`. Its examples are not
also counted as skipped, which would report one problem twice.

Use `--spec` to check such a policy against a spec that does carry its schema.

### Injected `additionalProperties: false`

The spec omits `additionalProperties` on nearly every object, so Ajv would accept a misspelled
config key silently. That is the failure most likely in a hand-written docs example, so the
validator closes every object schema that does not already say what it accepts and does not
compose with another schema through `oneOf`/`anyOf`/`allOf`. (`$ref` needs no mention: none
survive dereferencing.)

A schema used as a member of an `allOf` is left open. Its sibling members carry the rest of the
object's properties, so closing it would make every member reject the others' keys and nothing
could validate. Finding those members takes its own pass over the spec, because a named schema
such as `BaseEventGatewayPolicy` is reached from `components.schemas` before anything reveals
that an `allOf` composes it. `oneOf`/`anyOf` branches are whole alternatives to each other, so
those are closed as normal.

As of writing this flags nothing in either spec shape below. If a genuinely open-ended map is
added to the spec, declare its `additionalProperties` there rather than loosening this rule.

### Template variable replacement

Example files use `${VARIABLE}` placeholders for environment-specific values. The validator
substitutes a value taken, in order, from: the enclosing object schema's `example`, the field's
own `example`, its `default`, its first `enum` value, a per-`format` placeholder, then a per-type
fallback.

The enclosing-object `example` matters: a patterned string field such as an AWS KMS ARN usually
has no example of its own, and a generic placeholder would fail its own `pattern`.

### Polymorphic fields

Variable substitution walks the example and the schema together, but a `oneOf`/`anyOf` node has
no `properties` or `items` of its own to walk into. Without picking a branch, every `${...}`
under a polymorphic field collapses to a generic placeholder, which then fails that branch's own
`pattern` or `format` — a false failure. So the validator picks a branch, in this order:

1. **By JSON type.** Branches that cannot hold a value of this type are discarded. If one
   survives, it wins. This resolves a field that is either a literal array or an expression
   string, such as an ACL rule's `resource_names`.
1. **By `discriminator`.** For an object, the `mapping` entry for the value's tag property, as
   `EncryptionKey` maps `type: aws` to `EncryptionKeyAWS`.
1. **By key count.** For an object with no discriminator, the branch declaring the most of the
   value's keys. The reference-by-ID-or-name schemas (`VirtualClusterReference`,
   `SchemaRegistryReference`, `EncryptionKeyStaticReference`) need this: their branches share no
   tag property, so a discriminator is impossible, and they are told apart by whether `id` or
   `name` is present.

Branch selection only affects substitution. Ajv still validates the value against the whole
`oneOf`/`anyOf`, so a wrong guess here cannot make an invalid example pass.

Note that `discriminator.mapping` values are plain pointer strings rather than `$ref` keywords,
so dereferencing the spec leaves them alone. They are resolved through the parser's `$refs.get`.

### Null value stripping

Nulls are stripped from the policy object unless the schema allows them, via `type: "null"`, a
type array containing `"null"`, or OpenAPI 3.0's `nullable: true`, which Ajv does not understand.

### Not checked

- **`condition` expressions.** The spec types `condition` as a plain string and lists the legal
  field names in an `x-expression` extension. Checking the expression body means parsing the
  expression grammar, so `condition` is validated only as the string the spec says it is.
- **`x-min-runtime-version`.** Some schema fields are only available from a given Event Gateway
  runtime version. Nothing verifies that an example using such a field declares a high enough
  `min_version`.
