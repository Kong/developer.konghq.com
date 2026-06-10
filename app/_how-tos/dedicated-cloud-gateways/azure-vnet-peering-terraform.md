---
title: Configure an Azure Dedicated Cloud Gateway with VNET peering using Terraform
description: 'Use Terraform to configure an Azure Dedicated Cloud Gateway with VNET peering.'
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-vnet-peering-terraform/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - konnect
works_on:
  - konnect
tools:
  - terraform
tags:
  - dedicated-cloud-gateways
  - terraform
  - azure
  - network
automated_tests: false
tldr:
  q: How do I configure an Azure Dedicated Cloud Gateway with VNET peering using Terraform?
  a: |
    After your Azure Dedicated Cloud Gateway network is `Ready`, grant Kong access in your Azure tenant, then define a `konnect_cloud_gateway_transit_gateway` resource with an `azure-vnet-peering-attachment` and apply it with Terraform.
    Verify that the peering is `ready` using the {{site.konnect_short_name}} API.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Configure an Azure Dedicated Cloud Gateway with VNET peering
    url: /dedicated-cloud-gateways/azure-peering/
  - text: Dedicated Cloud Gateways network architecture
    url: /dedicated-cloud-gateways/network-architecture/
  - text: Dedicated Cloud Gateways private network architecture and security
    url: /dedicated-cloud-gateways/private-network/
prereqs:
  show_works_on: false
  inline:
    - title: Terraform and the Konnect provider
      include_content: prereqs/products/konnect-terraform
      icon_url: /assets/icons/terraform.svg
    - title: Microsoft Entra
      include_content: prereqs/entra-tenant
      icon_url: /assets/icons/azure.svg
    - title: Microsoft Azure CLI
      include_content: prereqs/azure-cli
      icon_url: /assets/icons/azure.svg
    - title: Azure virtual network
      content: |
        To configure VNET peering in {{site.konnect_short_name}}, you'll need a [virtual network configured in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/quickstart-create-virtual-network?tabs=portal). 

        Copy your Entra tenant ID and virtual network subscription ID, resource group name, and virtual network name and pass them to Terraform as input variables. Terraform automatically reads any environment variable prefixed with `TF_VAR_`:

        ```sh
        export TF_VAR_tenant_id='YOUR_TENANT_ID'
        export TF_VAR_subscription_id='YOUR_SUBSCRIPTION_ID'
        export TF_VAR_resource_group_name='YOUR_RESOURCE_GROUP_NAME'
        export TF_VAR_vnet_name='YOUR_VNET_NAME'
        ```

        {:.danger}
        > **Important:** Your Azure virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.
    - title: Azure Dedicated Cloud Gateway network and control plane
      include_content: prereqs/dcgw-azure-network-cp
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
  - text: Configure an Azure managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/azure-managed-cache-control-plane/
---

## Grant Kong access in your Azure tenant

{{site.konnect_short_name}} needs permission to create and manage peering resources in your Azure tenant. Terraform's `kong/konnect` provider can't configure this on the Azure side, so you grant it with Microsoft Entra and the Azure CLI before you apply your configuration.

1. Grant admin consent to the Dedicated Cloud Gateway app in Microsoft Entra. You need an admin account to approve the app.
1. Create a custom role named `Kong Cloud Gateway Peering Creator` with the following permissions:

    * Read and write access to Virtual Network peering configurations
    * Permission to perform peering actions
```sh
az role definition create --output none --role-definition '{
    "Name": "Kong Cloud Gateway Peering Creator - Kong",
    "Description": "Perform cross-tenant network peering.",
    "Actions": [
        "Microsoft.Network/virtualNetworks/read",
        "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
        "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
        "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
        "Microsoft.Network/virtualNetworks/peer/action"
    ],
    "AssignableScopes": [
        "/subscriptions/$SUBSCRIPTION_ID"
    ]
}'
```
  Replace `$SUBSCRIPTION_ID` with your VNet subscription ID.

1. Assign the role to the {{site.konnect_short_name}} service principal so it has permission to peer with your virtual network.
```sh
az role assignment create \
  --role "Kong Cloud Gateway Peering Creator - Kong" \
  --assignee "$(az ad sp list --filter "appId eq 'REPLACE BACK with value once you check'" \
  --output tsv --query '[0].id')" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME"
```
Replace the following:
* `$SUBSCRIPTION_ID`: The subscription ID of your VNet in Azure.
* `$RESOURCE_GROUP_NAME`: The resource group name of your VNet in Azure.
* `$VNET_NAME`: The name of your VNet.

## Define the VNET peering resource

Add a `konnect_cloud_gateway_transit_gateway` resource to your Terraform configuration. Declare the input variables you exported, then reference your Dedicated Cloud Gateway network so Terraform provisions it before the peering. The `azure-vnet-peering-attachment` attaches your Azure virtual network to your network:

<!--vale off-->
```hcl
echo '
variable "tenant_id" {}
variable "subscription_id" {}
variable "resource_group_name" {}
variable "vnet_name" {}

resource "konnect_cloud_gateway_transit_gateway" "my_vnet_peering" {
  network_id = konnect_cloud_gateway_network.my_cloudgatewaynetwork.id

  azure_transit_gateway = {
    name = "azure vnet peering"

    transit_gateway_attachment_config = {
      kind                = "azure-vnet-peering-attachment"
      tenant_id           = var.tenant_id
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      vnet_name           = var.vnet_name
    }
  }
}
' >> main.tf
```
<!--vale on-->

If you created your Dedicated Cloud Gateway network outside this Terraform project, replace the `network_id` reference with your network ID.

## Apply the configuration

Create the VNET peering resource using Terraform:

```bash
terraform apply -auto-approve
```

You will see one resource created:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
{:.no-copy-code}

## Validate

VNET peering can take 30-40 minutes to become active. To confirm that it's ready, fetch the network and peering IDs from the Terraform state:

```bash
KONNECT_NETWORK_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "konnect_cloud_gateway_network.my_cloudgatewaynetwork") | .values.id')
VNET_PEERING_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "konnect_cloud_gateway_transit_gateway.my_vnet_peering") | .values.id')
```

Then call the {{site.konnect_short_name}} API and confirm that the peering's `state` is `ready`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways/$VNET_PEERING_ID
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
