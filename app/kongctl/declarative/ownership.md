---
title: "Ownership, namespaces, and protection with kongctl"
description: "Set namespaces, defaults, protection, and ownership guardrails."
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

Read this page when choosing ownership boundaries, setting defaults, or
enforcing namespace guardrails. A profile selects credentials and configuration;
namespaces define ownership and reconciliation boundaries.

The `kongctl` section provides metadata for resource management. Namespace and
protection metadata are supported on namespace-bearing resources. Most parent
resources store this metadata in {{site.konnect_short_name}} labels. Participating
{{site.ai_gateway}} children own their metadata independently, even when nested
under a gateway. Other children follow their parent's lifecycle. Confirm support
for each resource with `kongctl explain`.

To assign ownership to existing resources and save their configuration, see
[Adopt existing resources](/kongctl/declarative/adoption/). Parent adoption
doesn't adopt independently owned children.

## Protected resources

The `protected` field prevents accidental deletion of critical resources:

```yaml
portals:
  - ref: production-portal
    name: "Production Portal"
    kongctl:
      protected: true  # Cannot be deleted until protection is removed
```

## Namespace management

The `namespace` field enables resource isolation:

```yaml
apis:
  - ref: billing-api
    name: "Billing API"
    kongctl:
      namespace: finance-team  # Owned by finance team
      protected: false
```

A namespace must contain 1–63 lowercase alphanumeric characters or hyphens and
must start and end with an alphanumeric character. Consecutive hyphens are
permitted and are preserved exactly.

## File-level defaults

Use `_defaults` to set metadata defaults for namespace-bearing resources in one
file. Explicit resource metadata overrides these defaults:

```yaml
_defaults:
  kongctl:
    namespace: platform-team
    protected: true

portals:
  - ref: api-portal
    name: "API Portal"
    # Inherits namespace: platform-team and protected: true

  - ref: test-portal
    name: "Test Portal"
    kongctl:
      namespace: qa-team
      protected: false
    # Overrides both defaults
```

## Namespace and protected field behavior

`kongctl` provides some default behavior depending on how metadata fields are
specified or omitted. The following tables summarize the behavior.

Namespace values can use `!env` in file defaults or resource metadata. They
resolve before validation and sync scoping, and remain fixed in saved plans. See
[Managing multiple environments](/kongctl/declarative/environments/) for a reusable
example.

### namespace field behavior

{% table %}
columns:
  - title: File default
    key: default
  - title: Resource value
    key: resource
  - title: Final result
    key: result
  - title: Notes
    key: notes
rows:
  - default: Not set
    resource: Not set
    result: '"default"'
    notes: System default
  - default: Not set
    resource: '"team-a"'
    result: '"team-a"'
    notes: Resource explicit
  - default: Not set
    resource: '"" (empty)'
    result: ERROR
    notes: Empty namespace not allowed
  - default: '"team-b"'
    resource: Not set
    result: '"team-b"'
    notes: Inherits default
  - default: '"team-b"'
    resource: '"team-a"'
    result: '"team-a"'
    notes: Resource overrides
  - default: '"team-b"'
    resource: '"" (empty)'
    result: ERROR
    notes: Empty namespace not allowed
  - default: '"" (empty)'
    resource: Any value
    result: ERROR
    notes: Empty default not allowed
{% endtable %}

### protected field behavior

{% table %}
columns:
  - title: File default
    key: default
  - title: Resource value
    key: resource
  - title: Final result
    key: result
  - title: Notes
    key: notes
rows:
  - default: Not set
    resource: Not set
    result: "false"
    notes: System default
  - default: Not set
    resource: "true"
    result: "true"
    notes: Resource explicit
  - default: Not set
    resource: "false"
    result: "false"
    notes: Explicit false
  - default: "true"
    resource: Not set
    result: "true"
    notes: Inherits default
  - default: "true"
    resource: "false"
    result: "false"
    notes: Resource overrides
  - default: "false"
    resource: "true"
    result: "true"
    notes: Resource overrides
{% endtable %}

Portal and API children follow the parent's ownership. Independently owned
{{site.ai_gateway}} children inherit file defaults, rather than the gateway's
explicit metadata. Consumer credentials inherit consumer ownership. See the
[{{site.ai_gateway}} federation guide][site-ai-gateway-federation-guide] for the support
matrix, existing-resource ownership setup, and cascade-deletion limits.

## Namespace enforcement flags

The `kongctl plan` command provides built-in namespace guardrails:

- `--require-any-namespace` forces every managed resource to declare a namespace
  via `kongctl.namespace` or `_defaults.kongctl.namespace`.
- `--require-namespace=<ns>` restricts planning to the provided namespaces
  (repeat or comma-separate the flag to allow multiple values).

These flags help prevent accidentally operating on unexpected namespaces,
especially when running in sync mode.

External resources do not participate in namespace enforcement and do not
inherit `kongctl` metadata. If no managed parent resources are present, an
explicit `_defaults.kongctl.namespace` satisfies `--require-any-namespace` and
must match one of the values allowed by `--require-namespace`. Defaults on
external-only files are retained for enforcement without adding namespaces to
sync's deletion scope. Defaults-only files still select namespaces for sync
deletion.

`_deck` steps do not independently participate in namespace enforcement. For a
managed control plane, enforcement checks the control plane's namespace. A file
containing only external control planes with `_deck` must declare a matching
file-level default to satisfy namespace enforcement. This validates the
manifest's declared namespace; it does not check the external control plane's
labels or assign namespaces to Gateway entities managed by decK.

[site-ai-gateway-federation-guide]:
https://github.com/Kong/kongctl/blob/main/docs/ai-gateway-federation.md
