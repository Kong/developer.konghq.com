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
