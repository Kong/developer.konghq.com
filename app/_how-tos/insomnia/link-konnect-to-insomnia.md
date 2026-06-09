---
title: Link a {{ site.konnect_short_name }} to {{ site.data.products.insomnia.name }} 
permalink: /how-to/link-konnect-to-insomnia/

content_type: how_to

products:
  - gateway
  - insomnia
works_on:
  - konnect
tools:
  - deck


tiers:
  insomnia: enterprise

min_version:
  insomnia: '13'

description: Link {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }} and send requests against a Route in your {{site.base_gateway}} Service.
tags:
  - konnect
  - integrations
prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route

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

You are now ready to send requests from {{ site.data.products.insomnia.name }} against Routes hosted on {{ site.konnect_short_name }}.