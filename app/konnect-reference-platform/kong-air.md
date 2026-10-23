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
  - text: Follow an API change
    url: /konnect-reference-platform/apiops/
  - text: General APIOps example with decK
    url: /deck/apiops/
  - text: Adapt patterns from KongAirlines
    url: /konnect-reference-platform/patterns/
  - text: Frequently asked questions
    url: /konnect-reference-platform/faq/
---

[KongAirlines](https://github.com/KongAirlines) is the example implementation of
the Reference Platform. Its public repositories show how service teams can
deliver independently while a platform team governs shared infrastructure and
production Gateway changes.

The useful starting points are the OpenAPI contracts, [kongctl](/kongctl/)
manifests, generated [decK](/deck/) configuration, and delivery workflows.
You can read them without deploying the example. Use the
[pattern guide](/konnect-reference-platform/patterns/) to choose practices
to adapt rather than reproducing every repository and resource.

## Meet the repositories

The [platform repository](https://github.com/KongAirlines/platform) represents
the platform team. It owns shared Konnect infrastructure, access governance,
Developer Portals, and production Gateway configuration.

Two service teams own the API repositories:

{% table %}
columns:
  - title: Team
    key: team
  - title: Repository
    key: repository
  - title: Example API access
    key: access
rows:
  - team: customer-data
    repository: "[bookings](https://github.com/KongAirlines/bookings)"
    access: Approved Portal application API key
  - team: customer-data
    repository: "[customer](https://github.com/KongAirlines/customer)"
    access: Approved Portal application API key
  - team: flight-data
    repository: "[destinations](https://github.com/KongAirlines/destinations)"
    access: Public
  - team: flight-data
    repository: "[flights](https://github.com/KongAirlines/flights)"
    access: Public
{% endtable %}

Service teams own their development and production Catalog APIs, specifications,
versions, and publications. They write Gateway configuration directly to their
team's development control plane. They propose production Gateway changes
through platform PRs instead of writing to the production control plane.

## Start with one service

Read [Bookings](https://github.com/KongAirlines/bookings) as a representative
service repository. The other services follow the same delivery structure;
Flights provides a public-API contrast.

- [OpenAPI contract](https://github.com/KongAirlines/bookings/blob/main/openapi.yaml):
  the current development design.
- [Konnect manifests](https://github.com/KongAirlines/bookings/tree/main/konnect):
  service-owned Catalog state and references to shared infrastructure.
- [Gateway artifacts](https://github.com/KongAirlines/bookings/tree/main/gateway):
  generated development and production configuration, alongside policy inputs.
- [Workflows](https://github.com/KongAirlines/bookings/tree/main/.github/workflows):
  validation, development delivery, release preparation, and production promotion.

For the sequence connecting these files, [follow an API change](/konnect-reference-platform/apiops/).

## Then inspect the platform boundary

In the platform repository, compare the
[shared foundations](https://github.com/KongAirlines/platform/blob/main/konnect/foundations.yaml)
with the service's references to those resources. Then inspect
[production Gateway configuration](https://github.com/KongAirlines/platform/tree/main/gateway/prod)
to see the reviewed service artifacts and their provenance.

The [production delivery workflow](https://github.com/KongAirlines/platform/blob/main/.github/workflows/apply-production-gateway.yaml)
shows how platform approval leads to Gateway synchronization and then dispatches
production Catalog delivery back to the owning service.

## Explore the consumer experience

The platform also owns [Portal pages and navigation](https://github.com/KongAirlines/platform/tree/main/konnect/portal).
Service-owned publications connect API delivery to discovery and application
access. The protected service source demonstrates fictional accounts scoped to
an application, not passenger login.

The Gateway delivery workflows do not deploy the application source. Read that
source as an illustration of the identity contract, not proof that an existing
upstream deployment implements it.

## Choose what to adapt

The repository topology, version conventions, and authentication strategy are
example decisions. You can adopt API-first PR review without also adopting the
same Portal or control-plane topology. Start with a
[pattern that addresses your needs](/konnect-reference-platform/patterns/),
and consult the [FAQ](/konnect-reference-platform/faq/) for design tradeoffs.
