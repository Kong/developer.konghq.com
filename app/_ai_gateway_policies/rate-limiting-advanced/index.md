---
description: Enhanced rate limiting capabilities such as sliding window support, Redis Sentinel support, and increased performance.
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
related_resources:
  - text: AI Rate Limiting Advanced Policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
---

Rate limit how many HTTP requests can be made in a given time frame using multiple rate limits and window sizes, and applying sliding windows.
This Policy is a more advanced version of the [Rate Limiting Policy](/ai-gateway/policies/rate-limiting/), which only allows one fixed rate limiting window.

{% include md/ai-gateway/v2/policies/rate-limiting/identify-clients.md %}

Advanced features of this Policy include:

* [Sliding window support](#window-types), which provides better performance than fixed rate limiting
* [Multiple limits and window sizes](#multiple-limits-and-window-sizes)
* Support for Redis Sentinel, Redis cluster, and Redis SSL
* Control over which requests contribute to incrementing the rate limiting counters through the [`config.disable_penalty`](./reference/#schema--config-disable-penalty) parameter

To rate limit on LLM token usage or cost rather than request count, use the [AI Rate Limiting Advanced Policy](/ai-gateway/policies/ai-rate-limiting-advanced/) instead.

## Window types

The Rate Limiting Advanced Policy supports the following window types, set with [`config.window_type`](./reference/#schema--config-window-type):

* **Fixed window**: Fixed windows consist of buckets that are statically assigned to a definitive time range. Each request is mapped to only one fixed window based on its timestamp and will affect only that window's counters.
* **Sliding window** (default): A sliding window tracks the number of hits assigned to a specific key (such as an IP address, AI Consumer, or credential) within a given time window, taking into account previous hit rates to create a dynamically calculated rate.
The default (and recommended) sliding window type ensures a resource is not consumed at a higher rate than what is configured.

## Multiple limits and window sizes

An arbitrary number of limits or window sizes can be applied per Policy instance. This allows you to create multiple rate limiting windows (for example, rate limit per minute and per hour, and per any arbitrary window size). Each nth limit applies to each nth window size. For example:

{% entity_example %}
type: policy
data:
  display_name: Rate Limiting Advanced - Global
  name: rate-limiting-advanced-global
  type: rate-limiting-advanced
  enabled: true
  global: true
  config:
    limit:
      - 10
      - 100
    window_size:
      - 60
      - 3600
formats:
  - kongctl
{% endentity_example %}

This example applies two rate limits, one of which will trip when 10 hits have been counted in 60 seconds, and the other when 100 hits have been counted in 3600 seconds.

The number of configured window sizes and limits parameters must be equal, otherwise you will get the following error:

```plaintext
You must provide the same number of windows and limits
```
{:.no-copy-code}

## Namespace

The [`config.namespace`](./reference/#schema--config-namespace) field is a logical grouping for the counter data used by the rate limiting algorithm. It's auto-generated for the Policy instance and is optional when you create the Policy.

Set the namespace explicitly in your declarative configuration when you manage {{site.ai_gateway}} with [kongctl](/kongctl/). Otherwise the field is regenerated automatically with every update.

## Strategies

{% include md/ai-gateway/v2/rate-limiting-strategies.md name="Rate Limiting Advanced" window_size_field="config.window_size" limit_field="config.limit" %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md %}

### Fallback from Redis

{% include md/ai-gateway/v2/redis-fallback.md %}

## Identifiers

Use [`config.identifier`](./reference/#schema--config-identifier) to choose what the Policy aggregates counters against:

{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "`consumer`"
    description: "The authenticated [AI Consumer](/ai-gateway/entities/ai-consumer/). This is the default."
  - value: "`consumer-group`"
    description: "The [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) the AI Consumer belongs to. The Policy must be referenced from an AI Consumer Group to use this value."
  - value: "`credential`"
    description: The credential the AI Consumer authenticated with. Use this to limit each API key separately when one AI Consumer holds several.
  - value: "`ip`"
    description: "The client IP address. See [Limit by IP address](#limit-by-ip-address)."
  - value: "`header`"
    description: "The value of the header named in [`config.header_name`](./reference/#schema--config-header-name)."
  - value: "`path`"
    description: "The request path set in [`config.path`](./reference/#schema--config-path)."
{% endtable %}

To key counters on a combination of values, set [`config.compound_identifier`](./reference/#schema--config-compound-identifier) to an array instead, for example `["ip", "consumer"]`. When `compound_identifier` is set, it takes priority over `identifier`.

### Limit by IP address

{% include md/ai-gateway/v2/policies/rate-limiting/limit-by-ip.md %}

## Headers sent to the client

{% include md/ai-gateway/v2/policies/rate-limiting/headers.md sliding_window=true %}

Use [`config.retry_after_jitter_max`](./reference/#schema--config-retry-after-jitter-max) to add a random delay of up to the configured number of seconds to the `Retry-After` header on denied requests. This prevents all clients from retrying at the same moment.

## Rate limiting for AI Consumer Groups

You can use the [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) entity to manage custom rate limiting configurations for subsets of AI Consumers.

Set [`config.enforce_consumer_groups`](./reference/#schema--config-enforce-consumer-groups) to `true` and list the groups allowed to override the settings in [`config.consumer_groups`](./reference/#schema--config-consumer-groups).

## Throttle rate limits

You can enable request throttling to improve clients' experience and protect upstream AI Model Providers from being overwhelmed by traffic spikes. With throttling, requests that exceed the rate limit threshold can be delayed and retried, rather than immediately rejected with a `429` status code.

We recommend setting [`config.disable_penalty`](./reference/#schema--config-disable-penalty) to `true` when using throttled rate limits with a sliding window. For the sliding window type, if you set `disable_penalty` to `false`, all requests, including denied ones, are still counted toward the rate limit. This can lead to a situation where every subsequent window immediately reaches the limit, causing all requests to be denied. In this case, the throttling mechanism will not take effect, because there are no accepted requests left to throttle.

Throttled rate limits work like the following:

1. When a request hits the rate limit, it's placed into a "waiting room" or queue. The client's connection is held during this delay.
   * This queue uses local, Redis, or cluster strategies to manage the queue of throttled requests using a counter-based approach.
1. Requests in the queue are automatically retried after a configurable interval ([`config.throttling.interval`](./reference/#schema--config-throttling-interval)).
   * There's a limit to retries for individual requests ([`config.throttling.retry_times`](./reference/#schema--config-throttling-retry-times)), and a cap to the total number of requests waiting ([`config.throttling.queue_limit`](./reference/#schema--config-throttling-queue-limit)).
   * All concurrent requests will retry at approximately the same time once the specified interval has elapsed.
1. If a request exceeds its maximum retries or if the waiting room is full, it will ultimately be rejected with a `429` response.

Enable throttling by setting [`config.throttling.enabled`](./reference/#schema--config-throttling-enabled) to `true`:

{% entity_example %}
type: policy
data:
  display_name: Rate Limiting Advanced - Throttled
  name: rate-limiting-advanced-throttled
  type: rate-limiting-advanced
  enabled: true
  global: true
  config:
    limit:
      - 10
    window_size:
      - 60
    window_type: sliding
    disable_penalty: true
    throttling:
      enabled: true
      interval: 5
      retry_times: 3
      queue_limit: 100
formats:
  - kongctl
{% endentity_example %}
