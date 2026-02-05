---
title: Throttle APIs with different rate limits for Services and Consumers
permalink: /how-to/throttle-apis-with-services-and-consumers/
content_type: how_to
description: Use the Rate Limiting and Service Protection plugins to set different rate limits for Services and Consumers.
related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: Rate Limiting with {{site.base_gateway}}
    url: /gateway/rate-limiting/
  - text: How to create rate limiting tiers with {{site.base_gateway}}
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.9'

plugins:
  - rate-limiting
  - service-protection

entities: 
  - service
  - consumer
  - plugin

tags:
    - rate-limiting

tldr:
    q: How do I throttle APIs to protect them from DDoS attacks while allowing multiple privileged Consumers to access the Service with higher rate limits?
    a: Configure the [Rate Limiting](/plugins/rate-limiting/) plugin on two Consumers with `config.minute` set to a specific limit, then configure the [Service Protection](/plugins/service-protection/) plugin with `config.window_size` and `config.limit` set to a different limit. This setup will limit all requests on the Service to your configured limit, even if the Consumers are sending requests simultaneously. 

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

## Create privileged Consumers

In this tutorial, we'll be creating two Consumers that have different rate limits from the limits applied to the Gateway Service. 
These Consumers act as a type of "privileged" Consumer in this scenario that have higher rate limits, but they will still be prevented from exceeding the Service rate limits. 
The reason for this is to prevent DDoS type attacks on your APIs. 

{% entity_examples %}
entities:
  consumers:
    - username: jsmith
      keyauth_credentials:
      - key: jsmith-key
    - username: tsmith
      keyauth_credentials:
      - key: tsmith-key
{% endentity_examples %}

## Enable authentication

Authentication lets you identify a Consumer so that you can apply rate limiting to Consumers.
This example uses the [Key Authentication](/plugins/key-auth/) plugin, but you can use any authentication plugin that you prefer.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Enable rate limiting on Consumers with the Rate Limiting plugin 

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the Consumers. 
In this example, the limit is 6 requests per minute per Consumer.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      consumer: jsmith
      config:
        minute: 6
        limit_by: consumer
        policy: local
    - name: rate-limiting
      consumer: tsmith
      config:
        minute: 6
        limit_by: consumer
        policy: local
{% endentity_examples %}

## Enable rate limits on the Service with the Service Protection plugin

Now we can apply a rate limit on the Service itself using the [Service Protection](/plugins/service-protection/) plugin. 
In this example, we are setting the limit to 10 requests per minute. 
Due to [plugin execution order](/gateway/entities/plugin/#plugin-priority), the Service Protection plugin is applied *before* the Rate Limiting plugin. 
This means that if multiple Consumers are making requests at the same time, together they can't make more than 10 requests per minute, even if the individual Consumer rate limit is 6 requests per minute. 

{% entity_examples %}
entities:
  plugins:
    - name: service-protection
      service: example-service
      config:
        window_size: [60]
        limit: [10]
        namespace: service-protection-plugin
{% endentity_examples %}

## Validate

To test that the Service Protection plugin correctly applies rate limits to the Service, you'll run requests from both Consumers in quick succession. 

First, run the following command to test the rate limiting as the `jsmith` Consumer:

{% validation traffic-generator %}
iterations: 6
url: '/anything'
headers:
  - 'apikey:jsmith-key'
status_code: 200
{% endvalidation %}

This doesn't exceed the rate limit per Consumer or per Service.

Now, quickly run the following command to test the rate limiting as the `tsmith` Consumer:

{% validation rate-limit-check %}
iterations: 5
url: '/anything'
headers:
  - 'apikey:tsmith-key'
status_code: 429
{% endvalidation %}

You get this error because the Consumer has now exceeded the rate limit of 10 requests per minute on the Service.

