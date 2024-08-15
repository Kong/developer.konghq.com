---
title: How to create rate limiting tiers with Kong Gateway
related_resources:
  - text: Consumer Group API documentation
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - ui

min_version:
  gateway: 3.4.x

plugins: 
  - rate-limiting-advanced

entites:
  - consumer
  - consumer_group

tier: enterprise

tags:
  - rate-limiting

content_type: tutorial

tldr: 
  q: How do you rate limit tiers of users?
  a: You can rate limit tiers of users by creating different consumer groups, assigning consumers to those groups, and then configure the Rate Limiting Advanced plugin to limit the requests.

faqs:
  - q: Why can't I use the regular Rate Limiting plugin to rate limit tiers of consumers?
    a: In this tutorial, we use the Rate Limiting Advanced plugin because it supports sliding windows, which we use to apply the rate limiting logic while taking into account previous hit rates (from the window that immediately precedes the current) using a dynamic weight.

tools:
    - deck

prereqs:
    consumers:
        - example-consumer
    consumer-groups:
        - example-consumer-group
---

With consumer groups, you can define rate limiting tiers and apply them to subsets of application consumers.

You can define consumer groups as tiers, for example:

* A **gold tier** consumer group with 1000 requests per minute
* A **silver tier** consumer group with 10 requests per second
* A **bronze tier** consumer group with 6 requests per second
  
Consumers that are not in a consumer group default to the Rate Limiting advanced plugin’s configuration, so you can define tier groups for some users and have a default behavior for consumers without groups.

## Steps

1. Enable the Rate Limiting Advanced plugin on the consumer group:
{% capture step %}
  {% entity_example %}
    type: plugin
    data:
      name: rate-limiting-advanced
      config:
        limit: 5
        window_size: 30
        window_type: sliding
        retry_after_jitter_max: 0
 
    targets:
        - consumer_group

    variables:
      'consumerGroupName|Id': Gold
  {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

    This configuration sets the rate limit to five requests (`config.limit`) for every 30 seconds (`config.window_size`).

1. Synchronize your configuration

  Check the differences in your files:
  ```sh
  deck gateway diff deck_files
  ```

  If everything looks right, synchronize them to update your Kong Gateway configuration:
  ```sh
  deck gateway sync deck_files
  ```

