---
title: Traceable Integration
content_type: reference
layout: reference

products:
    - gateway
breadcrumbs:
  - /service-catalog/
  - /service-catalog/service-catalog-integrations/

works_on:
    - konnect
description: The Traceable integration lets you connect Traceable entities directly to your Service Catalog Services.

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
discovery_support: true
bindable_entities: "Traceable Service"
---

The Traceable integration lets you connect Traceable Services directly to your Service Catalog services.

## Authenticate the Traceable integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **Traceable**, then **Install Traceable**.
3. Select **Authorize**. 

## Resources

Entity | Description
-------|-------------
Traceable Service | A [Traceable Service](https://docs.traceable.ai/docs/domains-services-backends), which holds groups of Traceable API endpoint resources.

## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



