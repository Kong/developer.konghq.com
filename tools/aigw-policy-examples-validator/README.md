# aigw-policy-examples-validator

Validates AI Gateway policy example YAML files
(`app/_ai_gateway_policies/*/examples/*.{yaml,yml}`) against the vendored
policy schemas in `app/_schemas/ai-gateway/policies/`.

## How it works

1. Builds a lookup map of every JSON schema in `app/_schemas/ai-gateway/policies/`,
   keyed by the schema basename with dashes stripped, case-insensitive. This
   mirrors how the site resolves a policy schema
   (`Jekyll::Drops::Plugins::AIGWPolicySchema`): the policy folder slug with
   dashes removed, matched against the `*.json` basenames.
1. Globs all example files matching `app/_ai_gateway_policies/*/examples/*.{yaml,yml}`.
1. For each example file:
   - Resolves the schema by the policy folder slug from the file path. A policy
     folder whose schema is missing or cannot be compiled is a finding, not a
     skip.
   - Checks the example's `type` against the policy folder slug.
   - Closes every object schema that declares `properties` without saying what
     else it accepts (`additionalProperties`), so misspelled config keys are
     rejected. Objects that compose through `allOf` stay open, and explicit
     `additionalProperties: true` is honored.
   - Replaces `${...}` template variables with schema-appropriate placeholder
     values (the schema's `example`, `default`, first `enum` value, or a safe
     value per type) and strips `null` values the schema disallows on a field it
     declares. A `null` on a key the schema does not declare survives, so a
     closed config object still rejects the key.
   - Validates the example's `config` against the schema's `properties.config`
     sub-schema using [Ajv](https://ajv.js.org/).

Every finding names the example file and the location of the offending value
inside the config. Any finding exits non-zero.

## How to run it

From the tool directory:

```bash
cd tools/aigw-policy-examples-validator
npm ci
node index.js
```
