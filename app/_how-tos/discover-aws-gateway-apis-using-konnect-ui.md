---
title: Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} UI
content_type: how_to
description: Learn how to connect an AWS Gateway API to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the UI.
products:
  - service-catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - aws
related_resources:
  - text: Service Catalog
    url: /service-catalog/
  - text: Integrations
    url: /service-catalog/integrations/
  - text: AWS API Gateway reference
    url: /service-catalog/integrations/aws-api-gateway/
  - text: "Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} API"
    url: /how-to/discover-aws-gateway-apis-using-konnect-api/
  - text: Discover and govern APIs with Service Catalog
    url: /how-to/discover-and-govern-apis-with-service-catalog/
automated_tests: false
tldr:
  q: How do I discover AWS API Gateway API in {{site.konnect_short_name}}?
  a: Install the AWS API Gateway integration in {{site.konnect_short_name}} and authorize access with your Service Catalog role ARN, then link an API to your {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: AWS API Gateway
      include_content: prereqs/service-catalog-iam
      icon_url: /assets/icons/aws.svg
---

## Configure the AWS API Gateway integration

Before you can discover APIs in Service Catalog, you must configure the AWS API Gateway integration.

{% include /service-catalog/aws-api-gateway-integration.md %}

## Create a Service Catalog service and map the API resources

Now that your integration is configured, you can create a Service Catalog service to map the ingested APIs.

{:.info}
> In this tutorial, we'll refer to your ingested AWS API Gateway API as `aws-api`.

1. In the {{site.konnect_short_name}} sidebar, click [**Service Catalog**](https://cloud.konghq.com/service-catalog/).
1. Click **New service**.
1. In the **Display Name** field, enter `APIs`.
1. In the **Name** field, enter `apis`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select `aws-api`. 
1. Click **Map 1 Resource**.

Your integration APIs are now discoverable from one Service Catalog service.

{:.info}
> You might need to manually sync your AWS API Gateway integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the AWS API Gateway integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

## Validate the mapping

To confirm that the AWS API Gateway resource is now mapped to the intended service, navigate to the service:

1. In the {{site.konnect_short_name}} sidebar, click [**Service Catalog**](https://cloud.konghq.com/service-catalog/).
1. In the Service Catalog sidebar, click **Services**.
1. Click the **APIs** service.
1. Click the **Resources** tab.

You should see the `aws-api` resource listed.
