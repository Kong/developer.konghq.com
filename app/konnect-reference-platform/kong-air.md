---
title: KongAirlines
content_type: reference
layout: reference
products:
  - konnect-reference-platform
works_on:
  - konnect
description: A public implementation of the {{site.konnect_short_name}} Reference Platform. Lists the repositories, who owns each part, and where to start reading.
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

[KongAirlines](https://github.com/KongAirlines) is the example implementation of the Reference Platform.
Its public repositories show how service teams deliver independently while a platform team governs shared infrastructure and production Gateway changes.

The best starting points are the OpenAPI contracts, the [kongctl](/kongctl/) manifests, the generated [decK](/deck/) configuration, and the delivery workflows.
You can read them without deploying the example.
Use the [pattern guide](/konnect-reference-platform/patterns/) to choose the practices that you want to adapt.
You don't need to reproduce every repository and resource.

## Meet the repositories

The [platform repository](https://github.com/KongAirlines/platform) represents the platform team.
It owns shared {{site.konnect_short_name}} infrastructure, access governance, [Dev Portals](/dev-portal/), and production Gateway configuration.

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

Service teams own their development and production [Catalog](/catalog/) APIs, specifications, versions, and publications.
They write Gateway configuration directly to the development control plane of their team.
They propose production Gateway changes through platform PRs and don't write to the production control plane.

## Start with one service

Read [Bookings](https://github.com/KongAirlines/bookings) first, because it is a representative service repository.
The other services follow the same delivery structure.
Flights is a good contrast because it has a public API.

- [OpenAPI contract](https://github.com/KongAirlines/bookings/blob/main/openapi.yaml): the current development design.
- [{{site.konnect_short_name}} manifests](https://github.com/KongAirlines/bookings/tree/main/konnect): service-owned Catalog state and references to shared infrastructure.
- [Gateway artifacts](https://github.com/KongAirlines/bookings/tree/main/gateway): generated development and production configuration, and the policy inputs.
- [Workflows](https://github.com/KongAirlines/bookings/tree/main/.github/workflows): validation, development delivery, release preparation, and production promotion.

To see how these files connect in sequence, [follow an API change](/konnect-reference-platform/apiops/).

## Inspect the platform boundary

In the platform repository, compare the
[shared foundations](https://github.com/KongAirlines/platform/blob/main/konnect/foundations.yaml)
with the references that the service makes to those resources.
Then read the
[production Gateway configuration](https://github.com/KongAirlines/platform/tree/main/gateway/prod)
to see the reviewed service artifacts and their provenance.

The [production delivery workflow](https://github.com/KongAirlines/platform/blob/main/.github/workflows/apply-production-gateway.yaml)
shows how platform approval leads to Gateway synchronization.
After synchronization, the workflow dispatches production Catalog delivery to the service that owns the change.

## Explore the consumer experience

The platform also owns the [Portal pages and navigation](https://github.com/KongAirlines/platform/tree/main/konnect/portal).
Publications that the services own connect API delivery to discovery and application access.
The source of the protected services uses fictional accounts that belong to an application.
It doesn't use passenger login.

The Gateway delivery workflows don't deploy the application source.
The source shows the identity contract.
It doesn't show how an existing upstream deployment behaves.

## Choose what to adapt

The repository topology, the version conventions, and the authentication strategy are example decisions.
You can adopt API-first PR review without the same Portal or control plane topology.
Start with a [pattern that addresses your needs](/konnect-reference-platform/patterns/).
For design tradeoffs, read the [FAQ](/konnect-reference-platform/faq/).
