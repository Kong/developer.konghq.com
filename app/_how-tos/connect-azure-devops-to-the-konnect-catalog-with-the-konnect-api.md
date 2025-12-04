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
  - azure-devops
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
        {:.info}
        > Your PAT expires after one year. Make sure that you renew it after it expires.
---

## Configure the Azure DevOps integration

Before you can discover Azure DevOps repositories in Catalog, you must configure the integration:

[insert codeblock]

Export the ID of your Azure DevOps integration:

[insert codeblock]

Next, authorize the integration with your Azure DevOps PAT:

[insert codeblock]

Once authorized, resources from your Azure DevOps account will be discoverable in the UI.

## Create a Service in Catalog

Create a service that you’ll map to your Azure DevOps resources:

[insert codeblock]

Export the service ID:

[insert codeblock]

## List Azure Dev Ops resources

Before you can map your Azure DevOps resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from Azure DevOps:

[insert codeblock]

{:.info}
> If you don't immediately see resources, you might need to manually sync your Azure DevOps integration. From the {{site.konnect_short_name}} UI, navigate to the Azure DevOps integration that you just installed. Then, from the  **Actions** dropdown menu, select **Sync Now**.

Export the resource ID you want to map to the service:

[insert codeblock]

## Map resources to a service

Now, map the Azure DevOps resource to the service:

[insert codeblock]

## Validate the mapping

To confirm that the Azure DevOps resource is now mapped to the intended service, list the service’s mapped resources:

[insert codeblock]