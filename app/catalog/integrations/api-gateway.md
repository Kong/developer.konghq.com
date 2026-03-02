---
title: "API Gateway integration"
content_type: reference
layout: reference

products:
    - catalog
    - gateway
    
tags:
  - integrations

breadcrumbs:
  - /catalog/
  - /catalog/integrations/
search_aliases:
  - service catalog
  - gateway manager integration
works_on:
    - konnect
description: The API Gateway integration is built directly into {{site.konnect_catalog}}, so no additional authorization is needed.

related_resources:
  - text: Map API Gateway Services in {{site.konnect_catalog}}
    url: /how-to/map-api-gateway-resources/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
discovery_support: true
bindable_entities: "Gateway Service"
---

This integration allows you to associate your {{site.konnect_catalog}} service to one or more Gateway Services registered in {{site.konnect_short_name}}’s API Gateway application.

## Authorize the API Gateway integration

The API Gateway integration is built directly into {{site.konnect_catalog}}. No additional authorization is required. As new Gateway Services are created in API Gateway, they are automatically discovered by {{site.konnect_catalog}} and surfaced as Resources.

## Authorize the API Gateway integration

The API Gateway integration is built directly into Service Catalog. No additional authorization is required. As new Gateway Services are created in {{site.konnect_short_name}}, they are automatically discovered by Service Catalog and surfaced as Resources.

## Resources

Available API Gateway entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "Gateway Service"
    description: "Represents an upstream backend service in your system. See [Gateway Services](/gateway/entities/service/) for more information."
{% endtable %}


## Events

This integration supports events.

You can view the following event types for linked Gateway Services from the {{site.konnect_short_name}} UI:

* Plugin added
* Plugin updated
* Plugin removed


## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->