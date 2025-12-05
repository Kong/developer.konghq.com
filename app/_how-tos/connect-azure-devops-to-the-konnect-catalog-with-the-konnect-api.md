---
title: Connect Azure DevOps repositories to Catalog with the Konnect API
content_type: how_to
description: Learn how to connect Azure DevOps repositories to your {{site.konnect_catalog}} services in {{site.konnect_short_name}} using the Konnect API.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations

search_aliases:
  - azure repos
  - devops
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Azure DevOps reference
    url: /catalog/integrations/azure-devops/
  - text: "Connect Azure DevOps repositories to Catalog with the Konnect UI"
    url: /how-to/connect-azure-devops-with-konnect-ui/
automated_tests: false
tldr:
  q: How do I connect Azure DevOps to {{site.konnect_short_name}} using the API?
  a: Use the Konnect Integrations API to create and authorize an Azure DevOps integration instance with your organization name and PAT, then map an ingested repository to a {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: Create and configure an Azure account
      content: |
        You need to configure the following in Azure DevOps:
        - An [Azure DevOps account](https://azure.microsoft.com/en-gb/pricing/purchase-options/azure-account?icid=devops).
        - An [Azure DevOps personal access token (PAT)](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) with `Code: Read` permission.
        
        {:.warning}
        > Your PAT expires after one year. Make sure that you renew it when it expires.

---

## Configure the Azure DevOps integration

Before you can discover Azure DevOps repositories in Catalog, you must configure the integration:

{% konnect_api_request %}
url: /v1/integration-instances
status_code: 201
method: POST
body:
  integration_name: "azure-devops"
  name: "azure-devops"
  display_name: "Azure DevOps"
  config:
    organization: "kong-konnect"
{% endkonnect_api_request %}

Export the ID of your Azure DevOps integration:

```sh
export AZUREDEVOPS_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the integration with your Azure DevOps PAT:

{% konnect_api_request %}
url: /v1/integration-instances/$AZUREDEVOPS_INTEGRATION_ID/auth-credential
status_code: 201
method: POST
body:
  type: multi_key_auth
  config:
    headers:
      - name: authorization
        key: $AZUREDEVOPS_PAT
{% endkonnect_api_request %}

Once authorized, resources from your Azure DevOps account are discoverable in the UI.

## Create a Service in Catalog

Create a service to map to your Azure DevOps resources:

{% konnect_api_request %}
url: /v1/catalog-services
status_code: 201
method: POST
body:
  name: "user-service"
  display_name: "User Service"
{% endkonnect_api_request %}

Export the service ID:

```sh
export AZUREDEVOPS_SERVICE_ID="YOUR-SERVICE-ID"
```

## List Azure Dev Ops resources

Before you map Azure DevOps resources to a service in Catalog, locate the resources that {{site.konnect_short_name}} ingests from Azure DevOps:

{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=azure-devops
status_code: 200
method: GET
{% endkonnect_api_request %}

 If you don't immediately see resources, try manually syncing your Azure DevOps integration. From the {{site.konnect_short_name}} UI, navigate to the Azure DevOps integration that you just installed. Then, from the  **Actions** dropdown menu, select **Sync Now**.

Export the resource ID you want to map to the service:

```sh
export AZUREDEVOPS_RESOURCE_ID="YOUR-RESOURCE-ID"
```

## Map resources to a service

Now, map the Azure DevOps resource to the service:

{% konnect_api_request %}
url: /v1/resource-mappings
status_code: 201
method: POST
body:
  service: $AZUREDEVOPS_SERVICE_ID
  resource: $AZUREDEVOPS_RESOURCE_ID
{% endkonnect_api_request %}

## Validate the mapping

To confirm that the Azure DevOps resource is now mapped to the intended service, list the service’s mapped resources:

{% konnect_api_request %}
url: /v1/catalog-services/$AZUREDEVOPS_SERVICE_ID/resources
status_code: 200
method: GET
{% endkonnect_api_request %}