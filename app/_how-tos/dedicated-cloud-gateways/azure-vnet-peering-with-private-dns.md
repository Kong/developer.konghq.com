---
title: Configure an Azure Dedicated Cloud Gateway with VNET peering and private DNS
description: 'Learn how to configure an Azure Dedicated Cloud Gateway with VNET peering and private DNS.'
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-vnet-peering-with-private-dns/
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
  q: How do I configure an Azure Dedicated Cloud Gateway with VNET peering and private DNS?
  a: After you configure a virtual network, virtual network link, and private DNS zone in Azure, you can create a Dedicated Cloud Gateway in {{site.konnect_short_name}} with Azure as the network provider. When the Azure network is `Ready` in {{site.konnect_short_name}}, you can configure VNET peering by creating the peering role and assigning it to the service principal. Configure private DNS for your Azure network in {{site.konnect_short_name}}. You can use your Azure Dedicated Cloud Gateway after it displays as `Ready` for your private hosted zone.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Configure an Azure Dedicated Cloud Gateway with VNET peering
    url: /dedicated-cloud-gateways/azure-peering/
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

        Copy and export your Entra tenant ID from your dashboard:
        ```sh
        export TENANT_ID='YOUR TENANT ID'
        ```
    - title: Microsoft Azure CLI
      content: |
        [Install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and authenticate:
        ```sh
        az login
        ```
      icon_url: /assets/icons/azure.svg
    - title: Azure virtual network
      include_content: prereqs/dcgw-azure-vnet
      icon_url: /assets/icons/azure.svg
    - title: Azure private DNS zone
      content: |
        Configuring Azure private DNS for Dedicated Cloud Gateways involves creating a private DNS zone in Azure, linking the private DNS zone to your virtual network, and configuring a private hosted zone in {{site.konnect_short_name}}.

        1. [Create a private DNS zone in Azure](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#create-a-private-dns-zone) in the same resource group as the virtual network that you're using for VNET peering.
        1. Export the following variables for your private DNS zone:
          ```sh
          export YOUR_DOMAIN='YOUR PRIVATE DNS DOMAIN NAME'
          export PRIVATE_DNS_ZONE_NAME='YOUR PRIVATE DNS ZONE NAME'
          export PRIVATE_DNS_SUBSCRIPTION_ID='YOUR PRIVATE DNS ZONE SUBSCRIPTION ID'
          export PRIVATE_DNS_RESOURCE_GROUP_NAME='YOUR PRIVATE DNS RESOURCE GROUP NAME'
          ```
      icon_url: /assets/icons/azure.svg
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


## Configure private DNS for your Azure network in {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private DNS".
1. Click **Private hosted zone**.
1. In the **Name** field, enter the fully qualified domain name for your private hosted zone in Azure.
1. In the **Tenant ID** field, enter your [tenant ID from Microsoft Entra](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
1. In the **Subscription ID** field, enter the subscription ID for your private DNS zone.
1. In the **Resource group ID** field, enter the resource group ID that your private DNS zone is in.
1. In the **VNet link name** field, enter the name of the virtual network link.
1. Create a DNS link creator role with the Azure CLI:
   ```sh
   az role definition create --output none --role-definition '{
       "Name": "Kong Cloud Gateway DNS Link Creator - Kong",
       "Description": "Perform cross-tenant network peering.",
       "Actions": [
           "Microsoft.Network/virtualNetworks/read",
           "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
           "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
           "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
           "Microsoft.Network/virtualNetworks/peer/action"
       ],
       "AssignableScopes": [
           "/subscriptions/$PRIVATE_DNS_SUBSCRIPTION_ID",
       ]
   }'
   ```
1. Assign the role to the service principal so it has permission to peer with your virtual network with the Azure CLI:
   ```sh
   az role assignment create \
    --role "Kong Cloud Gateway DNS Link Creator - Kong" \
    --assignee "$(az ad sp list --filter "appId eq '54aeca8a-ec61-4737-9a1a-99ca4fed32da'" --output tsv --query '[0].id')" \
    --scope "/subscriptions/$PRIVATE_DNS_SUBSCRIPTION_ID/resourceGroups/$PRIVATE_DNS_RESOURCE_GROUP_NAME/providers/Microsoft.Network/privateDnsZones/$YOUR_DOMAIN"
   ```

1. [Link your private DNS zone to your virtual network](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#link-the-virtual-network) using the command provided by the private DNS wizard in the UI:
   ```sh
   az network private-dns link vnet create \
   --name $VNET_LINK_NAME \
   --resource-group $PRIVATE_DNS_RESOURCE_GROUP_NAME \
   --zone-name $PRIVATE_DNS_ZONE_NAME \
   --virtual-network $VNET_NAME \
   --registration-enabled false
   ```

   Be sure to replace `$VNET_LINK_NAME` with the name you want to use for your virtual network link.
1. Select **I confirm that I completed all required steps and understand that incorrect configuration can cause DNS resolution issues.**
1. Click **Connect**.

## Validate

Once your private DNS configuration displays as ready, you can begin using your Dedicated Cloud Gateway. To verify that it's ready, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private DNS".
1. Scroll until you see `Ready` for private DNS.