---
title: "Datadog"
content_type: reference
layout: reference

products:
    - service-catalog
    - gateway
    

no_version: true

breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The Datadog integration lets you connect Datadog entities directly to your Service Catalog Services.
discovery_support: true
bindable_entities: "Datadog Monitor, Datadog Dashboard"

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
---

The Datadog integration lets you connect Datadog entities directly to your Service Catalog services.

## Authenticate the Datadog integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/service-catalog/integrations)**. 
1. Select **Datadog**, then **Install Datadog**.
1. Select your Datadog region and enter your [Datadog API and application keys](https://docs.datadoghq.com/account_management/api-app-keys/). 
1. Select **Authorize**. 

## Resources

Available Datadog resources:

| Entity | Description |
|-------|-------------|
| [Datadog Monitor](https://docs.datadoghq.com/monitors/) | Provides visibility into performance issues and outages. |
| [Datadog Dashboard](https://docs.datadoghq.com/dashboards/) | Provides visibility into the performance and health of systems and applications in your org. |

## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



