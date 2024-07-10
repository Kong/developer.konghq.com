---
title: How to create rate limiting tiers
related_resources:
  - text: Consumer Group API documentation
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/
  - text: Rate Limiting Advanced plugin
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/
info_box
  products: ["konnect", "gateway"]
  plugins: ["Rate Limiting Advanced"]
  apis: ["consumer group", "consumer", "rate limiting advanced"]
faqs:
  - q: Why can't I use the regular Rate Limiting plugin to rate limit tiers of consumers?
    a: answer here. 
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

## Create rate limiting tiers

1. Create a consumer group named `Gold`:
  {% entity_example %}
    type: consumer-group
    data:
      custom_id: 8a4bba3c-7f82-45f0-8121-ed4d2847c4a4
      name: Gold
  
    formats:
      - admin-api
      - konnect
      - kic
      - deck
      - ui
    {% endentity_example %}

1. Create a consumer, `Amal`:
   {% entity_example %}
    type: consumer
    data:
      username: Amal
      username_lower: amal
  
    formats:
      - admin-api
      - konnect
      - kic
      - deck
      - ui
    {% endentity_example %}

1. Add `Amal` to the `Gold` consumer group:
   {% entity_example %}
    type: consumer-group
    data:
      custom_id: 8a4bba3c-7f82-45f0-8121-ed4d2847c4a4
      name: Gold
      consumer.id: 8089a0e6-1d31-4e00-bf51-5b902899b4cb
      consumer.username: Amal
      consumer.username_lower: amal
  
    formats:
      - admin-api
      - konnect
      - kic
      - deck
      - ui
    {% endentity_example %}

1. Enable the plugin on the consumer group:
   {% plugin_example %}
    type: rate-limiting-advanced
    request:
      name: gold
    data:
      name: rate-limiting-advanced
      config.limit: 5
      config.window_size: 30
      config.window_type: sliding
      config.retry_after_jitter_max=0
  
    formats:
      - admin-api
      - konnect
      - kic
      - deck
      - ui
    {% endentity_example %}

    This configuration sets the rate limit to five requests (`config.limit`) for every 30 seconds (`config.window_size`).
