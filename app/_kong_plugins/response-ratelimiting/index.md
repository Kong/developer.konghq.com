---
title: Response Rate Limiting

name: Response Rate Limiting
publisher: kong-inc
content_type: plugin
description: Rate limit based on a custom response header value.
tags:
  - rate-limiting
  - traffic-control

related_resources:
  - text: Rate limiting with {{site.base_gateway}}
    url: /gateway/rate-limiting/

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

icon: response-ratelimiting.png

categories:
  - traffic-control

search_aliases:
  - ratelimiting
  - response-ratelimiting

notes: |
  In Konnect, DB-less, and hybrid modes, the <code>cluster</code> config policy
  is not supported.
  <br><br>
  For DB-less mode, use one of <code>redis</code> or <code>local</code>;
  for Konnect and hybrid mode, use <code>redis</code>, or <code>local</code> for data
  planes only. In Serverless gateways only the <code>local</code> config policy is supported.

min_version:
  gateway: '1.0'
---

This plugin allows you to impose rate limits based on custom response headers returned by the upstream service.
You can arbitrarily set as many rate limiting objects (or quotas) as you want and instruct {{site.base_gateway}} to increase or decrease them by any number of units. 

For example, if there are different costs associated with specific upstream services, they can be returned as headers to 
{{site.base_gateway}}, and {{site.base_gateway}} will increment the rate limit counters based on these costs.

Each custom rate limiting object can limit the inbound requests in number of seconds, minutes, hours, days, months, or years.

If the underlying Gateway Service or Route has no authentication layer, the [client IP address](#limit-by-ip-address) is used for identifying clients. 
Otherwise, the Consumer is used if an authentication plugin has been configured.

## Rate limiting strategies

{% include_cached /plugins/rate-limiting/strategies.md name=page.name %}

## Limit by IP address

{% include_cached /plugins/rate-limiting/limit-by-ip.md %}

## Configuring quotas

After adding the plugin, you can increment the configured limits by adding the following response header:

```
Header-Name: Limit=Value [,Limit=Value]
```

You can change the default header name using [`config.header_name`](/plugins/response-ratelimiting/reference/#schema--config-header_name).

You can optionally increment more than one limit with comma-separated entries.
The header is removed before returning the response to the original client.

## Headers sent to the client

When the Response Rate Limiting plugin is enabled, {{site.base_gateway}} sends additional headers back to the
client, indicating how many units are still available and how many are allowed total.

For example, if you created a limit called `Videos` with a per-minute limit:

```
X-RateLimit-Limit-Videos-Minute: 10
X-RateLimit-Remaining-Videos-Minute: 9
```

If more than one limit value is set, it returns a combination of all the time limits:

```
X-RateLimit-Limit-Videos-Second: 5
X-RateLimit-Remaining-Videos-Second: 5
X-RateLimit-Limit-Videos-Minute: 10
X-RateLimit-Remaining-Videos-Minute: 10
```

If any of the configured limits configured is reached, the plugin
returns an `HTTP/1.1 429` (Too Many Requests) status code and an empty response body.

### Upstream headers

The plugin appends usage headers for each limit before proxying the request to the
upstream service, so that you can properly refuse to process the request if there
are no more limits remaining. 
The headers are in the form of `X-RateLimit-Remaining-LIMIT_NAME`, for example:

```
X-RateLimit-Remaining-Videos: 3
X-RateLimit-Remaining-Images: 0
```

{% include plugins/redis-cloud-auth.md %}
