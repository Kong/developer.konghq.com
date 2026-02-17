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
automated_tests: false
tldr:
  q: How do I configure an Azure Dedicated Cloud Gateway with VNET peering and private DNS?
  a: blah
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
prereqs:
  skip_product: true
  inline:
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
    - title: Azure Virtual Network
      content: |
        To configure VNET peering in {{site.konnect_short_name}}, you'll need a [virtual network configured in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/quickstart-create-virtual-network?tabs=portal). 

        Copy and export the following:
        ```sh
        export VNET_SUBSCRIPTION_ID='YOUR VNET SUBSCRIPTION ID'
        export RESOURCE_GROUP_NAME='RESOURCE GROUP NAME FOR YOUR VNET'
        export RESOURCE_GROUP_ID='RESOURCE GROUP ID FOR YOUR VNET'
        export VNET_NAME='YOUR VNET NAME'
        ```

next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

{% include_cached /sections/azure-peering.md %}

## Create an Azure Dedicated Cloud Gateway

{% include_cached /sections/azure-dcgw-network-setup.md %}

## Configure VNET peering in {{site.konnect_short_name}}

{% include_cached /sections/azure-dcgw-vnet-peering-setup.md %}

## Create a private DNS zone in Azure

Configuring Azure private DNS for Dedicated Cloud Gateways involves creating a private DNS zone in Azure, linking the private DNS zone to your Virtual Network, and configuring a private hosted zone in {{site.konnect_short_name}}.

1. [Create a private DNS zone in Azure](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#create-a-private-dns-zone) in the same resource group as your Virtual Network you're using for VNET peering.
1. Export the following variables for your private DNS zone:
   ```sh
   export YOUR_DOMAIN='YOUR PRIVATE DNS DOMAIN NAME'
   export PRIVATE_DNS_ZONE_NAME='YOUR PRIVATE DNS ZONE NAME'
   ```
1. Create a DNS link creator role with the Azure CLI::
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
           "/subscriptions/$VNET_SUBSCRIPTION_ID",
       ]
   }'
   ```
1. Assign the role to the service principal so it has permission to peer with your virtual network with the Azure CLI:
   ```sh
   az role assignment create \
    --role "Kong Cloud Gateway DNS Link Creator - Kong" \
    --assignee "$(az ad sp list --filter "appId eq '54aeca8a-ec61-4737-9a1a-99ca4fed32da'" --output tsv --query '[0].id')" \
    --scope "/subscriptions/$RESOURCE_GROUP_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Network/privateDnsZones/$YOUR_DOMAIN"
   ```

   Be sure to replace the following:
   * `$SERVICE_PRINCIPAL_APP_ID`: The [service principal ID](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-view-managed-identity-service-principal?pivots=identity-mi-service-principal-portal) that is used by VNET peering.
   * `$RESOURCE_GROUP_ID`: Your resource group subscription ID. To get this value, in the Azure portal, navigate to **Resource groups** in the sidebar. Click your resource group where your private DNS zone is located and copy the Subscription ID.
   * `$RESOURCE_GROUP_NAME`: The name of your resource group.
   * `$YOUR_DOMAIN`: The domain name you entered in your Azure private DNS zone.

1. [Link your private DNS zone to your Virtual Network](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#link-the-virtual-network) using the command provided by the private DNS wizard in the UI:
   ```sh
   az network private-dns link vnet create \
   --name $VNET_LINK_NAME \
   --resource-group $RESOURCE_GROUP_NAME \
   --zone-name $PRIVATE_DNS_ZONE_NAME \
   --virtual-network $VNET_NAME \
   --registration-enabled false
   ```

   Be sure to replace the following:
   * `$VNET_LINK_NAME`: The name you want to use for your Virtual Network link.
   * `$RESOURCE_GROUP_NAME`: The name of your resource group.
   * `$PRIVATE_DNS_ZONE_NAME`: The name of your private DNS zone.
   * `$VNET_NAME`: The name of your Virtual Network.

## Configure private DNS for your Azure network in {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private DNS".
1. Click **Private hosted zone**.
1. In the **Name** field, enter a name for your private hosted zone.
1. In the **Tenant ID** field, enter your [tenant ID from Microsoft Entra](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
1. In the **Subscription ID** field, enter the subscription ID for your private DNS zone.
1. In the **Resource group ID** field, enter the resource group ID that your private DNS zone is in.
1. In the **VNet link name** field, enter the name of the Virtual Network link.
1. Select **I confirm that I completed all required steps and understand that incorrect configuration can cause DNS resolution issues.**
1. Click **Done**.

## Validate

Once your private DNS configuration displays as ready, you can begin using your Dedicated Cloud Gateway. To verify that it's ready, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. Scroll until you see `Ready` for private DNS.