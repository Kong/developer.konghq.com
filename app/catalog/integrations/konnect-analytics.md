---
title: "{{site.observability}}"
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

works_on:
    - konnect
description: Connect reports from {{site.observability}}
search_aliases:
  - service catalog
  - konnect analytics
related_resources:
  - text: "Map {{site.observability}} reports in {{site.konnect_catalog}}"
    url: /how-to/map-analytics-resources/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
discovery_support: true
discovery_default: true
bindable_entities: "Report"
---

The {{site.observability}} integration will allow users to connect Reports from the {{site.observability}} product directly to their services. Users browsing the catalog will be able to see what reports are important to that service, and be brought directly to the report by clicking through.

## Authorize the {{site.observability}} integration

The {{site.observability}} integration is built directly into {{site.konnect_catalog}}. No additional authorization is required.


## Resources

Available {{site.observability}} entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "Report"
    description: "A Report in the {{site.observability}} product"
{% endtable %}

## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->