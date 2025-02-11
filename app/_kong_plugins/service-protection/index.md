---
title: 'Service Protection'
name: 'Service Protection'

content_type: plugin

related_resources:
  - text: Rate Limiting with {{site.base_gateway}}
    url: /gateway/rate-limiting/
  - text: Throttle APIs with different rate limits for Services and Consumers
    url: /how-to/throttle-apis-with-services-and-consumers/

publisher: kong-inc
description: 'Prevent abuse and protect services with absolute limits on the number of requests reaching the service'
tier: enterprise


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.9'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: service-protection.png

categories:
  - traffic-control

faqs:
  - q: Does the Service Protection plugin replace the Rate Limiting or Rate Limiting Advanced plugins?
    a: No. The Service Protection plugin only rate limits services. You can still use the Rate Limiting and Rate Limiting Advanced plugins to rate limit other entities, like consumers and routes.
  - q: Can I use the Service Protection plugin with other rate limiting plugins?
    a: Yes. You can rate limit a service with the Service Protection plugin, then rate limit routes, consumers, or consumer groups with the other rate limiting plugins. We don’t recommend using multiple rate limiting plugins on the same **service only**. We recommend applying Service Protection on the service, and Rate Limiting (or Rate Limiting Advanced) on the service/consumer pair, for more granular rate limits.
  - q: When would I use the Service Protection plugin with other rate limiting plugins?
    a: You should use the Service Protection plugin to rate limit your services and use the other rate limiting plugins to limit other entities, like consumers or routes, or to apply global rate limits. 
---

Set absolute maximum rate limits for services using the Service Protection plugin. 
You can use this plugin together with other rate limiting plugins to apply granular rate limits based on different entities.

If you want to apply global rate limits or apply rate limits to routes and consumers, see the [Rate Limiting with {{site.base_gateway}}](/gateway/rate-limiting/) page for additional rate limiting plugins.

The Service Protection plugin uses the same [Rate Limiting Library](/gateway/latest/reference/rate-limiting/) as the other rate limiting plugins.
