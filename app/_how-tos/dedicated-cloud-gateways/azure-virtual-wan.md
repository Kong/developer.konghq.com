---
title: Configure an Azure Dedicated Cloud Gateway with virtual WAN
description: 'Learn how to configure an Azure Dedicated Cloud Gateway with virtual WAN.'
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-virtual-wan/
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
  q: How do I configure an Azure Dedicated Cloud Gateway with virtual WAN?
  a: |
    Create a Dedicated Cloud Gateway in {{site.konnect_short_name}} with Azure as the network provider. 
    When the Azure network is `Ready` in {{site.konnect_short_name}}, you can configure virtual hub peering by creating the peering role and assigning it to the service principal. 
    You can use your Azure Dedicated Cloud Gateway after it displays as `Ready` for virtual hub peering.
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
    - title: Azure virtual WAN
      content: |
        To configure virtual hub peering in {{site.konnect_short_name}}, you'll need a [virtual network configured in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/quickstart-create-virtual-network?tabs=portal) that is associated with a [virtual WAN](https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-site-to-site-portal#openvwan). 

        Copy your virtual WAN subscription ID, resource group name, and virtual WAN name.

        {:.danger}
        > **Important:** Your Azure virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited. The Azure virtual network and virtual WAN must also use CIDRs that don't overlap.
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---
{% include_cached /sections/azure-peering.md %}

## Create an Azure Dedicated Cloud Gateway

{% include_cached /sections/azure-dcgw-network-setup.md %}

## Configure Azure virtual hub peering in {{site.konnect_short_name}}

Now that your Dedicated Cloud Gateway Azure network is ready, you can configure virtual hub peering to connect your Azure virtual WAN to your Dedicated Cloud Gateway.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private networking".
1. In the **Tenant ID** field, enter [your Microsoft Entra tenant ID](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
1. In the **Subscription ID** field, enter your virtual WAN's subscription ID.
1. In the **Resource group name** field, enter your virtual WAN's resource group name.
1. In the **Virtual hub name** field, enter your virtual WAN's name.
1. Click **Next**.
1. Grant access to the Dedicated Cloud Gateway app in Microsoft Entra using the link provided in the setup wizard.
   
   {:.warning}
   > **Important:** You need an admin account to approve the app.
1. Create a peering role with the Azure CLI using the command in the UI wizard.

   {{site.konnect_short_name}} requires permission to create and manage peering resources. You must define a role named `Kong Cloud Gateway Peering Creator` with the following permissions:

    * Read and write access to virtual WAN configurations
    * Permission to perform peering actions

1. Assign the role to the service principal so it has permission to peer with your virtual WAN using the command in the UI wizard.
1. Select **I've completed the Azure setup steps above.**
1. Click **Done**.

## Validate

After your VNET peering configuration displays as ready, you can begin using your Dedicated Cloud Gateway. To verify that it's ready, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. Scroll until you see `Ready` for virtual hub peering.