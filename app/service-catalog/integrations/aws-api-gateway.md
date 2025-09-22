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
description: The AWS API Gateway integration allows you to associate your Service Catalog service with one or more AWS API Gateway APIs. 

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
  - text: Import and map AWS API Gateway resources in Service Catalog
    url: /how-to/install-and-map-aws-gateway-apis/
  - text: "Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} API"
    url: /how-to/discover-aws-gateway-apis-using-konnect-api/
  - text: "Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} UI"
    url: /how-to/discover-aws-gateway-apis-using-konnect-ui/
  - text: Discover and govern APIs with Service Catalog
    url: /how-to/discover-and-govern-apis-with-service-catalog/
discovery_support: true
bindable_entities: "APIs"
---

The AWS API Gateway integration allows you to associate your Service Catalog service with one or more AWS API Gateway APIs.

{% include /service-catalog/multi-resource.md %}

For complete tutorials, see the following:
* [Discover and govern APIs with Service Catalog](/how-to/discover-and-govern-apis-with-service-catalog/)
* [Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} API](/how-to/discover-aws-gateway-apis-using-konnect-api/)
* [Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} UI](/how-to/discover-aws-gateway-apis-using-konnect-ui/)

## Configure an IAM role in AWS for Service Catalog

{% include /prereqs/service-catalog-iam.md %}

## Authorize the AWS API Gateway integration

1. In the {{site.konnect_short_name}} sidebar, click **Service Catalog**.
1. In the Service Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **AWS API Gateway**.
1. Click **Add AWS API Gateway instance**.
1. From the **AWS region** dropdown, select your AWS region.
1. In the **IAM role ARN** field, enter the [IAM role you configured for Service Catalog](#configure-an-iam-role-in-aws-for-service-catalog).
1. In the **Display name** field, enter a name for your AWS API Gateway instance.
1. In the **Instance name** field, enter a unique identifier for your AWS API Gateway instance.
1. Click **Save**. 

## Resources

Available AWS API Gateway entities:

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