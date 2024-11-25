---
title: Rate Limiting Advanced plugin

name: Rate Limiting Advanced
publisher: kong-inc
tier: enterprise
content_type: plugin
description: Enhanced Rate Limiting capabilities such as sliding window, Redis Sentinel support and increased performance.
tags:
  - rate-limiting
  - rate-limiting-advanced
  - traffic-control
related_resources:
  - text: How to create rate limiting tiers with Rate Limiting Advanced
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/how-to/

works_on:
    - on-prem
    - konnect
---

## Overview

Rate limit how many HTTP requests can be made in a given time frame.

[to do: write this section in a better way]

The Rate Limiting Advanced plugin offers more functionality than the {{site.base_gateway}} (OSS) [Rate Limiting plugin](../rate-limiting/), such as:
* Enhanced capabilities to tune the rate limiter, provided by the parameters `limit` and `window_size`. Learn more in [Multiple Limits and Window Sizes](#multi-limits-windows)
* Support for Redis Sentinel, Redis cluster, and Redis SSL
* Increased performance: Rate Limiting Advanced has better throughput performance with better accuracy. The plugin allows you to tune performance and accuracy via a configurable synchronization of counter data with the backend storage. This can be controlled by setting the desired value on the `sync_rate` parameter.
* More limiting algorithms to choose from: These algorithms are more accurate and they enable configuration with more specificity. Learn more about our algorithms in [How to Design a Scalable Rate Limiting Algorithm](https://konghq.com/blog/how-to-design-a-scalable-rate-limiting-algorithm).
* More control over which requests contribute to incrementing the rate limiting counters via the `disable_penalty` parameter
* Consumer groups support: Apply different rate limiting configurations to select groups of consumers.

## Headers sent to the client

When this plugin is enabled, Kong sends some additional headers back to the client
indicating the allowed limits, how many requests are available, and how long it will take
until the quota will be restored.

For example:

```plaintext
RateLimit-Limit: 6
RateLimit-Remaining: 4
RateLimit-Reset: 47
```

The plugin also sends headers indicating the limits in the time frame and the number
of remaining minutes:

```plaintext
X-RateLimit-Limit-Minute: 10
X-RateLimit-Remaining-Minute: 9
```

You can optionally hide the limit and remaining headers with the `hide_client_headers` option.

If more than one limit is being set, the plugin returns a combination of more time limits:

```plaintext
X-RateLimit-Limit-Second: 5
X-RateLimit-Remaining-Second: 4
X-RateLimit-Limit-Minute: 10
X-RateLimit-Remaining-Minute: 9
```

If any of the limits configured has been reached, the plugin returns an `HTTP/1.1 429` status
code to the client with the following JSON body:

```plaintext
{ "message": "API rate limit exceeded" }
```

The [`Retry-After`] header will be present on `429` errors to indicate how long the service is
expected to be unavailable to the client. When using `window_type=sliding` and `RateLimit-Reset`, `Retry-After`
may increase due to the rate calculation for the sliding window.

{:.warning}
> The headers `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` are based on the Internet-Draft [RateLimit Header Fields for HTTP](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers) and may change in the future to respect specification updates.

## Limit by IP address

If limiting by IP address, it's important to understand how the IP address is determined. The IP address is determined by the request header sent to Kong from downstream. In most cases, the header has a name of `X-Real-IP` or `X-Forwarded-For`. 

By default, Kong uses the header name `X-Real-IP`. If a different header name is required, it needs to be defined using the [real_ip_header](https://docs.konghq.com/gateway/latest/reference/configuration/#real_ip_header) Nginx property. Depending on the environmental network setup, the [trusted_ips](https://docs.konghq.com/gateway/latest/reference/configuration/#trusted_ips) Nginx property may also need to be configured to include the load balancer IP address.

## Rate limiting for consumer groups

You can use the [consumer groups entity](https://docs.konghq.com/gateway/api/admin-ee/latest/#/consumer_groups/get-consumer_groups) to manage custom rate limiting configurations for
subsets of consumers. This is enabled by default **without** using the `/consumer_groups/:id/overrides` endpoint.

You can see an example of this in the [Enforcing rate limiting tiers with the Rate Limiting Advanced plugin](https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/how-to/) guide.
