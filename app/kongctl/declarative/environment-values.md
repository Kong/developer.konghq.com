---
title: "Environment values and saved plans with kongctl"
description: "Choose deferred or stored values, types, and saved-plan behavior."
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Declarative configuration overview
    url: /kongctl/declarative/
  - text: Supported resources
    url: /kongctl/supported-resources/
---

Read this page when choosing deferred versus stored `!env`, extracting
structured values, or fixing values in a reviewed plan. Use [write-only
secrets](/kongctl/declarative/secrets/) for sensitive write-only fields.

## Loading values from environment variables

Use `!env` to load a value from an environment variable into a string field:

```yaml
portals:
  - ref: env-portal
    name: env-portal
    description: !env PORTAL_DESCRIPTION
```

Scalar syntax supports extraction with `#`:

```yaml
api_documents:
  - ref: env-doc
    api: petstore-api
    title: !env DOC_METADATA#title
    content: !env DOC_METADATA#content
    slug: getting-started
```

Map syntax is also supported:

```yaml
api_documents:
  - ref: env-doc
    api: petstore-api
    title: !env
      var: DOC_METADATA
      extract: title
    content: !env
      var: DOC_METADATA
      extract: content
    slug: getting-started
```

`!env` extraction parses the environment variable as YAML or JSON before reading
the requested field path.

A runnable example is available in
[docs/examples/declarative/env/][docs-examples-declarative-env].

### !env behavior

- Deferred `!env` supports string-typed fields only.
- Unset environment variables are treated as errors.
- Empty-but-set environment variables are allowed except for namespaces.
- During planning, `kongctl` resolves the current environment value to calculate
  changes.
- Saved plan files preserve the deferred `!env` reference instead of the
  resolved plaintext value.
- Namespace `!env` values resolve during loading and remain fixed in saved plans
  as ownership metadata, including when `store: false` is used.
- Another exception is `!env` nested inside `!lookup` or `!external`: it is a
  planner-only selector input, so the saved plan retains the resolved resource
  ID and does not defer that environment value to execution.
- During execution, `kongctl` performs a fresh environment lookup for each
  deferred `!env` value instead of reusing the value observed during planning.
- When you run `apply`, `sync`, or `delete` directly from configuration files,
  `kongctl` still plans first and then performs that second lookup during
  execution in the same command invocation.
- In direct `apply`, `sync`, and `delete` runs, both lookups happen within the
  same `kongctl` process, so they will usually observe the same process
  environment.
- When execution uses a saved plan with `--plan`, planning and execution happen
  in separate command invocations, so environment values may differ between them
  and the executed value may differ from what was observed while planning.
- Human-readable plan and diff output redact deferred `!env` values and the
  corresponding current values returned by {{site.konnect_short_name}}. Saved plans also redact
  those current values while retaining the desired deferred references.

Diffs, execution reports, and operation/HTTP logs also redact nested fields with
sensitive names, including password, secret, credential, token, API-key, and
private-key patterns. This applies to literal and stored values as well as
deferred values. Diff redaction applies to text, JSON, YAML, and
`--full-content` output. It does not classify these fields as write-only or
change when their values are sent to {{site.konnect_short_name}}.

Executable `kongctl plan` output can retain literal and stored values needed by
`apply --plan`. Use deferred `!env` to avoid storing those values in a plan.
Redacted diff output is for review; generate execution artifacts with
`kongctl plan`.

## Storing typed environment values in plans

Use `store: true` when a saved plan should retain the environment value approved
during planning. Values are read during configuration loading, before decoding
resource fields. Execution uses the stored values even when the environment has
changed or the variables are absent.

**Stored values are plaintext in plan artifacts and may appear in plan and diff
output.** Use this for non-sensitive configuration. No separate secret store is
involved.

`store` is a boolean and defaults to `false`. These are alternative declarations
of the same field:

```yaml
description: !env {var: DESCRIPTION, store: true}
```

```yaml
description: !env
  var: DESCRIPTION
  store: true
```

Stored values support structured extraction using the mapping form:

```yaml
description: !env
  var: METADATA
  extract: description
  store: true
  type: string
```

The loader infers the type from an unambiguous resource/SDK field, including
typed map values and array elements. Unknown destinations such as arbitrary
policy configuration, and conflicting union branches, require an explicit
`type`. Errors identify the field and variable. Custom decoding layouts that
cannot be inferred also require `type`; inference does not duplicate policy
schemas or select an arbitrary union branch.

{% table %}
columns:
  - title: Type
    key: type
  - title: Conversion
    key: conversion
rows:
  - type: "`string`"
    conversion: Preserve raw environment text, including whitespace and quotes
  - type: "`boolean`"
    conversion: "Parse a YAML boolean (`true` or `false`, also title/upper case)"
  - type: "`integer`"
    conversion: Parse a whole number; fractional values are errors
  - type: "`number`"
    conversion: Parse a finite decimal number, including exponent notation
  - type: "`null`"
    conversion: Parse a YAML null value
  - type: "`array`"
    conversion: Parse a YAML/JSON sequence with typed nested values
  - type: "`object`"
    conversion: Parse a YAML/JSON mapping with string keys and typed values
{% endtable %}

Quote the enum name in `type: "null"`; an unquoted YAML null is not a string
option. An explicit type must match a known destination; `integer` is also
accepted for a numeric destination, and `null` for nullable destinations. The
normal SDK and resource validation still applies.

For a string destination, an environment value of `42`, `true`, or `null`
remains text. For an unknown destination, specify `type: string` to preserve
that text. Inside parsed objects and arrays, quote strings that resemble
numbers, booleans, or null.

For example, an {{site.ai_gateway}} rate-limiting policy's dynamic `config` can
use:

```yaml
config:
  redis:
    ssl: !env {store: true, var: REDIS_SSL, type: boolean}
    ssl_verify: !env {var: REDIS_SSL_VERIFY, store: true, type: boolean}
  sync_rate: !env {store: true, var: SYNC_RATE, type: number}
```

Set `REDIS_SSL=true`, `REDIS_SSL_VERIFY=false`, and `SYNC_RATE=0.5`. A known
boolean field, such as a portal's `auto_approve_developers`, can instead use
`!env {var: AUTO_APPROVE, store: true}` without a type option.

Extraction parses the source as YAML/JSON before selecting an existing
dot-separated mapping path. The selected value may be any supported type and
must match the inferred or explicit type; extraction does not convert to strings
booleans, numbers, null, arrays, or objects. Array-index extraction is not
supported. Missing paths and traversal through scalar/null values fail.

### Parsing and serialization boundaries

- Unset variables always fail. Empty text is valid only for a direct `string`;
  structured parsing and extraction reject empty/whitespace-only input. YAML
  null spellings include `null`, `Null`, `NULL`, and `~`.
- Structured input must be one YAML/JSON document. YAML 1.2 boolean semantics
  apply: `yes`, `no`, `on`, and `off` are strings.
- Numbers use JSON decimal syntax. Hexadecimal, octal spellings with leading
  zeros, underscores, leading plus signs, NaN, and infinity are rejected.
- Numbers are limited to ±9,007,199,254,740,991 (±(2^53−1)). Integers within
  this range survive JSON plan round trips exactly. Fractional numbers use
  binary64 rounding; underflow to zero or loss of an entire fractional part is
  rejected. Normal SDK decoding enforces narrower integer destinations.
- Objects require unique string keys. Anchors, aliases, merge keys, custom tags,
  timestamps, binary values, and other non-JSON YAML types are rejected. Quote
  dates to represent them as strings.
- Nested arrays, objects, and null retain their JSON meanings. Resource rules
  still determine whether a field accepts null or an empty collection.
- Strings beginning with reserved internal prefixes `__ENV__:`, `__SECRET__:`,
  `__REF__:`, or `__EXTERNAL__:` are rejected, including inside structured
  values, so execution cannot reinterpret stored data as deferred references.

### Compatibility and saved plans

Ordinary `!env VAR` and `!env {var: VAR, store: false}` retain their
string-only, deferred behavior: read during planning and again at execution.
Existing saved plans and deferred-value redaction are unchanged. `type` is only
valid with stored values; unknown options are errors.

Stored tags cannot be nested inside `!secret`, `!lookup`, or `!external`, and
cannot contain other custom tags. Existing deferred nesting remains supported.
Stored tags cannot supply resource `ref`. Namespace values resolve during
loading with either stored or deferred syntax. Write-only fields continue to
require their existing deferred secret sources or supported vault references;
`!secret` is unchanged.

For a manifest with the stored `DESCRIPTION` value:

```bash
DESCRIPTION="Approved description" kongctl plan --mode apply -f config.yaml > plan.json
DESCRIPTION="Changed description" kongctl apply --plan plan.json --auto-approve
# Alternatively, execute without the original variable:
env -u DESCRIPTION kongctl apply --plan plan.json --auto-approve
```

The two apply commands are alternatives. Both use `Approved description` from
the plan. Re-plan from the manifest to approve a different value.

[docs-examples-declarative-env]:
https://github.com/Kong/kongctl/blob/main/docs/examples/declarative/env
