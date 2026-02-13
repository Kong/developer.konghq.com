---
title: "Azure peering"
content_type: reference
layout: reference
description: | 
    {{site.konnect_short_name}} can leverage Azure to create virtual networks, and ingest data from your Azure services and expose them to the internet via {{site.konnect_short_name}}. 


products:
    - gateway
works_on:
    - konnect
api_specs:
    - konnect/control-planes-config

breadcrumbs:
  - /dedicated-cloud-gateways/

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
tags:
  - azure
  - security
---



When you deploy Dedicated Cloud Gateway in {{site.konnect_short_name}}, {{site.konnect_short_name}} hosts the Data Plane Nodes on Azure. Then, you can use [Azure virtual network peering](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview) to establish a secure, low-latency connection between your Azure environment and the {{site.konnect_short_name}} platform.

{% include_cached /sections/azure-peering.md %}


## Azure configuration for VNET peering

To enable virtual network peering between your Azure environment and {{site.konnect_short_name}}, you must authorize {{site.konnect_short_name}} to access and configure the necessary Azure resources.

This process includes three main steps:

1. Authorize the {{site.konnect_short_name}} VNET Peering App in your Azure Tenant

    {{site.konnect_short_name}} uses a registered Azure application to create and manage peering connections. To authorize it:

    * You must grant admin consent to the `kong-cgw-azure-vnet-peering-app` for your tenant.
    * This is done by visiting a URL that includes your Azure Tenant ID:

    `https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id=207b296f-cf25-4d23-9eba-9a2c41dc62ca`


1. Define a Custom Role in Azure

    {{site.konnect_short_name}} requires permission to create and manage peering resources. You must define a role named `Kong Cloud Gateway Peering Creator` with the following permissions:

    * Read and write access to Virtual Network peering configurations
    * Permission to perform peering actions

    Use the Azure CLI to define the role, replacing `$SUBSCRIPTION-ID` with your Azure subscription ID:

    ```bash
    az role definition create --output none --role-definition '{
        "Name": "Kong Cloud Gateway Peering Creator",
        "Description": "Perform cross-tenant network peering.",
        "Actions": [
            "Microsoft.Network/virtualNetworks/read",
            "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
            "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
            "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
            "Microsoft.Network/virtualNetworks/peer/action"
        ],
        "AssignableScopes": [
            "/subscriptions/$SUBSCRIPTION-ID",
        ]
    }'
    ```

1. Assign the Role to the {{site.konnect_short_name}} Service Principal

    Once the role is created, assign it so it has permission to peer with your virtual network. Replace the values for `subscription-id`, `resource-group`, and `vnet-name`:

    ```bash
    az role assignment create \
        --role "Kong Cloud Gateway Peering Creator" \
        --assignee "$(az ad sp list --filter "appId eq '207b296f-cf25-4d23-9eba-9a2c41dc62ca'" \
        --output tsv --query '[0].id')" \
        --scope "/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Network/virtualNetworks/{vnet-name}"
    ```

### Konnect configuration for VNET peering

To configure peering in {{site.konnect_short_name}} you need to input the following values from Azure into the {{site.konnect_short_name}} UI for your Dedicated Cloud Gateway:

* Azure Tenant ID  
* Azure VNET Subscription ID  
* Azure VNET Resource Group Name  
* Azure VNET Name  

### DNS mappings


The following table describes how DNS is mapped in Azure VNET peering:

{% table %}
columns:
  - title: Mapping Type
    key: type
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - type: 1-to-1 Mapping
    description: Each domain is mapped to a unique IP address.
    example: "`example.com` → `192.168.1.1`"
  - type: N-to-1 Mapping
    description: Multiple domains share the same IP address.
    example: "`example.com`, `example2.com` → `192.168.1.1`"
  - type: M-to-N Mapping
    description: Multiple domains are mapped to multiple IP addresses, without a strict one-to-one relationship.
    example: >-
      `example.com` → `192.168.1.2`
      <br><br>
      `example3.com` → `192.168.1.1`
{% endtable %}

## Configure private DNS 

Configuring Azure private DNS for Dedicated Cloud Gateways involves creating a private DNS zone in Azure, linking the private DNS zone to your Virtual Network, and configuring a private hosted zone in {{site.konnect_short_name}}.

### Create a private DNS zone in Azure

1. [Create a private DNS zone in Azure](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#create-a-private-dns-zone) in the same resource group as your Virtual Network you're using for VNET peering.
1. Use the Azure CLI to assign the Private DNS Zone Contributor role to the same service principal as our VNET Peering:
   ```sh
   az role assignment create \
     --role "Private DNS Zone Contributor" \
     --assignee "$(az ad sp list --filter "appId eq '$SERVICE-PRINCIPAL-APP-ID'" \
     --output tsv --query '[0].id')" \
     --scope "/subscriptions/$RESOURCE-GROUP-ID/resourceGroups/$RESOURCE-GROUP-NAME/providers/Microsoft.Network/privateDnsZones/$YOUR-DOMAIN"
   ```

   Be sure to replace the following:
   * `$SERVICE-PRINCIPAL-APP-ID`: The [service principal ID](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-view-managed-identity-service-principal?pivots=identity-mi-service-principal-portal) that is used by VNET peering.
   * `$RESOURCE-GROUP-ID`: Your resource group subscription ID. To get this value, in the Azure portal, navigate to **Resource groups** in the sidebar. Click your resource group where your private DNS zone is located and copy the Subscription ID.
   * `$RESOURCE-GROUP-NAME`: The name of your resource group.
   * `$YOUR-DOMAIN`: The domain name you entered in your Azure private DNS zone.

1. [Link Private DNS to your VNET](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#link-the-virtual-network):
   ```sh
   az network private-dns link vnet create \
   --name $VNET-LINK-NAME \
   --resource-group $RESOURCE-GROUP-NAME \
   --zone-name $PRIVATE-DNS-ZONE-NAME \
   --virtual-network $VNET-NAME \
   --registration-enabled false
   ```
   NEED TO LIST THINGS TO REPLACE HERE

### Configure private DNS for your Azure network in {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. Click the action menu next to your Azure network and select "Configure private DNS".
1. Click **Private hosted zone**.
1. In the **Name** field, enter a name for your private hosted zone.
1. In the **Tenant ID** field, enter your [tenant ID from Microsoft Entra](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
1. In the **Subscription ID** field, enter the subscription ID for your Virtual Network.
1. In the **Resource group ID** field, enter the resource group ID that your private DNS zone is in.
1. In the **VNet link name** field, enter the name of the Virtual Network link.
1. probably more here too
1. Click **Next**.


<!-- 
"Outbound DNS resolver" needs more config steps for this that we don't have yet
1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. Click the action menu next to your Azure network and select "Configure private DNS".
1. Click **Outbound DNS resolver**.
1. In the **Outbound Resolver name** field, enter
1. In the **Domain name** field, enter
1. In the **Target IP address** field, enter
1. Click **Save**.
-->


