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
tags:
  - azure
  - network
automated_tests: false
tldr:
  q: How do I configure an Azure Dedicated Cloud Gateway with VNET peering and outbound DNS resolution?
  a: |
    Using a virtual network and a private DNS resolver in Azure, you can create a Dedicated Cloud Gateway in {{site.konnect_short_name}} with Azure as the network provider. 
    When the Azure network is `Ready` in {{site.konnect_short_name}}, you can configure VNET peering by creating the peering role and assigning it to the service principal. 
    Configure outbound DNS resolver for your Azure network in {{site.konnect_short_name}}. 
    You can use your Azure Dedicated Cloud Gateway after it displays as `Ready` for your outbound DNS resolver.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Configure an Azure Dedicated Cloud Gateway with VNET peering
    url: /dedicated-cloud-gateways/azure-peering/
  - text: Configure an Azure Dedicated Cloud Gateway with VNET peering and private DNS
    url:  /dedicated-cloud-gateways/azure-vnet-peering-with-private-dns/
prereqs:
  show_works_on: false
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
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

{% include_cached /sections/azure-peering.md %}

## Create an Azure Dedicated Cloud Gateway

{% include_cached /sections/azure-dcgw-network-setup.md %}

## Configure VNET peering in {{site.konnect_short_name}}

{% include_cached /sections/azure-dcgw-vnet-peering-setup.md %}

A DNS Outbound Resolver is already created when the VNET peering is set up. 
We just need to add additional outbound endpoints.

## Configure outbound DNS resolver for your Azure network in {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private DNS".
1. Click **Outbound DNS resolver**.
1. In the **Outbound Resolver name** field, enter the name of your private DNS resolver in Azure.
1. In the **Domain name** field, enter your domain.
1. In the **Target IP address** field, enter the IP addresses of your outbound endpoint subnets.
1. Click **Save**.

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

## Validate

Once your outbound DNS resolver configuration displays as ready, you can begin using your Dedicated Cloud Gateway. To verify that it's ready, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Click your Azure Dedicated Cloud Gateway.
1. In the API Gateways sidebar, click **Networks**.
1. From the action menu next to your Azure network, select "Configure private DNS".
1. Scroll until you see `Ready` for outbound DNS resolver.