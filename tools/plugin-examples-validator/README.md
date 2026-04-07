# plugin-examples-validator

Validates plugin example YAML files against their corresponding JSON schemas.

## How it works

1. Finds the latest schema version directory under `app/_schemas/gateway/plugins/`.
1. Builds a lookup map of all plugin JSON schemas in that directory.
1. Globs all example files matching `app/_kong_plugins/*/examples/*.yaml`.
1. For each example file that contains a `config` block:
   - Matches the plugin slug (from the file path) to its JSON schema.
   - Replaces `${...}` template variables with schema-appropriate placeholder values (using `default`, first `enum` value, or a safe value per type).
   - Validates the config against the schema's `properties.config` sub-schema using [Ajv](https://ajv.js.org/).

## Caveats

### Null value stripping

The plugin JSON schemas are generated from Kong Gateway's Lua schemas and some **do not include `null` as an allowed type** for fields that accept it. Many example YAML files use `null` to explicitly unset optional fields, which would cause spurious validation failures.

To work around this, the validator **strips `null` values** from config objects before validation, unless the JSON schema for that specific field explicitly allows `null` (via `"type": "null"` or a type array that includes `"null"`).

This means the validator will not catch cases where `null` is incorrectly used for a field that truly shouldn't be null. If the JSON schemas are updated in the future to accurately represent nullable fields, this workaround should be removed.

### Template variable replacement

Example files use `${VARIABLE}` placeholders for values that are environment-specific. The validator replaces these with schema-appropriate defaults before validation so they don't cause type-mismatch errors.

## How to run it

From the tool directory:

```bash
cd tools/plugin-examples-validator
npm ci
node index.js
```
