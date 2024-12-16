---
title: How to create rate limiting tiers with {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Consumer Group API documentation
    url: /api/gateway/admin-ee/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

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
    routes:
        - example-route

min_version:
  gateway: 3.4

plugins:
  - rate-limiting-advanced
  - key-auth

entities:
  - consumer
  - consumer_group

tier: enterprise

tags:
  - rate-limiting

tldr:
  q: How do I rate limit different tiers of users, such as free vs. premium subscribers, in my API using {{site.base_gateway}}?
  a: To effectively manage API traffic for various user tiers (such as free, basic, and premium subscribers) you can create consumer groups for each tier and assign individual consumers to these groups. Then, configure the Rate Limiting Advanced plugin to apply specific rate limits based on these groups. This setup allows you to enforce customized request limits for each tier, ensuring fair usage and optimizing performance for high-value users.

faqs:
  - q: Why can't I use the regular Rate Limiting plugin to rate limit tiers of consumers?
    a: We use the Rate Limiting Advanced plugin because it supports sliding windows, which we use to apply the rate limiting logic while taking into account previous hit rates (from the window that immediately precedes the current) using a dynamic weight.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. things
<!--outlines:
How to:
- how do I configure it alongside the other entities it relies on? 
- since regex is a common use case, I'd like to see that.
-->