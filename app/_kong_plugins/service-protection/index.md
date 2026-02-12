---
title: 'Service Protection'
name: 'Service Protection'

content_type: plugin
tier: enterprise

related_resources:
  - text: Rate Limiting with {{site.base_gateway}}
    url: /gateway/rate-limiting/
  - text: Throttle APIs with different rate limits for Services and Consumers
    url: /how-to/throttle-apis-with-services-and-consumers/

publisher: kong-inc
description: 'Prevent abuse and protect services with absolute limits on the number of requests reaching the service'


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
tags:
  - traffic-control
  - rate-limiting

faqs:
  - q: Does the Service Protection plugin replace the Rate Limiting or Rate Limiting Advanced plugins?
    a: No. The Service Protection plugin only rate limits Gateway Services. You can still use the Rate Limiting and Rate Limiting Advanced plugins to rate limit other entities, like Consumers and Routes.
  - q: Can I use the Service Protection plugin with other rate limiting plugins?
    a: Yes. You can rate limit a Gateway Service with the Service Protection plugin, then rate limit Routes, Consumers, or Consumer Groups with the other rate limiting plugins. We don’t recommend using multiple rate limiting plugins on the same **Service only**. We recommend applying Service Protection on the Service, and Rate Limiting (or Rate Limiting Advanced) on the Service/Consumer pair, for more granular rate limits.
  - q: When would I use the Service Protection plugin with other rate limiting plugins?
    a: You should use the Service Protection plugin to rate limit your Services and use the other rate limiting plugins to limit other entities, like Consumers or Routes, or to apply global rate limits. 

notes: |
  This plugin doesn't support cluster policies. 
  If you want to use this plugin in hybrid mode or in Konnect, use Redis for storage.
---

Set absolute maximum rate limits for Gateway Services using the Service Protection plugin. 
You can use this plugin together with other rate limiting plugins to apply granular rate limits based on different entities.

If you want to apply global rate limits or apply rate limits to Routes and Consumers, see the [Rate Limiting with {{site.base_gateway}}](/gateway/rate-limiting/) page for additional rate limiting plugins.

{% include plugins/redis-cloud-auth.md %}
