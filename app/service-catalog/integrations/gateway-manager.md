---
title: "Gateway Manager"
content_type: reference
layout: reference

products:
    - service-catalog
    - gateway
    
tags:
  - integrations

breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The Gateway Manager integration is built directly into Service Catalog, so no additional authorization is needed.

related_resources:
  - text: Map Gateway Manager resources in Service Catalog
    url: /how-to/map-gateway-manager-resources/
  - text: "Service Catalog"
    url: /service-catalog/
discovery_support: true
bindable_entities: "Gateway Service"
---

This integration allows you to associate your Service Catalog service to one or more Gateway Services registered in {{site.konnect_short_name}}’s Gateway Manager application.

## Authorize the Gateway Manager integration

The Gateway Manager integration is built directly into Service Catalog. No additional authorization is required. As new Gateway Services are created in Gateway Manager, they are automatically discovered by Service Catalog and surfaced as Resources.



## Resources

Available Gateway Manager entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "Gateway Service"
    description: "Represents an upstream backend service in your system. See [Gateway Services](/gateway-manager/) for more information."
{% endtable %}


## Events

This integration supports events.

You can view the following event types for linked Gateway Services from the {{site.konnect_short_name}} UI:

* Plugin added
* Plugin updated
* Plugin removed


## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->