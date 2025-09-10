---
title: "AWS API Gateway"
content_type: reference
layout: reference

products:
    - service-catalog
    - gateway
    
tags:
  - integrations
  - aws

breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The AWS API Gateway integration allows you to associate your Service Catalog service to one or more API Gateway APIs. 

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
  - text: Import and map AWS API Gateway resources in Service Catalog
    url: /how-to/install-and-map-aws-gateway-apis/
discovery_support: true
bindable_entities: "APIs"
---

The GitHub integration allows you to associate your Service Catalog service to one or more API Gateway APIs.

{% include /service-catalog/multi-resource.md %}

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map GitHub resources in Service Catalog](/how-to/install-and-map-github-resources/).

## Authorize the GitHub integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **AWS API Gateway**, then **Add AWS Instance**.
3. Select **Authorize**. 

## Resources

Available GitHub entities:

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: API
    description: An AWS API Gateway API that relates to the Service Catalog service.
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