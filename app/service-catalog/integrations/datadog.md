---
title: "Datadog"
content_type: reference
layout: reference

products:
    - gateway

description: placeholder

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
---

The Datadog integration lets you connect Datadog entities directly to your Service Catalog services.

## Authenticate the Datadog integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/service-catalog/integrations)**. 
1. Select **Datadog**, then **Install Datadog**.
1. Select your Datadog region and enter your [Datadog API and application keys](https://docs.datadoghq.com/account_management/api-app-keys/). 
1. Select **Authorize**. 

## Resources

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



