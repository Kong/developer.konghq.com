---
title: Configure an Azure Dedicated Cloud Gateway with VNET peering
description: 'Learn how to configure an Azure Dedicated Cloud Gateway with VNET peering.'
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-peering/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - konnect
works_on:
  - konnect
tags:
  - azure
  - network
automated_tests: false
tldr:
  q: How do I configure an Azure Dedicated Cloud Gateway with VNET peering?
  a: After you've configured a virtual network (VNET) in Azure, you can create a Dedicated Cloud Gateway in {{site.konnect_short_name}} with Azure as the network provider. When the Azure network is `Ready` in {{site.konnect_short_name}}, you can configure VNET peering by creating the peering role and assigning it to the service principal. You can use your Azure Dedicated Cloud Gateway after it displays as `Ready` for VNET peering.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Configure an Azure Dedicated Cloud Gateway with VNET peering and private DNS
    url: /dedicated-cloud-gateways/azure-vnet-peering-with-private-dns/
  - text: Configure an Azure Dedicated Cloud Gateway with VNET peering and outbound DNS resolution
    url: /dedicated-cloud-gateways/azure-vnet-peering-with-outbound-dns-resolver/
prereqs:
  show_works_on: false
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: Microsoft Entra
      content: |
        To approve the Dedicated Cloud Gateway app, you need a Microsoft Entra admin account with the [Application Administrator](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#application-administrator) role.

        Copy your Entra tenant ID from your dashboard.
    - title: Microsoft Azure CLI
      content: |
        [Install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and authenticate:
        ```sh
        az login
        ```
    - title: Azure virtual network
      content: |
        To configure VNET peering in {{site.konnect_short_name}}, you'll need a [virtual network configured in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/quickstart-create-virtual-network?tabs=portal). 

        Copy your virtual network subscription ID, resource group name, and virtual network name.

        {:.danger}
        > **Important:** Your Azure virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.
faqs:
  - q: "When I try to create the VNET peering role and assign the role to the service principal, I get the following errors: `(RoleDefinitionWithSameNameExists) A custom role with the same name already exists in this directory.` and `Role 'Kong Cloud Gateway Peering Creator - Kong' doesn't exist.`. How do I fix this?"
    a: |
      {% include faqs/azure-vnet-same-tenant-multi-subscription.md %}
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

{% include_cached /sections/azure-peering.md %}

## Create an Azure Dedicated Cloud Gateway

{% include_cached /sections/azure-dcgw-network-setup.md %}

## Configure VNET peering in {{site.konnect_short_name}}

{% include_cached /sections/azure-dcgw-vnet-peering-setup.md %}

## Validate

Once your VNET peering configuration displays as ready, you can begin using your Dedicated Cloud Gateway. To verify that it's ready, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. Scroll until you see `Ready` for VNET peering.