---
title: "References and external resource lookups with kongctl"
description: "Link declarations and look up existing resources, including scoped parents."
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

Read this page when linking declarations, selecting existing {{site.konnect_short_name}} objects, or
composing scoped lookups.

## External resources

External resources are {{site.konnect_short_name}} objects managed elsewhere but selected by the
`kongctl` declarative engine for use by managed resources. Use `_external` when
the object needs a reusable declarative `ref` or managed children. Use the
`!lookup` tag to resolve an existing object directly in a relationship field.
`!external` is an exact alias for `!lookup`.

```yaml
# External portal definition - this tells kongctl that this portal
# is managed externally (by the platform team) but we need to reference it
portals:
  - ref: shared-developer-portal
    _external:
      selector:
        matchFields:
          name: "Shared Developer Portal"
```

Catalog APIs and application auth strategies can also be declared external. An
external API may contain managed versions, publications, implementations, and
documents:

```yaml
apis:
  - ref: shared-api
    _external:
      selector:
        matchFields:
          name: Shared API
    versions:
      - ref: shared-api-v2
        version: v2
        spec: !file ./openapi.yaml
```

The API itself remains outside kongctl management. The declared version is
managed beneath the resolved API ID.

Because kongctl does not own those resources:

- External resources **cannot** declare `kongctl` metadata. Supplying
  `kongctl.namespace` or `kongctl.protected` on an external resource results in
  a parsing error. File-level defaults are ignored for externals.
- External references do **not** add their namespaces to sync planning.
  Namespace-bearing managed resources and explicit defaults determine namespace
  scope; child collections have resource-specific ownership rules.
- Child resources (portal pages, API versions, publications, implementations,
  documents, etc.) are still planned by resolving the external parent's {{site.konnect_short_name}}
  ID. You do not need to (and cannot) assign a namespace to the external
  definition itself.
- An external parent is not changed or deleted, but its child collections
  explicitly included in sync scope are fully reconciled, including stale child
  deletion. Child collections omitted from the configuration remain out of scope
  and are not pruned.

See [ownership and namespace rules](/kongctl/declarative/ownership/) for independently
owned children and the [sync scope guide](/kongctl/declarative/sync/) for
omitted versus empty collections.

Inline lookups use either a `field:value` scalar or a mapping. The target type
is inferred from the relationship field:

```yaml
apis:
  - ref: products
    name: Products
    publications:
      - ref: products-publication
        portal_id: !lookup {name: Shared Developer Portal}

ai_gateway_model_providers:
  - ref: shared-provider
    ai_gateway: !lookup {name: shared-ai-gateway}
    name: openai
    type: openai
    display_name: OpenAI
    config: {}
```

`!lookup` and `!external` are exact aliases. A mapping can contain multiple
selectors, all of which must match. `id:<uuid>` and `{id: <uuid>}` bind a known
ID directly and cannot be combined with other selectors. Selector lookups must
match exactly one resource.

Some relationship fields, such as `portal_id`, are fields from the {{site.konnect_short_name}} API
schema. Others, such as `ai_gateway`, are parent selectors added by kongctl for
root-level child declarations. Their names remain different for compatibility,
but both accept literal IDs, `!ref`, `!external`, and `!lookup` where supported.
When a child is nested under its parent, the kongctl parent selector is omitted
and inferred from the nesting.

Lookups run during planning with the active {{site.konnect_short_name}} profile. Equivalent lookups,
including `_external` declarations, are cached for that plan. Saved plans
contain resolved IDs rather than tag placeholders.

## References and lookups in payload values

Explicit `!ref` tags also work in payload fields, arbitrary map values, and list
elements, including SDK-backed configuration structures. Map keys are never
interpreted as references. Keys containing dots, slashes, or numbers retain
their meaning.

```yaml
ai_gateways:
  - ref: telemetry-gateway
    name: telemetry-gateway
    display_name: Telemetry Gateway
    deployment_type: hybrid
    policies:
      - ref: observability
        name: observability
        display_name: Observability
        type: opentelemetry
        enabled: true
        global: true
        config:
          headers:
            X-Control-Plane-Id: !ref telemetry-gateway
            X-Gateway-Name: !ref telemetry-gateway#name
            X-Shared-Gateway-Id: !lookup
              resource_type: ai_gateway
              name: shared-gateway
```

`!ref target` and `!ref target#id` both select the {{site.konnect_short_name}} ID. Existing IDs
resolve during planning. New resources are created before operations that need
their IDs, including a policy referencing its own parent. Other selectors
address scalar fields present in the declaration, using JSON field names and
dot-separated nested selectors. For example, `#display_name` selects the
declared display name. Configuration-known selectors do not require a creation
dependency. Boolean and numeric values retain their types in arbitrary value
slots; incompatible string destinations are rejected. Unavailable selectors,
missing or ambiguous declarations, and dependency cycles fail with resource
context. Write-only secrets cannot be selected.

An arbitrary destination does not imply a lookup resource type. Supply the
canonical singular `resource_type` in a lookup mapping, as above. For scoped
lookups, also supply `parent_ref` naming a declaration with an existing {{site.konnect_short_name}}
ID. For example:

```yaml
service_id: !lookup
  resource_type: gateway_service
  parent_ref: shared-control-plane
  name: shared-service
```

To look up both a remote parent and its child without declaring either, use a
nested `parent` lookup:

```yaml
service_id: !lookup
  resource_type: gateway_service
  name: billing
  parent: !lookup
    resource_type: control_plane
    name: production
```

The parent resolves first, then its ID scopes the child lookup. Both lookups
must match exactly one resource. Supply `resource_type` at each level; the
parent type must match the child's required scope. Use either `parent` or
`parent_ref`, never both. Nested parents also accept the `!external` alias and
`!env` selector values. Neither remote object becomes managed by kongctl.

The normal lookup capability, selector, uniqueness, and scope rules apply.
`!external` accepts the same syntax. Lookups locate existing resources during
planning; they do not wait for a new parent to be created. For new resources,
use `!ref`. Relationship fields retain their existing type inference and parent
scope rules.

References replace whole values; string interpolation and references in map keys
are unsupported. `!env` values retain deferred evaluation when copied through a
configuration-known reference. Ordinary strings, including strings that resemble
internal reference encodings, remain literal. Unresolved tag expressions are
rejected before a mutation request is sent.

Saved plans retain deferred ID bindings and dependencies. New plans use format
1.1, which requires a matching or newer executor; this version also accepts
format 1.0 plans. Direct apply and saved-plan apply use the same resolution
path. Planning again compares resolved values to avoid repeated
reference-induced updates.

## Nested YAML tags

Nested tags are supported only for combinations whose resolution order and
security behavior are defined explicitly. `!env` may be used as a direct mapping
selector value inside `!lookup` or `!external`:

```yaml
# Block mapping syntax
portal_id: !lookup
  name: !env PORTAL_NAME

# Compact flow syntax
control_plane: !lookup {name: !env CONTROL_PLANE_NAME}
```

Both scalar and map forms of the nested `!env` tag are supported. Multiple
lookup selectors may use `!env`, subject to the selectors supported by the
target resource. The existing rule that `id` cannot be combined with other
selectors still applies.

The current nested-tag support matrix is:

| Outer tag | Inner tag | Status |
|---|---|---|
| `!lookup` / `!external` | `!env` | Direct mapping values only |
| `!secret` | `!env`, `!file` | Direct `source` value or `parts` element |
| `!lookup` / `!external` | Lookup tags | Only as an explicit `parent` lookup |
| `!lookup` / `!external` | `!file`, `!ref` | Unsupported |
| `!env`, `!file`, `!ref` | Any custom tag | Unsupported |

The scalar `field:value` lookup form cannot contain a nested YAML tag; use a
mapping form instead. Tags are rejected in mapping keys and control fields such
as `var`, `extract`, or `path`. Nested lookup tags are supported only through
the explicit `parent` form described in [payload
lookups](#references-and-lookups-in-payload-values).

Nested `!file` values are supported only as deferred sources inside `!secret`.
They are not supported inside lookup tags. Nested `!ref` values are not enabled
because references resolve after resources load, while remote lookups must
resolve during planning. A tag contained in data loaded by `!file` continues to
be treated as file content and is not processed recursively.

For a supported nested `!env`, the environment value is read before the planner
performs the remote lookup. Diagnostics redact that selector value. After a
match is found, only the resolved resource ID is written to the plan. Saved-plan
execution does not read the environment variable again or repeat the lookup,
even if the environment later changes.
