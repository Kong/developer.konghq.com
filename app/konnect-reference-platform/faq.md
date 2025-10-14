---
title: Frequently asked questions
content_type: reference
layout: reference

products:
  - konnect-reference-platform

works_on:
  - konnect

description: |
    Provides a complete guide for platform builders to integrate {{site.konnect_product_name}} into 
    their engineering organization and API delivery process. 

breadcrumbs:
  - /konnect-reference-platform/

related_resources:
- text: Reference Platform - Home
  url: /konnect-reference-platform/
- text: Reference Platform - Konnect Orchestrator 
  url: /konnect-reference-platform/orchestrator/
- text: Reference Platform - Kong Air
  url: /konnect-reference-platform/kong-air/
- text: Reference Platform - How-To
  url: /konnect-reference-platform/how-to/
- text: Reference Platform - APIOps
  url: /konnect-reference-platform/apiops/
---

## What is the specific role of the Platform Team in the Reference Platform?
The Reference Platform operates off of a central code repository, the _Platform Team_ repository. This is by design, such that organizations
can on-board application teams without having to "inject" and code or process into the application team code, repositories or engineering workflows.

All APIOps workflows are stored and execute within the Platform repository. Application team API specifications are read from their repositories
and copied into the Platform team repository for staging, before delivery to {{site.konnect_product_name}}.

In the future, the reference platform may evolve to support a more decentralized approach, where Application teams can own more of the API delivery 
pipeline and take advantage of {{site.base_gateway}} capabilities directly.

## What Konnect Organization design should I follow?

{{site.konnect_product_name}}'s design centers around the concept of an organization. An organization is an isolated tenant of Konnect resources with 
its own configuration and set of teams, users, API Gateways, APIs, Developer Portals, and other resources. Konnect users may decide between a 
single or multi-organization design when implementing their Konnect usage. The Konnect Orchestrator can manage resources in multiple organizations, 
but there is no coordination or connectivity between organizations at the Konnect level. Choosing your organization design is an important
consideration before proceeding with your Konnect implementation. Here are some factors that may determine which design to choose:

<u>Multiple Organizations</u>:

* Data between organizations is isolated, limiting the ability of Konnect applications to provide visibility into the full usage of the platform
* Some Business may have strict compliance requirements requiring strong isolation of data between business units or products which multiple organizations can provide
* It may be desired to strongly isolate critical API runtime configurations between business units

<u>Single Organization</u>:

* One organization allows Konnect applications full visibility across your businesses usage of the platform enabling deeper insights, analytics, and capabilities
* A single Konnect {{site.konnect_catalog}} allows for a true central catalog of service applications running across your business
* Data and analytics cannot be shared across organizations. A single organization provides a single accurate view of your businesses usage of the Konnect platform
* A single organization provides better visibility into your businesses usage of the platform which will provide better 
  information regarding billing and contractual usage of the platform
* Single organization can eliminate redundant configuration of key shared resources successfully as network settings, authorization integrations, 
  audit logging, and more

## Why do I see the warning message "Found 0 services for API ... Cannot create API implementation relation..."

The reference platform uses the {{site.konnect_short_name}} Developer Portal product, which is used to publish the API specifications
to a catalog for API consumers to discover and review. The Developer Portal model is based on an _API_ resource which is managed by the
orchestrator during the reconciliation loop. Those API resources can be associated with gateway services (called an _implementations_). 

In order for the orchestrator to successfully associate an _API_ with a gateway service, the service must exist in the control plane. 
There is a chicken and egg problem, because the services are managed by the APIOps workflows, which execute independently of the orchestrator
reconciliation loop.

During the APIOps workflows, gateway services are tagged with API names. During the reconciliation loop, the orchestrator looks for these
tags in order to associate the API with the service. Once the APIOps workflows have executed once, the gateway services will be tagged and
the next reconciliation loop will associate the API with the service properly.

