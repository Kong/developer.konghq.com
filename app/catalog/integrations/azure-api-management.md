---
title: "Azure API management"
content_type: reference
layout: reference

products:
    - catalog
    - gateway
    
tags:
  - integrations
  - azure

breadcrumbs:
  - /catalog/
  - /catalog/integrations/
search_aliases:
  - service catalog
works_on:
    - konnect
description: placeholder

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
discovery_support: true
bindable_entities: "APIs"
---

The Azure API Management integration allows you to associate your {{site.konnect_catalog}} service with one or more Azure API Management APIs.

{% include /catalog/multi-resource.md %}

For complete tutorials, see the following:
* [Discover Azure API Management APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} API](/how-to/discover-azure-apis-with-konnect-api/)
* [Discover Azure API Management APIs in {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI](/how-to/discover-azure-apis-with-konnect-ui/)

## Prerequisites

Before you configure the Azure API Management integration, ensure the following:

* You have an [API in Azure API Management](https://learn.microsoft.com/azure/api-management/add-api-manually) and the subscription ID for the API.
* Your Azure email account is associated with an [Azure organization](https://learn.microsoft.com/azure/devops/organizations/accounts/create-organization?view=azure-devops). Personal Azure accounts aren't supported for this integration.

## Authorize the Azure API Management integration

{:.info}
> **Note:** The Azure API Management integration uses OAuth for authentication and can only be configured through the {{site.konnect_short_name}} UI.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **Azure API Management**.
1. Click **Add Azure API Management instance**.
1. In the **Subscription ID** field, enter your Azure API subscription ID.
1. Click **Submit configuration**.
1. In the **Add authorization** section, click **Authorize in Azure API Management**.
1. Click **Authorize** to authenticate with Azure using OAuth.
1. In the **Display name** field, enter a name for your Azure API Management instance.
1. In the **Instance name** field, enter a unique identifier for your Azure API Management instance.
1. Click **Save**. 

## Resources

Available Azure API Management entities:

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: API
    description: An Azure API Management API that relates to the {{site.konnect_catalog}} service. Only HTTP specs can be added via the the **API Specs** tab on a service. gRPC, WebSocket, and GraphQL specifications aren't supported.
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