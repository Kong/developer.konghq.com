---
title: SwaggerHub
content_type: reference
layout: reference

products:
    - gateway
breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The SwaggerHub integration lets you connect SwaggerHub API specs directly to your Service Catalog Services.
related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
discovery_support: true
bindable_entities: "SwaggerHub API version"
---

The SwaggerHub integration lets you connect SwaggerHub API specs directly to your Service Catalog services.

## Prerequisites

You need a SwaggerHub API key to authenticate your SwaggerHub account with {{site.konnect_short_name}}.

## Authenticate the SwaggerHub integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/service-catalog/integrations)**. 
2. Select **SwaggerHub**, then **Install SwaggerHub**.
3. Select **Authorize**. 

This will take you to SwaggerHub, where you can use your SwaggerHub API key to grant {{site.konnect_short_name}} access to your account.

## Resources

Entity | Description
-------|-------------
{{page.bindable_entities}} | A [SwaggerHub API version](https://support.smartbear.com/swaggerhub/docs/en/manage-apis/versioning.html?sbsearch=API%20Versions), which is the unique version identifier for a specific API spec.

## Discovery information

{:.info}
> This integration will discover both public and private SwaggerHub APIs in the linked account.

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



