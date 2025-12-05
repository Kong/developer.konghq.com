---
title: Connect Azure DevOps repositories to Catalog with the konnect UI
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
  q: How do I connect Azure DevOps repositories to {{site.konnect_short_name}}?
  a: Install the Azure DevOps integration in {{site.konnect_short_name}}, authorize it with a Personal Access Token (PAT) that has Code:Read access, then map an Azure DevOps repository to your {{site.konnect_catalog}} service.
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
        > Your PAT expires after one year. Make sure that you renew it after it expires.
---

## Configure the Azure DevOps integration

Before you can discover Azure DevOps repositories in Catalog, you must configure the integration:

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the {{site.konnect_catalog}} sidebar, click **Integrations**.
1. Click **Azure DevOps**.
1. Click **Add Azure DevOps instance**.
1. In the **Azure DevOps organization name** field, enter your organization name exactly as it is in Azure DevOps.
1. In the **Azure DevOps personal access token (PAT)** field, enter your Azure DevOps token.
1. (Optional) In the **Description** field, enter a description for this instance.
1. Click **Save**.

## Create a catalog service and map the Azure DevOps resources

After you configure the Azure DevOps integration, create a service in Catalog and link it to a repository from your Azure DevOps organization. This associates the service with its source code location and uses that repository as a system of record.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click **New service**.
1. In the **Display Name** field, enter `user-service`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select `user-service`.

## Validate the mapping
To confirm that the Azure DevOps resource is now mapped to the intended service, navigate to the new service:
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click the `user-service` service.
1. Click the **Resources** tab.

You'll see the `user-service` resource listed.