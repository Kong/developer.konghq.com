---
title: Federated APIOps
content_type: reference
layout: reference
products:
  - konnect-reference-platform
description: How service and platform teams deliver APIs with kongctl and decK.
breadcrumbs:
  - /konnect-reference-platform/
related_resources:
  - text: Reference Platform
    url: /konnect-reference-platform/
  - text: KongAirlines implementation
    url: /konnect-reference-platform/kong-air/
  - text: Adopt the architecture
    url: /konnect-reference-platform/how-to/
  - text: Frequently asked questions
    url: /konnect-reference-platform/faq/
---

[APIOps](/deck/apiops/) applies version control, review, automation, and
declarative configuration to the API lifecycle. The Reference Platform uses a
federated model: desired state remains with the team that owns the resource,
and each repository invokes supported tooling directly.

## Sources of truth

There are no environment branches and no separate service registry.

- OpenAPI documents describe API contracts.
- kongctl manifests describe Konnect Catalog and shared platform resources.
- decK manifests describe {{site.base_gateway}} runtime entities.
- `main` contains separate development and production resources and files.

Service repositories own their development and production Catalog APIs,
versions, specifications, publications, and control-plane implementations.
They also own development Gateway configuration. The platform repository owns
shared foundations and the production Gateway aggregate.

## Generate Gateway state

Each service repository has a deterministic generation script. It performs the
following operations with a pinned decK version:

1. `deck file openapi2kong` converts the selected OpenAPI document.
2. `deck file patch` adds `_info.select_tags` and makes shared-control-plane
   health Routes service-specific.
3. Protected services use `deck file add-plugins` to attach service-scoped ACE
   with `match_policy: required`.
4. `deck file add-tags` ensures Services, Routes, and plugins carry environment,
   team, owner, and service-stage tags.
5. `deck file validate` checks each result before it is committed.

Development files select a unique service-stage tag so sibling repositories can
apply to a shared team control plane. Production files select the common
`env-prod` tag and are applied together by the Platform Team. The initial model
uses `kongctl apply`; it does not prune omitted resources.

Pull-request validation regenerates both files without Konnect credentials and
fails on a Git diff. Contributor code in an untrusted fork never receives a
Konnect token or platform-promotion credential.

## Development delivery

After a service change reaches `main`, the repository runs:

```sh
kongctl apply -f konnect/dev.yaml --base-dir . \
  --require-namespace <service>-dev
```

The manifest uses `_external` and `!lookup` to resolve the Platform Team-owned
development control plane and Portal. `_deck` makes kongctl run one decK apply
for that service's tagged Gateway state. The same kongctl operation manages the
service-owned private Catalog API and its control-plane implementation.

Each repository uses a dedicated Konnect system account token. kongctl
namespaces define declarative ownership; Konnect RBAC defines what that identity
can actually change. Sibling repositories can run at the same time in v1. Their
unique names and tags avoid normal collisions, and apply-only behavior avoids
deleting each other's omitted state.

## Production promotion

Production uses an explicit ownership boundary:

1. A service PR retains the release OpenAPI document and regenerates the
   production decK candidate.
2. After merge, a trusted workflow copies the exact candidate into
   `KongAirlines/platform` and opens a PR.
3. The platform PR records the source repository, commit, SHA-256 checksum,
   decK version, and kongctl version.
4. The Platform Team reviews and merges the Gateway change.
5. The platform workflow applies all four production files in one kongctl
   `_deck` operation against `kongairlines-prod`.
6. The Service Team manually dispatches its production Catalog apply from the
   exact promoted service commit.
7. A protected GitHub Environment supplies production approval.

<!--vale off -->
{% mermaid %}
sequenceDiagram
  participant S as Service repository
  participant P as Platform repository
  participant G as Production Gateway
  participant C as Konnect Catalog
  S->>S: Generate and validate candidate
  S->>P: Open promotion PR with provenance
  P->>P: Platform review
  P->>G: Aggregate kongctl apply with _deck
  S->>C: Approved kongctl apply from promoted commit
{% endmermaid %}
<!--vale on -->

The platform copy is the production Gateway source of truth. Do not hand-edit
it. Make corrections in the service repository and promote a new exact copy.
Rollback follows the same additive PR process using retained release inputs;
v1 does not define deletion reconciliation.

## Authentication flow

Bookings and Customer Information publish with separate platform-owned
development and production Key Auth strategies. Their decK files install ACE on
the Gateway Service. Because the Catalog API links to a control plane, ACE uses
the OpenAPI operations for application access decisions independently from the
Gateway Route layout. Destinations and Flights publish without auth strategies
and have no ACE plugin.
