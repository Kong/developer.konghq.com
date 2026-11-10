---
title: "Reusable configuration templates with kongctl"
description: "Reuse configuration and understand inheritance and merge rules."
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

Read this page when sharing configuration across resources or files with
`_templates` and `_extends`.

Use a top-level `_templates` configuration block to define named, reusable
configuration blocks. Add `_extends` to a resource or nested configuration block
to merge one named template into that block. Both keys are authoring constructs:
`kongctl` removes them before validation, planning, or sending configuration to
an API.

Templates apply to any resource configuration block. For example, a shared
Portal parent configuration and Portal Page child configuration can be used
together:

```yaml
_templates:
  standard-developer-portal:
    authentication_enabled: true
    rbac_enabled: true
    default_api_visibility: private
    default_page_visibility: private
    labels:
      managed-by: kongctl
      experience: standard

  published-guide-page:
    visibility: public
    status: published
    description: Developer documentation

portals:
  - _extends: standard-developer-portal
    ref: payments-portal
    name: Payments Developer Portal
    display_name: Payments APIs
    labels:
      business-unit: payments
    pages:
      - _extends: published-guide-page
        ref: payments-getting-started
        slug: getting-started
        title: Getting Started
        content: !file ./pages/payments-getting-started.md
```

The effective Portal labels contain `managed-by`, `experience`, and
`business-unit`. A child template can also be used in a root-level declaration:

```yaml
portal_pages:
  - _extends: published-guide-page
    ref: payments-authentication
    portal: payments-portal
    slug: authentication
    title: Authentication
    content: !file ./pages/authentication.md
```

Expansion is independent of field names and resource types. The following
{{site.ai_gateway}} example reuses both policy fields and the policy's nested
`config` configuration block. The `config` key has no special template behavior.

```yaml
_templates:
  corporate-oidc-config:
    issuer: https://auth.example.com
    auth_methods: [bearer]
    bearer_token_param_type: [header]
    consumer_optional: false
    hide_credentials: true

  standard-oidc-policy:
    type: openid-connect
    enabled: true
    global: false
    config:
      _extends: corporate-oidc-config

ai_gateways:
  - ref: shared-ai-gateway
    name: shared-ai-gateway
    display_name: Shared AI Gateway
    policies:
      - _extends: standard-oidc-policy
        ref: payments-oidc
        name: payments-oidc
        display_name: Payments OIDC
        config:
          groups_required: [payments-api-users]

      - _extends: standard-oidc-policy
        ref: reporting-oidc
        name: reporting-oidc
        display_name: Reporting OIDC
        config:
          groups_required: [reporting-api-users]
```

### Template discovery and inheritance

All files supplied to one command share one template registry. This includes
explicit files, recursively discovered directory files, standard input, and HTTP
or HTTPS sources. A template-only file is valid when it is loaded with at least
one resource file:

```shell
kongctl plan -f templates.yaml -f portals.yaml
kongctl plan -f ./configuration --recursive
```

`kongctl` does not search files outside the supplied source set. Template names
must be non-empty strings and must be unique across that source set. Duplicate
names are errors even when the definitions are identical or unused.

A template can extend another template:

```yaml
_templates:
  standard-portal:
    authentication_enabled: true
    default_api_visibility: private

  restricted-portal:
    _extends: standard-portal
    rbac_enabled: true
```

Each configuration block can extend exactly one template. Circular inheritance
and unknown template names are errors. Templates may define identity fields such
as `ref` and `name`, but each consumer must override them when uniqueness is
required.

### Merge rules

The consumer configuration block takes precedence over the template:

| Template and consumer values | Result |
| --- | --- |
| Both configuration blocks | Recursively merge their keys |
| Consumer scalar | Replace the template value |
| Consumer sequence | Replace the complete template sequence |
| Consumer explicit `null` | Replace the template value with `null` |
| Consumer key omitted | Retain the template value |
| Different value types | Replace with the consumer value |

Sequences never append or merge by element. A template definition must be a
configuration block; a sequence can be inherited only as a value within that
block. Individual configuration blocks inside a sequence can use `_extends`.

Templates are expanded before normal schema validation and sync-scope capture.
An inherited empty child collection therefore has the same sync behavior as an
empty collection written directly on the resource. YAML tags in a template use
the template definition file's context, so a relative `!file` path is relative
to that file. Deferred `!env` and `!secret` values retain their existing
behavior after expansion.

`_templates` is separate from `_defaults`: templates are selected explicitly and
shared across the source set, while defaults remain automatic and file-local.
`_extends` is not interpreted inside `_defaults`.
