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
    In Azure, you'll need a virtual network, virtual WAN and hub. 
    Create a Dedicated Cloud Gateway in {{site.konnect_short_name}} with Azure as the network provider. 
    When the Azure network is `Ready` in {{site.konnect_short_name}}, you can configure virtual hub peering by creating the peering role and assigning it to the service principal. 
    You can use your Azure Dedicated Cloud Gateway after it displays as `Ready` for virtual hub peering.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Configure an Azure Dedicated Cloud Gateway with virtual hub peering and outbound DNS resolution
    url: /dedicated-cloud-gateways/azure-virtual-wan-with-outbound-dns-resolver/
  - text: Configure an Azure Dedicated Cloud Gateway with virtual hub peering and private DNS
    url: /dedicated-cloud-gateways/azure-virtual-wan-with-private-dns/
prereqs:
  show_works_on: false
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: Microsoft Entra
      include_content: prereqs/entra-tenant
      icon_url: /assets/icons/azure.svg
    - title: Microsoft Azure CLI
      include_content: prereqs/azure-cli
      icon_url: /assets/icons/azure.svg
    - title: Azure virtual WAN
      include_content: prereqs/dcgw-azure-vwan
      icon_url: /assets/icons/azure.svg
faqs:
  - q: "How do I manage my Azure virtual WAN peering with Terraform?"
    a: |
      Because configuring virtual hub peering requires approving the {{site.konnect_short_name}} app in Microsoft Entra (a step that generates a link only available in the {{site.konnect_short_name}} UI), you must complete the initial setup using the UI before managing the resource in Terraform.

      After the peering is `Ready`, you can manage it with Terraform by importing the existing `konnect_cloud_gateway_transit_gateway` into your Terraform state. For a complete example, see [`cloud-gateways.tf`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/scenarios/cloud-gateways.tf). The following example shows what the resource block looks like:
      <!--vale off-->
      ```hcl
      resource "konnect_cloud_gateway_transit_gateway" "my_vhub_peering" {
        network_id = var.network_id

        azure_vhub_peering_gateway = {
          name = "azure virtual hub peering"

          transit_gateway_attachment_config = {
            kind                = "azure-vhub-peering-attachment"
            tenant_id           = var.tenant_id
            subscription_id     = var.subscription_id
            resource_group_name = var.resource_group_name
            vhub_name           = var.vhub_name
          }
        }
      }
      ```
      <!--vale on-->
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

## Create an Azure Dedicated Cloud Gateway

{% include_cached /sections/azure-dcgw-network-setup.md %}

## Configure Azure virtual hub peering in {{site.konnect_short_name}}

{% include_cached /sections/azure-vwan-setup.md %}

## Validate

After your virtual hub peering configuration displays as ready, you can begin using your Dedicated Cloud Gateway. To verify that it's ready, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click your Azure Dedicated Cloud Gateway.
1. Click the **Networks** tab.
1. Scroll until you see `Ready` for virtual hub peering.