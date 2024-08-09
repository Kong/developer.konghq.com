---
title: How to create rate limiting tiers with Kong Gateway
related_resources:
  - text: Consumer Group API documentation
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

products:
    - gateway

platforms:
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

tiers:
  - enterprise

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
---

With consumer groups, you can define rate limiting tiers and apply them to subsets of application consumers.

You can define consumer groups as tiers, for example:

* A **gold tier** consumer group with 1000 requests per minute
* A **silver tier** consumer group with 10 requests per second
* A **bronze tier** consumer group with 6 requests per second
  
Consumers that are not in a consumer group default to the Rate Limiting advanced plugin’s configuration, so you can define tier groups for some users and have a default behavior for consumers without groups.

To use consumer groups for rate limiting, you need to:

* Create one or more consumer groups
* Create consumers
* Assign consumers to groups

## Steps

1. Create a consumer group named `Gold`:
{% capture step %}
  {% entity_example %}
    type: consumer_group
    data:
      name: Gold
  
  {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Create a consumer, `Amal`:
{% capture step %}
   {% entity_example %}
    type: consumer
    data:
      username: Amal
      username_lower: amal
   {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Add `Amal` to the `Gold` consumer group:
{% capture step %}
  {% entity_example %}
    type: consumer_group
    data:
      name: Gold
      consumer:
        username: Amal
        username_lower: amal
  {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Enable the plugin on the consumer group:
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
