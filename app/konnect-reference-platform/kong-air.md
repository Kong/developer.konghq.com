---
title: KongAirlines
content_type: reference
layout: reference
products:
  - konnect-reference-platform
works_on:
  - konnect
description: A public implementation of the {{site.konnect_short_name}} Reference Platform.
breadcrumbs:
  - /konnect-reference-platform/
related_resources:
  - text: Reference Platform
    url: /konnect-reference-platform/
  - text: APIOps workflows
    url: /konnect-reference-platform/apiops/
  - text: Adopt the architecture
    url: /konnect-reference-platform/how-to/
  - text: Frequently asked questions
    url: /konnect-reference-platform/faq/
---

[KongAirlines](https://github.com/KongAirlines) is the public Reference
Implementation for this architecture. The repositories contain application
code so the example feels realistic, but the important artifacts are the
OpenAPI documents, kongctl manifests, generated decK files, and GitHub Actions
workflows. You can read them, copy the relevant pieces, and adapt the names and
topology to your organization.

## Repository ownership

The [platform repository](https://github.com/KongAirlines/platform) owns shared
foundations: organization teams, RBAC assignments, Developer Portals,
application auth strategies, control planes, and the reviewed production
Gateway aggregate.

Two service teams own four active repositories:

| Team | Repository | Authorization | Development control plane |
| --- | --- | --- | --- |
| `customer-data` | [bookings](https://github.com/KongAirlines/bookings) | Key Auth and ACE | `customer-data-dev` |
| `customer-data` | [customer](https://github.com/KongAirlines/customer) | Key Auth and ACE | `customer-data-dev` |
| `flight-data` | [destinations](https://github.com/KongAirlines/destinations) | Anonymous | `flight-data-dev` |
| `flight-data` | [flights](https://github.com/KongAirlines/flights) | Anonymous | `flight-data-dev` |

## What a service repository owns

Each active repository uses the same readable layout:

```text
openapi.yaml
openapi/versions/0.1.0.yaml
konnect/dev.yaml
konnect/prod.yaml
gateway/dev/kong.yaml
gateway/prod/kong.yaml
scripts/generate-gateway.sh
.github/workflows/
```

The root OpenAPI document is mutable development state. Versioned files are
retained release inputs for production. `konnect/dev.yaml` declares a private
development Catalog API, resolves the platform-owned Portal and control plane,
and attaches the repository's decK file through `_deck`. `konnect/prod.yaml`
declares a distinct public production Catalog API and a control-plane
implementation, but cannot apply production Gateway state.

Bookings and Customer Information use `deck file add-plugins` to add the `ace`
plugin to their generated Gateway Service with `match_policy: required`. Their
publications select the platform-owned Key Auth strategy. Destinations and
Flights declare neither an auth strategy nor ACE.

## What the platform repository owns

The platform repository contains direct kongctl manifests, not a registry or a
format that generates another desired-state format:

- `konnect/foundations.yaml` declares teams, control planes, Portals, and Key
  Auth strategies.
- `konnect/access.yaml` assigns roles to existing repository automation
  identities.
- `konnect/production-gateway.yaml` resolves one production control plane and
  applies four promoted decK files in one `_deck` operation.
- `gateway/prod/` contains exact service-generated artifacts. Platform changes
  go back to the service repository and are promoted again.

## Tooling dependencies

The manifests intentionally exercise federated external lookup and
control-plane API implementations. This provides a practical test bed for
kongctl declarative support. Control-plane implementation support is tracked in
[Kong/kongctl#1992](https://github.com/Kong/kongctl/pull/1992); use a kongctl
release containing that change before applying the example.

See [APIOps workflows](/konnect-reference-platform/apiops/) for the complete
development and production sequence.
