---
title: Traceable
content_type: reference
layout: reference

products:
    - service-catalog
    - gateway

tags:
  - integrations
  - traceable

breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The Traceable integration lets you connect Traceable entities directly to your Service Catalog services.

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
  - text: Traceable plugin
    url: /plugins/traceable/
discovery_support: true
bindable_entities: "Traceable Service"
---

The Traceable integration lets you connect Traceable Services directly to your Service Catalog services.
{% include /service-catalog/multi-resource.md %}

## Authenticate the Traceable integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **Add Traceable Instance**.
3. Configure the instance, add authorization and name the instance. 

## Resources

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: Traceable Service
    description: 
      A direct mapping to a [Traceable Service](https://docs.traceable.ai/docs/domains-services-backends), which holds groups of Traceable API endpoint resources.
{% endtable %}
<!--vale on-->

## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



