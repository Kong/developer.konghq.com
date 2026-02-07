---
title: "Discover Azure API Management APIs in Catalog with the {{site.konnect_short_name}} UI"
permalink: /how-to/discover-azure-apis-with-konnect-ui/
content_type: how_to
description: Learn how to connect an Azure API Management API to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the UI.
products:
  - catalog
works_on:
  - konnect
tags:
  - integrations
  - azure
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Azure API Management reference
    url: /catalog/integrations/azure-api-management/
  - text: "Discover Azure API Management APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/discover-azure-apis-with-konnect-api/
automated_tests: false
tldr:
  q: How do I discover Azure API Management APIs in {{site.konnect_short_name}}?
  a: Install the Azure API Management integration in {{site.konnect_short_name}} and authorize access with OAuth, then link an Azure API to your {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: Azure API Management
      content: |
        * You have an [API in Azure API Management](https://learn.microsoft.com/azure/api-management/add-api-manually) and the subscription ID for the API.
        * Your Azure email account is associated with an [Azure organization](https://learn.microsoft.com/azure/devops/organizations/accounts/create-organization?view=azure-devops). Personal Azure accounts aren't supported for this integration.
      icon_url: /assets/icons/azure.svg
---

## Configure the Azure API Management integration

{:.info}
> **Note:** The Azure API Management integration uses OAuth for authentication and can only be configured through the {{site.konnect_short_name}} UI.

Before you can discover APIs in {{site.konnect_catalog}}, you must configure the Azure API Management integration.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **Azure API Management**.
1. Click **Add Azure API Management instance**.
1. In the **Subscription ID** field, enter your Azure API subscription ID.
1. Click **Submit configuration**.
1. In the **Add authorization** section, click **Authorize in Azure API Management**.
1. Click **Authorize** to authenticate with Azure using OAuth.
1. In the Azure authorization window, click **Accept**. 
1. In the **Display name** field, enter `azure-api-management-test`.
1. In the **Instance name** field, enter `azure-api-management-test`.
1. Click **Save**. 

## Create a {{site.konnect_catalog}} service and map the API resources

Now that your integration is configured, you can create a {{site.konnect_catalog}} service to map the ingested APIs.

{:.info}
> In this tutorial, we'll refer to your ingested Azure API Management API as `billing-api`.

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the Catalog sidebar, click **Services**.
1. Click **New service**.
1. In the **Display Name** field, enter `Billing Service`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select `billing-api`. 
1. Click **Map 1 Resource**.

Your integration APIs are now discoverable from one {{site.konnect_catalog}} service.

{:.info}
> You might need to manually sync your Azure API Management integration for resources to appear. In the {{site.konnect_short_name}} UI, by navigate to the Azure API Management integration you just installed and select **Sync Now** from the **Actions** dropdown menu.

## Validate the mapping

To confirm that the Azure API Management resource is now mapped to the intended service, navigate to the service:

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click the **Billing Service** service.
1. Click the **Resources** tab.

You should see the `billing-api` resource listed.