---
title: Configure an Azure Dedicated Cloud Gateway with virtual hub peering and outbound DNS resolution
description: 'Learn how to configure an Azure Dedicated Cloud Gateway with virtual hub peering and outbound DNS resolution.'
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-virtual-wan-with-outbound-dns-resolver/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
tags:
  - azure
  - network
automated_tests: false
tldr:
  q: How do I configure an Azure Dedicated Cloud Gateway with virtual hub peering and outbound DNS resolution?
  a: |
    In Azure, you'll need a virtual network, virtual WAN and hub, and outbound DNS resolver. 
    Create a Dedicated Cloud Gateway in {{site.konnect_short_name}} with Azure as the network provider. 
    When the Azure network is `Ready` in {{site.konnect_short_name}}, you can configure virtual hub peering by creating the peering role and assigning it to the service principal. 
    Configure an outbound DNS resolver for your Azure network in {{site.konnect_short_name}}. 
    You can use your Azure Dedicated Cloud Gateway after it displays as `Ready` for your outbound DNS resolver.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Configure an Azure Dedicated Cloud Gateway with virtual hub peering
    url: /dedicated-cloud-gateways/azure-virtual-wan/
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
    - title: Azure virtual network
      include_content: prereqs/dcgw-azure-vnet
      icon_url: /assets/icons/azure.svg
    - title: Azure private DNS resolver
      content: |
        Before you can configure outbound DNS in {{site.konnect_short_name}}, you must configure [private resolvers in Azure](https://learn.microsoft.com/en-us/azure/dns/private-resolver-endpoints-rulesets?source=recommendations):

        1. Create a [DNS resolver inside your virtual network](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-get-started-portal#create-a-dns-resolver-inside-the-virtual-network) in Azure. Save the name of your DNS resolver. 
        1. Configure the outbound endpoints in your DNS resolver in Azure.
        1. [Configure a DNS forwarding ruleset in Azure](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-get-started-portal#configure-a-dns-forwarding-ruleset).
      icon_url: /assets/icons/azure.svg
faqs:
  - q: "When I try to create the VNET peering role and assign the role to the service principal, I get the following errors: `(RoleDefinitionWithSameNameExists) A custom role with the same name already exists in this directory.` and `Role 'Kong Cloud Gateway Peering Creator - Kong' doesn't exist.`. How do I fix this?"
    a: |
      {% include faqs/azure-vnet-same-tenant-multi-subscription.md %}
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---


## Create an Azure Dedicated Cloud Gateway

{% include_cached /sections/azure-dcgw-network-setup.md %}

## Configure Azure virtual hub peering in {{site.konnect_short_name}}

{% include_cached /sections/azure-vwan-setup.md %}

An outbound DNS resolver is already created when the virtual hub peering is set up. 
We just need to add additional outbound endpoints.

## Configure an outbound DNS resolver for your Azure network in {{site.konnect_short_name}}

{% include_cached /sections/azure-outbound-dns-setup.md %}

### DNS mappings

{% include_cached /sections/private-dns-mappings.md %}

## Validate

{% include_cached /sections/outbound-dns-validate.md provider="Azure" %}