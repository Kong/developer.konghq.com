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
  a: |
    Using a virtual network, virtual network link, and private DNS zone in Azure, you can create a Dedicated Cloud Gateway in {{site.konnect_short_name}} with Azure as the network provider. 
    When the Azure network is `Ready` in {{site.konnect_short_name}}, you can configure VNET peering by creating the peering role and assigning it to the service principal. 
    Configure private DNS for your Azure network in {{site.konnect_short_name}}. 
    You can use your Azure Dedicated Cloud Gateway after it displays as `Ready` for your private hosted zone.
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
      include_content: prereqs/entra-tenant
      icon_url: /assets/icons/azure.svg
    - title: Microsoft Azure CLI
      include_content: prereqs/azure-cli
      icon_url: /assets/icons/azure.svg
    - title: Azure virtual network
      include_content: prereqs/dcgw-azure-vnet
      icon_url: /assets/icons/azure.svg
    - title: Azure private DNS zone
      content: |
        Configuring Azure private DNS for Dedicated Cloud Gateways involves creating a private DNS zone in Azure, linking the private DNS zone to your virtual network, and configuring a private hosted zone in {{site.konnect_short_name}}.

        1. [Create a private DNS zone in Azure](https://learn.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#create-a-private-dns-zone) in the same resource group as the virtual network that you're using for VNET peering.
        1. Copy and save your domain name, private DNS zone name, private DNS subscription ID, and private DNS resource group name.
      icon_url: /assets/icons/azure.svg
faqs:
  - q: "When I try to create the VNET peering role and assign the role to the service principal, I get the following errors: `(RoleDefinitionWithSameNameExists) A custom role with the same name already exists in this directory.` and `Role 'Kong Cloud Gateway Peering Creator - Kong' doesn't exist.`. How do I fix this?"
    a: |
      {% include faqs/azure-vnet-same-tenant-multi-subscription.md %}
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
  - text: Configure an Azure managed cache for a Dedicated Cloud Gateway control plane
    url: /dedicated-cloud-gateways/azure-managed-cache-control-plane/
  - text: Configure an Azure managed cache for a Dedicated Cloud Gateway control plane group
    url: /dedicated-cloud-gateways/azure-managed-cache-control-plane-group/
---

{% include_cached /sections/azure-peering.md %}

## Create an Azure Dedicated Cloud Gateway

{% include_cached /sections/azure-dcgw-network-setup.md %}

## Configure VNET peering in {{site.konnect_short_name}}

{% include_cached /sections/azure-dcgw-vnet-peering-setup.md %}

## Configure private DNS for your Azure network in {{site.konnect_short_name}}

{% include_cached /sections/azure-private-dns-setup.md %}

## Validate

{% include_cached /sections/private-dns-validate.md provider="Azure" %}