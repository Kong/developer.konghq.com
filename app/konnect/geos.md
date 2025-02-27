---
title: "Geographic Regions"
description: '{{site.konnect_short_name}} allows you to host and operate your cloud instance in a geographic region that you specify. This is important for data privacy and regulatory compliance for you organization.'
content_type: reference
layout: reference
products:
    - gateway
tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform
tags:
  - regions
  - geos
  - network
  
related_resources:
  - text: "{{site.konnect_short_name}} ports and network requirements"
    url: /konnect/network/
---

{{site.konnect_short_name}} allows you to host and operate your cloud instance in a geographic region that you specify. This is important for data privacy and regulatory compliance for you organization. 

Geographic regions allow you to also operate {{site.konnect_short_name}} in a similar geo to your users and their infrastructure applications. 
<!--- Do not publish yet: "This reduces network latency and minimizes the blast-radius in the event of cross-region connectivity failures." -->

## Geo-specific objects

Certain objects, like Consumers and Gateway Services, inside your {{site.konnect_short_name}} instance are geo-specific. This means that if you create one of these objects in an instance of {{site.konnect_short_name}} that is deployed in a particular geo, that object won't exist in a different geo.

Only authentication, billing, and usage is shared between {{site.konnect_short_name}} geos.

The following objects are geo-specific:

* [Gateway Services](/gateway/entities/service/)
* [Routes](/gateway/entities/route/)
* [Consumers](/gateway/entities/consumer/)
* [API products](/konnect/api-products/)
* [Application registration](/konnect/dev-portal/app-reg/)
* [Dev portals](/konnect/dev-portal/)
* [Service meshes and mesh zones](/konnect/mesh-manager/)
* [Custom teams and roles](/konnect/teams-and-roles/)

## Supported geos 

### Control planes

{{site.konnect_short_name}} currently supports the following geos:

* AU (Australia)
* EU (Europe)
* ME (Middle East)
* US (United States)
* IN (India)


### Dedicated Cloud Gateways

{{site.konnect_short_name}} [Dedicated Cloud Gateways](/konnect/dedicated-cloud-gateways/) support the following geos:

{% include_cached /sections/dcg-regions.md %}