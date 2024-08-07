---
title: Rate Limiting configuration
content_type: reference
entities: 
    - service
    - route
    - consumer
    - consumer_group
    - plugin
tools:
    - deck
faqs:
  - q: What is the Rate Limiting plugin used for?
    a: The Rate Limiting plugin is used to control the rate of requests that clients can make to your services. It helps prevent abuse and ensures fair usage by limiting the number of requests a client can make in a given time period.
  - q: Can I set different rate limits for different endpoints or services?
    a: Yes, you can configure rate limits on a per-service or per-route basis by applying the Rate Limiting plugin to specific services or routes in Kong.
  - q: "How does the `policy` option affect rate limiting?"
    a: |
      The `policy` option determines how rate limits are stored and enforced. The `local` policy uses Kong’s in-memory storage, while the `redis` policy uses Redis, which is useful for distributed setups where rate limiting needs to be consistent across multiple Kong data plane nodes.
related_resources:
  - text: How to create rate limiting tiers with Rate Limiting Advanced
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/how-to/
  - text: Rate Limiting Advanced plugin overview
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/
---

This page provides a reference for the Rate Limiting plugin configuration.

## schema goes here

<!-- example plugin schema renderer below, ideally this will render on the left of the config examples -->


{% contentfor config_examples %}
{% entity_example %}
type: plugin
data:
  name: rate-limiting
  config:
    second: 5
    hour: 1000
    policy: local
targets:
  - consumer
  - service
  - route
  - global
  - consumer_group
formats:
  - admin-api
  - konnect
  - kic
  - deck
  - terraform
{% endentity_example %}
{% endcontentfor %}