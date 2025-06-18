---
title: "{{site.konnect_short_name}} Analytics"
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
description: Connect reports from {{site.konnect_short_name}} Analytics

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
discovery_support: true
discovery_default: true
bindable_entities: "Service"
---

The {{site.konnect_short_name}} Analytics integration will allow users to connect Reports from the {{site.konnect_short_name}} Analytics product directly to their services. Users browsing the catalog will be able to see what reports are important to that service, and be brought directly to the report by clicking through.

## Authorize the {{site.konnect_short_name}} Analytics integration

The {{site.konnect_short_name}} Analytics integration is built directly into Service Catalog. No additional authorization is required.


## Resources

Available Mesh Manager entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "Report"
    description: "A Report in the Konnect Analytics product"
{% endtable %}




## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->