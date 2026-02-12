---
title: Connect Azure DevOps repositories to Catalog with the {{site.konnect_short_name}} API
permalink: /how-to/connect-azure-devops-to-the-konnect-catalog-with-the-konnect-api/
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
        1. You need to configure the following in Azure DevOps:
            - An [Azure DevOps account](https://azure.microsoft.com/en-gb/pricing/purchase-options/azure-account?icid=devops).
            - An [Azure DevOps personal access token (PAT)](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) with `Code:Read` permission.

           {:.warning}
           > Your PAT can be created with an expiration period of your choice, up to a maximum of one year. Make sure to renew the PAT before it expires to avoid interruptions.

        1. Set the personal access token as an environment variable:
           ```sh
           export AZUREDEVOPS_PAT='YOUR-AZURE-DEV-OPS-PERSONAL-ACCESS-TOKEN'
           ```
---

## Configure the Azure DevOps integration

Before you can discover Azure DevOps repositories in {{site.konnect_catalog}}, export your Azure DevOps organization name exactly as it appears in Azure DevOps:

```sh
export AZURE_DEVOPS_ORG_NAME="YOUR-ORG-NAME"
```

Now, configure the integration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances
status_code: 201
method: POST
body:
  integration_name: "azure-devops"
  name: "azure-devops"
  display_name: "Azure DevOps"
  config:
    organization: "$AZURE_DEVOPS_ORG_NAME"
extract_body:
    - name: 'id'
      variable: AZUREDEVOPS_INTEGRATION_ID
capture: AZUREDEVOPS_INTEGRATION_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Next, authorize the integration with your Azure DevOps PAT:

<!--vale off-->
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
<!--vale on-->

Once authorized, resources from your Azure DevOps account are discoverable in the UI.

## Create a Service in Catalog

Create a service to map to your Azure DevOps resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services
status_code: 201
method: POST
body:
  name: "user-service"
  display_name: "User Service"
extract_body:
    - name: 'id'
      variable: AZUREDEVOPS_SERVICE_ID
capture: AZUREDEVOPS_SERVICE_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## List Azure DevOps resources

Before you map Azure DevOps resources to a service in Catalog, locate the resources that {{site.konnect_short_name}} ingests from Azure DevOps:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=azure-devops
status_code: 200
method: GET
extract_body:
    - name: 'id'
      variable: AZUREDEVOPS_RESOURCE_ID
capture: AZUREDEVOPS_RESOURCE_ID
jq: ".data[0].id"
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> {{site.konnect_short_name}} uses the first resource in the list when you run this command. To select a different resource, replace `.data[0].id` in the `jq` filter with the index of the resource you want to use or manually specify the resource ID.

## Map resources to a service

Now, map the Azure DevOps resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
status_code: 201
method: POST
body:
  service: $AZUREDEVOPS_SERVICE_ID
  resource: $AZUREDEVOPS_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate the mapping

To confirm that the Azure DevOps resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$AZUREDEVOPS_SERVICE_ID/resources
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->