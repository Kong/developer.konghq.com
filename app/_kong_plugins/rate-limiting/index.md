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
  - q: What is the Rate Limiting plugin used for?
    a: The Rate Limiting plugin is used to control the rate of requests that clients can make to your services. It helps prevent abuse and ensures fair usage by limiting the number of requests a client can make in a given time period.
  - q: Can I set different rate limits for different endpoints or services?
    a: Yes, you can configure rate limits on a per-service or per-route basis by applying the Rate Limiting plugin to specific services or routes in Kong.
  - q: "How does the `policy` option affect rate limiting?"
    a: |
      The `policy` option determines how rate limits are stored and enforced. The `local` policy uses Kong’s in-memory storage, while the `redis` policy uses Redis, which is useful for distributed setups where rate limiting needs to be consistent across multiple Kong data plane nodes.

related_resources:
  - text: How to create rate limiting tiers with Rate Limiting Advanced
    url: /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting Advanced Plugin
    url: /plugins/rate-limiting-advanced/

products:
  - gateway

works_on:
    - on-prem
    - konnect

topologies:
    - hybrid
    - db-less
    - traditional

icon: rate-limiting.png

categories:
  - traffic-control

search_aliases:
  - rate-limiting
---

## Overview

Rate limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days, months, or years.
If the underlying service or route has no authentication layer,
the **Client IP** address is used. Otherwise, the consumer is used if an
authentication plugin has been configured.

The advanced version of this plugin, [Rate Limiting Advanced](/plugins/rate-limiting-advanced/), provides the ability to apply
[multiple limits in sliding or fixed windows](/plugins/rate-limiting-advanced/#multi-limits-windows).



## IP Address limitations 

When configuring IP address-based limitations, it's essential to understand how Kong determines the IP address of incoming requests. The IP address is extracted from the request headers sent to Kong by downstream clients. Typically, these headers are named` X-Real-IP` or `X-Forwarded-For`, which contain the client’s IP address.

By default, Kong uses the` X-Real-IP` header to identify the client's IP address. However, if your environment requires the use of a different header, you can specify this by setting the real_ip_header property in Nginx. Additionally, depending on your network setup, you may need to configure the trusted_ips Nginx property to include the IP addresses of any load balancers or proxies that are part of your infrastructure. This ensures that Kong correctly interprets the client’s IP address, even when the request passes through multiple network layers.


## Headers sent to the client

When this plugin is enabled, Kong sends additional headers
to show the allowed limits, number of available requests,
and the time remaining (in seconds) until the quota is reset. Here's an example header:

```
RateLimit-Limit: 6
RateLimit-Remaining: 4
RateLimit-Reset: 47
```

The plugin also sends headers to show the time limit and the minutes still available:

```
X-RateLimit-Limit-Minute: 10
X-RateLimit-Remaining-Minute: 9
```

If more than one time limit is set, the header contains all of these:

```
X-RateLimit-Limit-Second: 5
X-RateLimit-Remaining-Second: 4
X-RateLimit-Limit-Minute: 10
X-RateLimit-Remaining-Minute: 9
```

When a limit is reached, the plugin returns an `HTTP/1.1 429` status code, with the following JSON body:

```json
{ "message": "API rate limit exceeded" }
```

{:.warning}
> The headers `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` are based on the Internet-Draft [RateLimit Header Fields for HTTP](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/) and may change in the future to respect specification updates.


