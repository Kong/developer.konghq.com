---
title: Rate Limiting

name: Rate Limiting
publisher: kong-inc
content_type: plugin
description: You can use the Rate Limiting plugin to limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days, months, or years.
tags:
    - rate-limiting
    - traffic-control

faqs:
  - q: Can I set different rate limits for different endpoints or services?
    a: Yes, you can configure rate limits on a per-service or per-route basis by applying the Rate Limiting plugin to specific services or routes in Kong.
  - q: "How does the `policy` option affect rate limiting?"
    a: |
      The `policy` option determines how rate limits are stored and enforced. The `local` policy uses Kong’s in-memory storage, while the `redis` policy uses Redis, which is useful for distributed setups where rate limiting needs to be consistent across multiple Kong data plane nodes.

related_resources:
  - text: Rate limiting in {{site.base_gateway}}
    url: /gateway/rate-limiting/
  - text: Rate limit a Gateway Service with {{site.base_gateway}}
    url: /how-to/add-rate-limiting-to-a-service-with-kong-gateway/
  - text: Rate limit a Consumer with {{site.base_gateway}}
    url: /how-to/add-rate-limiting-for-a-consumer-with-kong-gateway/
  - text: Throttle APIs with different rate limits for Services and Consumers
    url: /how-to/throttle-apis-with-services-and-consumers/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

products:
  - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: rate-limiting.png

categories:
  - traffic-control

search_aliases:
  - rate-limiting

notes: |
  In Konnect, DB-less, and hybrid modes, the `cluster` config policy
  is not supported.
  <br><br>
  For DB-less mode, use one of `redis` or `local`;
  for Konnect and hybrid mode, use `redis`, or `local` for data
  planes only. In Serverless gateways only the `local` config policy is supported.

min_version:
  gateway: '1.0'
---

Rate limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days, months, or years.
If the underlying Gateway Service or Route has no authentication layer, the [client IP address](#limit-by-ip-address) is used for identifying clients. 
Otherwise, the Consumer is used if an authentication plugin has been configured.

The advanced version of this plugin, [Rate Limiting Advanced](/plugins/rate-limiting-advanced/), provides the ability to apply
multiple limits in sliding or fixed windows, and includes Redis Sentinel and Redis Cluster support.

Kong also provides multiple specialized rate limiting plugins, including rate limiting across LLMs and GraphQL queries. 
See [Rate Limiting in {{site.base_gateway}}](/gateway/rate-limiting/) to choose the plugin that is most useful in your use case.

## Strategies

{% include_cached /plugins/rate-limiting/strategies.md name=page.name %}

## Limit by IP address

{% include_cached /plugins/rate-limiting/limit-by-ip.md %}

## Headers sent to the client

{% include_cached /plugins/rate-limiting/headers.md name=page.name %}

{% include plugins/redis-cloud-auth.md %}
