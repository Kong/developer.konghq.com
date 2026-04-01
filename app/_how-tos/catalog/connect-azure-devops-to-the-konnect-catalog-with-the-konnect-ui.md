---
title: Connect Azure DevOps repositories to Catalog with the {{site.konnect_short_name}} UI
permalink: /how-to/connect-azure-devops-to-the-konnect-catalog-with-the-konnect-ui/
content_type: how_to
description: Learn how to connect Azure DevOps repositories to your {{site.konnect_catalog}} services in {{site.konnect_short_name}} using the UI.
products:
  - catalog
works_on:
  - konnect
tags:
  - integrations
search_aliases:
  - devops
  - azure repos
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Azure DevOps reference
    url: /catalog/integrations/azure-devops/
  - text: "Connect Azure DevOps repositories to Catalog with the Konnect API"
    url: /how-to/connect-azure-devops-with-konnect-api/

automated_tests: false
tldr:
  q: How do I connect an Azure DevOps repository to a service in {{site.konnect_short_name}}?
  a: Configure the Azure DevOps integration with your organization name and PAT, create a {{site.konnect_catalog}} service, then map the discovered Azure DevOps repository resource to that {{site.konnect_catalog}} service.
prereqs:
  skip_product: true
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
        > Your PAT can be created with an expiration period of your choice, up to a maximum of one year. Make sure to renew the PAT before it expires to avoid interruptions.
---

## Configure the Azure DevOps integration

Before you can discover Azure DevOps repositories in {{site.konnect_catalog}}, you must configure the integration:

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the {{site.konnect_catalog}} sidebar, click **Integrations**.
1. Click **Azure DevOps**.
1. Click **Add Azure DevOps instance**.
1. In the **Azure DevOps organization name** field, enter your organization name exactly as it appears in Azure DevOps.
1. In the **Azure DevOps personal access token (PAT)** field, enter your Azure DevOps token.
1. In the **Display name** field, enter `azure-devops-repository-service`.
1. In the **Instance name** field, enter `azure-devops-repository-service`.
1. (Optional) In the **Description** field, enter a description for this instance.
1. Click **Save**.

If you don't immediately see resources, try manually syncing your Azure DevOps integration. From the {{site.konnect_short_name}} UI, navigate to the Azure DevOps integration that you just installed. Then, from the  **Actions** dropdown menu, select **Sync Now**.

## Create a {{site.konnect_catalog}} service and map the Azure DevOps resources

After you configure the Azure DevOps integration, create a service in {{site.konnect_catalog}} and map an Azure DevOps repository resource to it.

{:.info}
> In this tutorial, we’ll refer to your Azure DevOps repository as `azure-devops-repository`.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click **New service**.
1. In the **Display Name** field, enter `azure-devops-repository-service`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select the `azure-devops-repository` checkbox.
1. Click **Map 1 Resource**.

## Validate the mapping
To confirm that the Azure DevOps resource is now mapped to the intended service, navigate to the new service:
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click the `azure-devops-repository-service` service.
1. Click the **Resources** tab.

You'll see the `azure-devops-repository-service` resource listed.