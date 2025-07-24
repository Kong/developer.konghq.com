---
title: "Mesh Manager"
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
description: Map Mesh Services from {{site.konnet_short_name}} Mesh Manager to visualize how configuration and policies are distributed across mesh deployments in multiple zones.

related_resources:
  - text: Map Mesh Manager services in Service Catalog
    url: /how-to/map-mesh-manager-resources/
  - text: "Service Catalog"
    url: /service-catalog/
discovery_support: true
discovery_default: true
bindable_entities: "Mesh Service"
---

The {{site.konnect_short_name}} Mesh integration allows users gain visibility into how their service is deployed across meshes and zones, determine whether their deployment is healthy, and (if used in conjunction with other built-in integrations) to identify links between their mesh services and other {{site.konnect_short_name}} resources.

## Authorize the Mesh Manager integration

The Mesh Manager integration is built directly into Service Catalog. No additional authorization is required. As new Mesh Services are created in Mesh Manager, they are automatically discovered by Service Catalog and surfaced as Resources.



## Resources

Available Mesh Manager entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "Mesh Service"
    description: "A Mesh Service (Service and Global Control Plane) with the Zone dimension included"
{% endtable %}




## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->