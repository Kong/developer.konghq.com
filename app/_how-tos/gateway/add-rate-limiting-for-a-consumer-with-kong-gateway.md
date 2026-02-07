---
title: Rate limit a Consumer with {{site.base_gateway}}
permalink: /how-to/add-rate-limiting-for-a-consumer-with-kong-gateway/
content_type: how_to
related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: How to create rate limiting tiers with {{site.base_gateway}}
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/
description: Learn how to rate limit a Consumer with the Rate Limiting and Key Authentication plugins.
products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - rate-limiting
  - key-auth

entities: 
  - service
  - plugin
  - consumer

tags:
    - rate-limiting

tldr:
    q: How do I rate limit a Consumer with {{site.base_gateway}}?
    a: Enable an authentication plugin and create a [Consumer](/gateway/entities/consumer/) with credentials, then enable the [Rate Limiting plugin](/plugins/rate-limiting/) on the new Consumer.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.
We're going to use key [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs an API key to access any {{site.base_gateway}} Services.

{% entity_examples %}
entities:
  consumers:
    - username: jsmith
      keyauth_credentials:
        - key: example-key
{% endentity_examples %}

## Enable authentication

Authentication lets you identify a Consumer so that you can apply rate limiting.
This example uses the [Key Authentication](/plugins/key-auth/) plugin, but you can use any [authentication plugin](/plugins/?category=authentication) that you prefer.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Enable rate limiting

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the Consumer. 
In this example, the limit is 5 requests per minute and 1000 requests per hour.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      consumer: jsmith
      config:
        minute: 5
        hour: 1000
{% endentity_examples %}

## Validate

You can run the following command to test the rate limiting as the Consumer:

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
headers:
  - 'apikey:example-key'
{% endvalidation %}
