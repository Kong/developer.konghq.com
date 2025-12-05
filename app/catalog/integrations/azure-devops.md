---
title: "Azure DevOps"
content_type: reference
layout: reference
icon: /assets/icons/third-party/azuredevops.png

products:
  - catalog
  - gateway

tags:
  - integrations

search_aliases:
  - service catalog
breadcrumbs:
  - /catalog/
  - /catalog/integrations/

works_on:
    - konnect
description: "description: Provides information about the Azure DevOps integration, which lets the Konnect Catalog read repository metadata from Azure DevOps and use it for service mapping and governance workflows."


related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "Connect Azure DevOps repositories to Catalog with the Konnect API"
    url: /how-to/connect-azure-devops-to-the-konnect-catalog-with-the-konnect-api/
  - text: "Connect Azure DevOps repositories to Catalog with the Konnect UI"
    url: /how-to/connect-azure-devops-to-the-konnect-catalog-with-the-konnect-ui/
---

The Azure DevOps integration lets Konnect Catalog securely read and ingest repository metadata from Azure DevOps using a PAT with `Code:Read` access. Teams can reference and manage their source-code assets inside {{site.konnect_catalog}} and prepare for future governance and scorecard workflows.

For a complete tutorial, choose one of the following:
- [Connect Azure DevOps repositories to Catalog with the Konnect API](/how-to/connect-azure-devops-to-the-konnect-catalog-with-the-konnect-api/)
- [Connect Azure DevOps repositories to Catalog with the Konnect UI](/how-to/connect-azure-devops-to-the-konnect-catalog-with-the-konnect-ui/)

### Prerequisites
You need to configure the following:
- An [Azure DevOps account](https://azure.microsoft.com/en-gb/pricing/purchase-options/azure-account?icid=devops)
- An [Azure DevOps personal access token (PAT)](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) with `Code:Read` permission.

### Configure the integration
{% navtabs "azure-devops-integration" %}
{% navtab "UI" %}

1. In the Konnect sidebar, click **Catalog**.
1. In the Catalog sidebar, click **Integrations**.
1. Click **Azure DevOps**.
1. Click **Add Azure DevOps instance**.
1. In the **Azure DevOps organization name** field, enter your organization name exactly as it is in Azure DevOps.
1. In the **Azure DevOps personal access token (PAT)** field, enter your Azure DevOps token.
1. (Optional) In the **Description** field, enter a description for this instance.
1. Click **Save**.

{% endnavtab %}
{% navtab "API" %}

[insert]

{% endnavtab %}
{% navtab "Terraform" %}

[insert]

{% endnavtab %}
{% endnavtabs %}

For additional Azure DevOps resources, use the following table:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "OAuth 2.0 Scopes"
    description: "Define and control the specific resources an OAuth application can access in Azure DevOps by requesting granular scopes."
  - entity: "Personal Access Tokens (PATs)"
    description: "Authenticate with Azure DevOps by generating a time-limited token that grants scoped access, follow least-privilege practices by selecting only required permissions, and store the token securely to prevent misuse."
{% endtable %}


## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->