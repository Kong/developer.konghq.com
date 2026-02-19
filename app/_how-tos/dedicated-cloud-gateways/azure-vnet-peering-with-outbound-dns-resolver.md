---
title: Configure an Azure Dedicated Cloud Gateway with VNET peering and outbound DNS resolution
description: 'Learn how to configure an Azure Dedicated Cloud Gateway with VNET peering and outbound DNS resolution.'
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-vnet-peering-with-outbound-dns-resolver/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure an Azure Dedicated Cloud Gateway with VNET peering and outbound DNS resolution?
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

A DNS Outbound Resolver is already created when the VNET peering is set up. 
We just need to add additional outbound endpoints.

## Configure private resolvers in Azure

Configuring [private resolvers in Azure](https://learn.microsoft.com/en-us/azure/dns/private-resolver-endpoints-rulesets?source=recommendations) for outbound DNS involves creating additional outbound endpoints and creating the DNS ruleset. 

1. Create a [DNS resolver inside the virtual network](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-get-started-portal#create-a-dns-resolver-inside-the-virtual-network) in Azure. Save the name of your DNS resolver. 
1. Configure the outbound endpoints in your DNS resolver in Azure.
1. [Configure a DNS forwarding ruleset in Azure](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-get-started-portal#configure-a-dns-forwarding-ruleset).

## Configure outbound DNS resolver for your Azure network in {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private DNS".
1. Click **Outbound DNS resolver**.
1. In the **Outbound Resolver name** field, enter the name of your private DNS resolver in Azure.
1. In the **Domain name** field, enter your domain.
1. In the **Target IP address** field, enter the IP address.
1. Click **Save**.

## Validate

Once your outbound DNS resolver configuration displays as ready, you can begin using your Dedicated Cloud Gateway. To verify that it's ready, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. Scroll until you see `Ready` for outbound DNS resolver.