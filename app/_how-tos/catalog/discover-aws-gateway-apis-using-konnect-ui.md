---
title: Discover AWS Gateway APIs in Catalog with the Konnect UI
permalink: /how-to/discover-aws-gateway-apis-using-konnect-ui/
content_type: how_to
description: Learn how to connect an AWS Gateway API to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the UI.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - aws
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: AWS API Gateway reference
    url: /catalog/integrations/aws-api-gateway/
  - text: "Discover AWS Gateway APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/discover-aws-gateway-apis-using-konnect-api/
  - text: Discover and govern APIs with {{site.konnect_catalog}}
    url: /how-to/discover-and-govern-apis-with-service-catalog/
automated_tests: false
tldr:
  q: How do I discover AWS API Gateway API in {{site.konnect_short_name}}?
  a: Install the AWS API Gateway integration in {{site.konnect_short_name}} and authorize access with your {{site.konnect_catalog}} role ARN, then link an API to your {{site.konnect_catalog}} service.
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

Before you can discover APIs in {{site.konnect_catalog}}, you must configure the AWS API Gateway integration.

{% include /catalog/aws-api-gateway-integration.md %}

## Create a {{site.konnect_catalog}} service and map the API resources

Now that your integration is configured, you can create a {{site.konnect_catalog}} service to map the ingested APIs.

{:.info}
> In this tutorial, we'll refer to your ingested AWS API Gateway API as `aws-api`.

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the Catalog sidebar, click **Services**.
1. Click **New service**.
1. In the **Display Name** field, enter `APIs`.
1. In the **Name** field, enter `apis`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select `aws-api`. 
1. Click **Map 1 Resource**.

Your integration APIs are now discoverable from one {{site.konnect_catalog}} service.

{:.info}
> You might need to manually sync your AWS API Gateway integration for resources to appear. In the {{site.konnect_short_name}} UI, by navigate to the AWS API Gateway integration you just installed and select **Sync Now** from the **Actions** dropdown menu.

## Validate the mapping

To confirm that the AWS API Gateway resource is now mapped to the intended service, navigate to the service:

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click the **APIs** service.
1. Click the **Resources** tab.

You should see the `aws-api` resource listed.
