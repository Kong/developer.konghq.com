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
      include_content: prereqs/entra-tenant
      icon_url: /assets/icons/azure.svg
    - title: Microsoft Azure CLI
      include_content: prereqs/azure-cli
      icon_url: /assets/icons/azure.svg
    - title: Azure virtual WAN
      include_content: prereqs/dcgw-azure-vwan
      icon_url: /assets/icons/azure.svg
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

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. Scroll until you see `Ready` for virtual hub peering.