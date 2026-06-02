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

        Copy your virtual network subscription ID, resource group name, and virtual network name.

        {:.danger}
        > **Important:** Your Azure virtual network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.
    - title: Azure Dedicated Cloud Gateway network
      content: |
        This how-to configures VNET peering on an existing network. Before you start, [create an Azure Dedicated Cloud Gateway](/dedicated-cloud-gateways/azure-peering/) and wait until the network displays as `Ready`.

        Copy the network ID and export it:

        ```sh
        export KONNECT_NETWORK_ID='YOUR_NETWORK_ID'
        ```
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
  - text: Configure an Azure managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/azure-managed-cache-control-plane/
---

## Set your Azure virtual network details

Export your Azure virtual network details so you can reuse them in your Terraform configuration:

```sh
export AZURE_TENANT_ID='YOUR_TENANT_ID'
export AZURE_SUBSCRIPTION_ID='YOUR_SUBSCRIPTION_ID'
export AZURE_RESOURCE_GROUP_NAME='YOUR_RESOURCE_GROUP_NAME'
export AZURE_VNET_NAME='YOUR_VNET_NAME'
```

## Grant Kong access in your Azure tenant

{{site.konnect_short_name}} needs permission to create and manage peering resources in your Azure tenant. Terraform's `kong/konnect` provider can't configure this on the Azure side, so you grant it with Microsoft Entra and the Azure CLI before you apply your configuration.

1. Grant admin consent to the Dedicated Cloud Gateway app in Microsoft Entra. You need an admin account to approve the app.
1. Create a custom role named `Kong Cloud Gateway Peering Creator` with the following permissions:

    * Read and write access to Virtual Network peering configurations
    * Permission to perform peering actions

1. Assign the role to the {{site.konnect_short_name}} service principal so it has permission to peer with your virtual network.

<!-- TODO (iterate with Diana): replace this section with the exact `az` CLI commands (or azuread/azurerm Terraform resources) for creating the role and assigning it to the service principal. The Konnect UI wizard generates these commands today; they are not yet captured here. -->

## Define the VNET peering resource

Add a `konnect_cloud_gateway_transit_gateway` resource to your Terraform configuration. The `azure-vnet-peering-attachment` attaches your Azure virtual network to your Dedicated Cloud Gateway network:

<!--vale off-->
```hcl
echo '
resource "konnect_cloud_gateway_transit_gateway" "my_vnet_peering" {
  network_id = "'$KONNECT_NETWORK_ID'"
  name       = "azure vnet peering"

  transit_gateway_attachment_config = {
    kind                = "azure-vnet-peering-attachment"
    tenant_id           = "'$AZURE_TENANT_ID'"
    subscription_id     = "'$AZURE_SUBSCRIPTION_ID'"
    resource_group_name = "'$AZURE_RESOURCE_GROUP_NAME'"
    vnet_name           = "'$AZURE_VNET_NAME'"
  }
}
' >> main.tf
```
<!--vale on-->

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

VNET peering can take 30-40 minutes to become active. To confirm that it's ready, fetch the peering ID from the Terraform state:

```bash
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

<!-- TODO (confirm with Diana): verify this validation endpoint against the live API. The OpenAPI spec models Azure VNET peering as a transit gateway under `.../networks/{networkId}/transit-gateways/{id}`, but you noted it may use a different endpoint. -->
