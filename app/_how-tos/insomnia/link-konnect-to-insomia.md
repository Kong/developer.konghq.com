---
title: Link a {{ site.konnect_short_name }} Service Gateway to {{ site.data.products.insomnia.name }} 
permalink: /how-to/link-konnect-to-insomnia/

content_type: how_to

products:
  - insomnia
works_on:
  - konnect

tier: enterprise

min_version:
  insomnia: '13'

description: Link {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }} and send requests against a routes in your {{site.base_gateway}} Service.
tags:
  - konnect
  - integrations
prereqs:
  skip_product: true
  show_works_on: false
  inline:
    - title: "{{ site.konnect_product_name }}"
      content: |
        This tutorial requires a {{ site.konnect_short_name }} account and a personal access token (PAT). If you don't have a {{ site.konnect_short_name }} account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

        Create a new PAT by opening the [{{ site.konnect_short_name }} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**. Save the token value to use when linking {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }}.
      icon_url: /assets/icons/gateway.svg
    - title: A deployed Gateway Service
      content: |
        You need a control plane with at least one Gateway Service and Route already configured in {{ site.konnect_short_name }}. See [Data Plane hosting options](/gateway/topology-hosting-options/) to choose a control plane type, then create a [Gateway Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).
      icon_url: /assets/icons/widgets.svg
next_steps:
  - text: Use the Collection Runner in Insomnia
    url: /how-to/use-the-collection-runner/
breadcrumbs:
  - /insomnia/
related_resources:
  - text: "{{ site.konnect_short_name }} integration in {{ site.data.products.insomnia.name }}"
    url: /insomnia/konnect-integration/
  - text: Enterprise
    url: /insomnia/enterprise/
  - text: Data Plane hosting options
    url: /gateway/topology-hosting-options/
tldr:
  q: How do I use {{ site.data.products.insomnia.name }} to send requests against a route hosted on {{ site.konnect_short_name }}?
  a: In {{ site.data.products.insomnia.name }}, link {{ site.konnect_short_name }} using a [Personal Access Token (PAT)](/konnect-api/#personal-access-tokens) and set up proxy URLs for your Gateway Service.  
---

## Link {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }}

{% include insomnia/konnect-integration.md %}

## Set the Proxy URLs

{% include insomnia/set-konnect-proxies.md %}

You are now ready to send requests from {{ site.data.products.insomnia.name }} against routes hosted on {{ site.konnect_short_name }}.