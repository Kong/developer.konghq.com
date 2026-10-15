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

{% table %}
columns:
  - title: Team
    key: team
  - title: Repository
    key: repository
  - title: Authorization
    key: authorization
  - title: Development control plane
    key: control_plane
rows:
  - team: "`customer-data`"
    repository: "[bookings](https://github.com/KongAirlines/bookings)"
    authorization: Key Auth and ACE
    control_plane: "`customer-data-dev`"
  - team: "`customer-data`"
    repository: "[customer](https://github.com/KongAirlines/customer)"
    authorization: Key Auth and ACE
    control_plane: "`customer-data-dev`"
  - team: "`flight-data`"
    repository: "[destinations](https://github.com/KongAirlines/destinations)"
    authorization: Anonymous
    control_plane: "`flight-data-dev`"
  - team: "`flight-data`"
    repository: "[flights](https://github.com/KongAirlines/flights)"
    authorization: Anonymous
    control_plane: "`flight-data-dev`"
{% endtable %}

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
scripts/prepare-release.sh
scripts/validate-api-releases.sh
.github/workflows/
```

The root OpenAPI document is the mutable next-beta contract. Versioned files
are immutable stable releases. The API-level `version` in `konnect/prod.yaml`
selects the current production release, so generation does not contain a
hard-coded release path. `konnect/dev.yaml` declares a private development
Catalog API, resolves the platform-owned Portal and control plane, and attaches
the repository's decK file through `_deck`. `konnect/prod.yaml` declares a
distinct public production Catalog API and a control-plane implementation, but
cannot apply production Gateway state.

The manually dispatched release workflow takes a stable release version and
the next development version. It opens a service PR that snapshots the current
beta, advances the root contract to the next `-beta.1`, updates the production
selector, and regenerates both Gateway artifacts. CI also prevents released
specifications from being changed or removed.

The platform repository installs ACE globally on each control plane with
`match_policy: required`. Bookings and Customer Information publications select
the platform-owned Key Auth strategy, so their matched OpenAPI operations
require application credentials. Destinations and Flights publish operations
without an auth strategy and remain anonymous.

## What the platform repository owns

The platform repository contains direct kongctl manifests, not a registry or a
format that generates another desired-state format:

- `konnect/foundations.yaml` declares teams, control planes, Portals, and Key
  Auth strategies.
- `konnect/access.yaml` assigns roles to existing repository automation
  identities.
- `konnect/development-gateway.yaml` installs shared control-plane policy,
  including global ACE, on both development control planes.
- `konnect/production-gateway.yaml` resolves one production control plane and
  applies platform policy and four promoted decK files in one `_deck`
  operation.
- `gateway/prod/` contains exact service-generated artifacts. Platform changes
  go back to the service repository and are promoted again.

## Tooling dependencies

The manifests intentionally exercise federated external lookup and
control-plane API implementations. The workflows install the latest stable
kongctl release so the example provides a practical test bed for current
declarative support and surfaces compatibility regressions.

See [APIOps workflows](/konnect-reference-platform/apiops/) for the complete
development and production sequence.
