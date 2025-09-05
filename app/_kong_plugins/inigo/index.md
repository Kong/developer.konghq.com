---
title: 'Inigo GraphQL'
name: 'Inigo GraphQL'

content_type: plugin

publisher: inigo
description: "Integrate Kong API Gateway with Inigo GraphQL Observability and Security"


products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true

source_code_url: https://github.com/inigolabs/inigo-kong
support_url: https://docs.inigo.io/support

icon: inigo.png

search_aliases:
  - inigo
  - graphql

tags:
  - observability
  - inigo

related_resources:
  - text: Inigo app
    url: https://app.inigo.io
  - text: Inigo documentation
    url: https://docs.inigo.io

min_version:
  gateway: '3.0'
---

Inigo offers complete visibility, control, and security for your production GraphQL APIs, enabling you to confidently adopt and scale GraphQL with the Inigo Kong plugin. 

Designed specifically for GraphQL APIs, this plugin provides:
- Deep API analytics
- Schema-based role-based access control (RBAC)
- Performance and error monitoring
- Dynamic rate limiting
- Prevention of breaking schema changes

Inigo’s plugin gives you unique, in-depth insights into GraphQL usage, from granular field-level details to full query paths, along with overall server health and performance metrics. 
It enforces security policies, modifies or blocks malicious queries before they reach your GraphQL servers, and alerts you to any API issues.

## How the Inigo plugin works

The Inigo plugin can be enabled on any GraphQL API route.
1. It syncs with a service configured in Inigo using the provided service token. 
2. The plugin enforces access control, rate limits, and other security policies configured in your Inigo service. 
3. Requests are batched and sent asynchronously to Inigo, ensuring no added latency to your API. 
4. The data is then analyzed in the cloud, matched against your GraphQL schema, and presented with full observability and insights into your API’s performance.

## Install the Inigo plugin

{% capture extra-steps %}
1. Download the Inigo library:

    1. Find the [library](https://github.com/inigolabs/artifacts/releases/latest) for your architecture. Library file names start with *inigo-*.
    1. Download and copy the library into your `kong run` directory. 

1. Obtain and set the Inigo Service Token:

    1. Create a service and token in [Inigo](https://app.inigo.io).
    1. Set the `INIGO_SERVICE_TOKEN` environment variable with the token's value.
{% endcapture %}

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="inigo-kong-plugin" extra-steps=extra-steps %}
