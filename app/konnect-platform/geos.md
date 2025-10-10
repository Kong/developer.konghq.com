---
title: "Geographic regions"
description: '{{site.konnect_short_name}} allows you to host and operate your cloud instance in a geographic region that you specify. This may be important for data privacy and regulatory compliance for your organization.'
content_type: reference
layout: reference
products:
  - konnect
tags:
  - geos
search_aliases:
  - geos
  - data centers
works_on:
  - konnect
breadcrumbs:
  - /konnect/
related_resources:
  - text: "{{site.konnect_short_name}} ports and network requirements"
    url: /konnect-platform/network/
  - text: "Dedicated Cloud Gateways"
    url: /dedicated-cloud-gateways/
  - text: "{{site.konnect_short_name}} Platform"
    url: /konnect/
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
* [API products](/api/konnect/api-products/)
* [Application registration](/dev-portal/self-service/#application-authentication-strategies)
* [Dev portals](/dev-portal/)
* [Service meshes and mesh zones](/mesh-manager/)
* [Custom teams and roles](/konnect-platform/teams-and-roles/)

## Supported geos 

{% include_cached /sections/cp-regions.md %}

### Dedicated Cloud Gateways

{{site.konnect_short_name}} [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) support the following geos:

{% include_cached /sections/dcg-regions.md %}

### Customer-Managed Encryption Keys (CMEK) region mapping

{{site.konnect_short_name}} supports [Customer-Managed Encryption Keys (CMEK)](/konnect-platform/cmek/), allowing you to use your own symmetric key stored in AWS Key Management Service (KMS) to encrypt a pre-determined set of sensitive data. 

A CMEK must be replicated to all AWS regions that make up a {{site.konnect_short_name}} region.

{% include_cached /konnect/cmek-region-mapping.md %}
