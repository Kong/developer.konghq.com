---
title: Rate limit requests based on peak and off-peak time
permalink: /how-to/rate-limit-based-on-peak-time/
content_type: how_to

description: Using the Pre-function and the Rate Limiting Advanced plugins, set the rate limit based on peak or non-peak time.

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service

min_version:
  gateway: '3.4'

plugins:
  - rate-limiting-advanced
  - pre-function

entities:
  - service
  - route
  - plugin

tags:
  - rate-limiting
  - serverless

tldr:
  q: How do I set different rate limits to handle traffic during peak and off-peak time?
  a: |
    You can set the rate limit based on peak or non-peak time by using the Pre-function and the Rate Limiting Advanced plugins together.

    This tutorial shows you how to handle traffic with two different Routes: one for peak traffic, and one for off-peak traffic. Then, you apply two plugins:
    * The Rate Limiting Advanced plugin applies a different rate limit to each Route.
    * The Pre-function plugin runs a Lua function in the rewrite phase, sending traffic to one of these Routes based on the defined peak and off-peak settings in the headers.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create peak and off-peak Routes

Create a Route to handle peak traffic, and a Route to handle off-peak traffic. 
We're going to use headers to distinguish between traffic times.

Attach both Routes to the `example-service` you created in the [prerequisites](#prerequisites).

{% entity_examples %}
entities:
  routes:
    - name: peak
      service:
        name: example-service
      paths:
        - /anything
      headers:
        X-Peak:
          - 'active'
    - name: off-peak
      service:
        name: example-service
      paths:
        - /anything
      headers:
        X-Off-Peak:
          - 'active'
{% endentity_examples %}

## Apply Rate Limiting Advanced plugin

Apply rate limits to both Routes by enabling the Rate Limiting Advanced plugin on each Route:

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting-advanced
      route: peak
      config:
        limit:
          - 10
        window_size:
          - 30
        namespace: peak
    - name: rate-limiting-advanced
      route: off-peak
      config:
        limit:
          - 5
        window_size:
          - 30
        namespace: off-peak
{% endentity_examples %}


## Apply the Pre-function plugin to route peak and off-peak traffic

The Pre-Function plugin lets you run Lua code in a plugin phase of your choosing.
In this case, we're going to write a function that determines the time of day 
based on the operating system’s time, then sets a request header based on the determined time.

You can set the hours based on your own preferred peak times.

The following command applies the Pre-Function globally and runs it in the rewrite phase:

{% entity_examples %}
entities:
  plugins:
    - name: pre-function
      config:
        rewrite:
          - |
              local hour = os.date("*t").hour
              if hour >= 8 and hour <= 17
              then
                kong.service.request.set_header("X-Peak","active")
              else
                kong.service.request.set_header("X-Off-Peak","active")
              end
{% endentity_examples %}

## Validate

You can now verify that both plugins were configured correctly and are working, by sending more requests than allowed in the configured time limit.

Let's send 11 requests, which will cover both the off-peak and peak rate limits:

{% validation rate-limit-check %}
iterations: 11
url: '/anything'
{% endvalidation %}

Depending on your OS time, you will see either the `X-Peak` or `X-Off-Peak` header in the request, 
and you will hit the rate limit at either 6 or 11 requests.