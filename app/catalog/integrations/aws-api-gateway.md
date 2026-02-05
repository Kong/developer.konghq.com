---
title: "AWS API Gateway"
content_type: reference
layout: reference

products:
    - catalog
    - gateway
    
tags:
  - integrations
  - aws

breadcrumbs:
  - /catalog/
  - /catalog/integrations/
search_aliases:
  - service catalog
works_on:
    - konnect
description: The AWS API Gateway integration allows you to associate your {{site.konnect_catalog}} service with one or more AWS API Gateway APIs. 

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Import and map AWS API Gateway resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-aws-gateway-apis/
  - text: "Discover AWS Gateway APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/discover-aws-gateway-apis-using-konnect-api/
  - text: "Discover AWS Gateway APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI"
    url: /how-to/discover-aws-gateway-apis-using-konnect-ui/
  - text: Discover and govern APIs with {{site.konnect_catalog}}
    url: /how-to/discover-and-govern-apis-with-service-catalog/
discovery_support: true
bindable_entities: "APIs"
---

The AWS API Gateway integration allows you to associate your {{site.konnect_catalog}} service with one or more AWS API Gateway APIs.

{% include /catalog/multi-resource.md %}

For complete tutorials, see the following:
* [Discover and govern APIs with {{site.konnect_catalog}}](/how-to/discover-and-govern-apis-with-service-catalog/)
* [Discover AWS Gateway APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} API](/how-to/discover-aws-gateway-apis-using-konnect-api/)
* [Discover AWS Gateway APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI](/how-to/discover-aws-gateway-apis-using-konnect-ui/)

## Configure an IAM role in AWS for {{site.konnect_catalog}}

{% include /prereqs/service-catalog-iam.md %}

## Authorize the AWS API Gateway integration

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **AWS API Gateway**.
1. Click **Add AWS API Gateway instance**.
1. From the **AWS region** dropdown, select your AWS region.
1. In the **IAM role ARN** field, enter the [IAM role you configured for {{site.konnect_catalog}}](#configure-an-iam-role-in-aws-for-service-catalog).
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
    description: An AWS API Gateway API that relates to the {{site.konnect_catalog}} service.
{% endtable %}
<!--vale on-->


## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->