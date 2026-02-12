---
title: "Discover Azure API Management APIs in Catalog with the {{site.konnect_short_name}} API"
permalink: /how-to/discover-azure-apis-with-konnect-api/
content_type: how_to
description: Learn how to connect an Azure API Management API to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the API.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
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
  - text: "Discover Azure API Management APIs with the {{site.konnect_short_name}} UI"
    url: /how-to/discover-azure-apis-with-konnect-ui/
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
        * An [API in Azure API Management](https://learn.microsoft.com/azure/api-management/add-api-manually) and the subscription ID for the API.
        * An Azure email account is associated with an [Azure organization](https://learn.microsoft.com/azure/devops/organizations/accounts/create-organization?view=azure-devops). Personal Azure accounts aren't supported for this integration.
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

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your Azure API Management resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services
method: POST
status_code: 201
region: us
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
<!--vale on-->

Export the service ID:
```sh
export AZURE_SERVICE_ID='YOUR-SERVICE-ID'
```

## List Azure API Management resources

Before you can map your Azure API Management resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from Azure API Management:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=azure-api-management
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your Azure API Management integration for resources to appear. In the {{site.konnect_short_name}} UI, by navigate to the Azure API Management integration you just installed and select **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:
```sh
export AZURE_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the Azure API Management resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $AZURE_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the Azure API Management resource is now mapped to the intended service, list the service's mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$AZURE_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->