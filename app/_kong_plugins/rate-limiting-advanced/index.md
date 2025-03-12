---
title: Rate Limiting Advanced

name: Rate Limiting Advanced
publisher: kong-inc
content_type: plugin
description: Enhanced rate limiting capabilities such as sliding window support, Redis Sentinel support, and increased performance
tags:
  - rate-limiting
  - rate-limiting-advanced
  - traffic-control
related_resources:
  - text: Rate limiting in {{site.base_gateway}}
    url: /gateway/rate-limiting/
  - text: Create rate limiting tiers with Rate Limiting Advanced
    url: /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Apply multiple rate limits and window sizes
    url: /how-to/multiple-rate-limits-window-sizes/
  - text: Rate Limiting plugin
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

icon: rate-limiting-advanced.png

categories:
  - traffic-control

search_aliases:
  - rate-limiting-advanced

---

Rate limit how many HTTP requests can be made in a given time frame using multiple rate limits and window sizes, and applying sliding windows.
This plugin is a more advanced version of the [Rate Limiting plugin](/plugins/rate-limiting/), which only allows one fixed rate limiting window.

Advanced features of this plugin include:
* [Sliding window support](#window-types), which provides better performance than fixed rate limiting
* [Multiple limits and window sizes](#multiple-limits-and-window-sizes)
* Support for Redis Sentinel, Redis cluster, and Redis SSL
* Control over which requests contribute to incrementing the rate limiting counters via the [`config.disable_penalty`](/plugins/rate-limiting-advanced/) parameter

Kong also provides multiple specialized rate limiting plugins, including rate limiting across LLMs and GraphQL queries. 
See [Rate Limiting in {{site.base_gateway}}](/gateway/rate-limiting/) to choose the plugin that is most useful in your use case.

## Window types

The Rate Limiting Advanced plugin supports the following window types:

* **Fixed window**: Fixed windows consist of buckets that are statically assigned to a definitive time range. Each request is mapped to only one fixed window based on its timestamp and will affect only that window’s counters.
* **Sliding window** (default): A sliding window tracks the number of hits assigned to a specific key (such as an IP address, consumer, credential) within a given time window, taking into account previous hit rates to create a dynamically calculated rate.
The default (and recommended) sliding window type ensures a resource is not consumed at a higher rate than what is configured.

Learn more about how the different [window types](/gateway/rate-limiting/window-types/) work for rate limiting plugins.

## Multiple limits and window sizes

An arbitrary number of limits or window sizes can be applied per plugin instance. This allows you to create multiple rate limiting windows (for example, rate limit per minute and per hour, and per any arbitrary window size). Because of limitations with {{site.base_gateway}}’s plugin configuration interface, each nth limit will apply to each nth window size. For example:

```yaml
config:
  limit:
    - 10
    - 100
  window_size:
    - 60
    - 3600
```
This example applies two rate limiting policies, one of which will trip when 10 hits have been counted in 60 seconds, or the other when 100 hits have been counted in 3600 seconds.

The number of configured window sizes and limits parameters must be equal, otherwise you will get the following error:

```plaintext
You must provide the same number of windows and limits
```
{:.no-copy-code}

## Strategies

{% include_cached /plugins/rate-limiting/strategies.md %}

### Fallback from Redis

When the `redis` strategy is used and a {{site.base_gateway}} node is disconnected from Redis, the `rate-limiting-advanced` plugin will fall back to `local`. 
This can happen when the Redis server is down or the connection to Redis broken.
{{site.base_gateway}} keeps the local counters for rate limiting and syncs with Redis once the connection is re-established.
{{site.base_gateway}} will still rate limit, but the {{site.base_gateway}} nodes can't sync the counters. As a result, users will be able
to perform more requests than the limit, but there will still be a limit per node.

## Limit by IP address

{% include_cached /plugins/rate-limiting/limit-by-ip.md %}

## Headers sent to the client

{% include_cached /plugins/rate-limiting/headers.md %}

## Rate limiting for consumer groups

You can use the [Consumer Groups entity](/entities/gateway/consumer-group/) to manage custom rate limiting configurations for
subsets of Consumers.

You can see an example of this in the guide on [enforcing rate limiting tiers with the Rate Limiting Advanced plugin](/how-to/add-rate-limiting-tiers-with-kong-gateway/).