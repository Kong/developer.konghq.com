---
title: Rate Limiting Advanced

name: Rate Limiting Advanced
publisher: kong-inc
tier: enterprise
content_type: plugin
description: Enhanced rate limiting capabilities such as sliding window support, Redis Sentinel support, and increased performance
tags:
  - rate-limiting
  - traffic-control
related_resources:
  - text: Rate limiting in {{site.base_gateway}}
    url: /gateway/rate-limiting/
  - text: Create rate limiting tiers with Rate Limiting Advanced
    url: /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Apply multiple rate limits and window sizes
    url: /how-to/multiple-rate-limits-window-sizes/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
  - text: Dynamic plugin config with CEL
    url: /gateway/plugins/expressible-fields/
  - text: "How-to: Configure dynamic plugin config with CEL"
    url: /gateway/configure-dynamic-plugin-config-with-cel/

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

notes: |
  In Konnect, DB-less, and hybrid modes, the `cluster` config strategy
  is not supported.
  <br><br>
  For DB-less mode, use one of `redis` or `local`;
  for Konnect and hybrid mode, use `redis`, or `local` for data
  planes only. In Serverless gateways only the `local` config strategy is supported.

min_version:
  gateway: '1.0'
faqs:
  - q: What are the potential impacts and risks associated with enabling request throttling in Rate Limiting Advanced?
    a: |
      Enabling [request throttling](#throttle-rate-limits) can lead to a degradation in the capacity of {{site.base_gateway}} data plane nodes. This is because client requests are held open for a longer duration during the throttling period compared to normal rejections. This extended occupation of resources (like memory and file descriptors) can reduce the data plane's ability to handle other new requests, potentially leading to scale or stress issues during high traffic spikes. Configuring a large [`config.throttling.queue_limit`](/plugins/rate-limiting-advanced/reference/#schema--config-throttle-queue-limit) can also consume significant memory on data plane nodes.
  - q: What happens to queued requests if a client drops its connection with {{site.base_gateway}} during the Rate Limiting Advanced throttling period?
    a: |
      If a client drops its connection with Kong while a [request is being throttled](#throttle-rate-limits) ({% new_in 3.12 %}), {{site.base_gateway}} automatically releases all associated resources for that specific request. This means the individual request will no longer be processed or retried. However, the counter that accounted for this request's slot in the "waiting room" is automatically managed by the underlying counter mechanism (shared dictionary or Redis). These counters are typically recorded within specific time windows and are automatically evicted when their window expires, ensuring resource cleanup without manual intervention for each dropped connection.
  - q: How is memory usage impacted when I enable throttling with the Rate Limiting Advanced plugin?
    a: |
      In regular conditions, memory usage is minimally impacted. In extreme conditions where both {{site.base_gateways}}’s header buffer and the kernel’s TCP buffer are fully used and you're using the default configuration ({{site.base_gateways}} accepts a maximum request header size of 32 KB, and the Linux kernel TCP buffer is approximately 200 KB), the average memory consumption of each open connection is around 220 KB for one Route with one Rate Limiting Advanced plugin configured with the following:
      * `config.limit`: 30 seconds
      * `config.throttling.interval`: 3,600 seconds
      * `config.throttling.retry_times`: 3
      * `config.throttling.queue_limit`: 100000

      You can test your own [throttling](#throttle-rate-limits) memory usage under extreme conditions by using a script like the following:
      ```sh
      #prepare header strings
      H1=$(head -c 8092 < /dev/zero | tr '\0' 'A')
      H2=$(head -c 8092 < /dev/zero | tr '\0' 'B')
      H3=$(head -c 8092 < /dev/zero | tr '\0' 'C')
      H4=$(head -c 8092 < /dev/zero | tr '\0' 'D')
      head -c 1000000 /dev/zero > /tmp/1mb

      for i in {1..10000};
      do

        curl -s http://hostname:7000/ \
          -H "X-Header-1: $H1" \
          -H "X-Header-2: $H2" \
          -H "X-Header-3: $H3" \
          -H "X-Header-4: $H4" \
          --data-binary @/tmp/1mb \
          -o /dev/null &
        echo "creating $i"
      done

      wait
      ```
---

Rate limit how many HTTP requests can be made in a given time frame using multiple rate limits and window sizes, and applying sliding windows.
This plugin is a more advanced version of the [Rate Limiting plugin](/plugins/rate-limiting/), which only allows one fixed rate limiting window.

If the underlying Gateway Service or Route has no authentication layer, the [client IP address](#limit-by-ip-address) is used for identifying clients.
Otherwise, the Consumer is used if an authentication plugin has been configured.

Advanced features of this plugin include:
* [Sliding window support](#window-types), which provides better performance than fixed rate limiting
* [Multiple limits and window sizes](#multiple-limits-and-window-sizes)
* Support for Redis Sentinel, Redis cluster, and Redis SSL
* Control over which requests contribute to incrementing the rate limiting counters via the [`config.disable_penalty`](./reference/#schema--config-disable-penalty) parameter

Kong also provides multiple specialized rate limiting plugins, including rate limiting across LLMs and GraphQL queries.
See [Rate limiting in {{site.base_gateway}}](/gateway/rate-limiting/) to choose the plugin that is most useful in your use case.

## Window types

The Rate Limiting Advanced plugin supports the following window types:

* **Fixed window**: Fixed windows consist of buckets that are statically assigned to a definitive time range. Each request is mapped to only one fixed window based on its timestamp and will affect only that window’s counters.
* **Sliding window** (default): A sliding window tracks the number of hits assigned to a specific key (such as an IP address, consumer, credential) within a given time window, taking into account previous hit rates to create a dynamically calculated rate.
The default (and recommended) sliding window type ensures a resource is not consumed at a higher rate than what is configured.

Learn more about how the different [window types](/gateway/rate-limiting/window-types/) work for rate limiting plugins.

## Multiple limits and window sizes

An arbitrary number of limits or window sizes can be applied per plugin instance. This allows you to create multiple rate limiting windows (for example, rate limit per minute and per hour, and per any arbitrary window size). Because of limitations with {{site.base_gateway}}’s plugin configuration interface, each nth limit will apply to each nth window size. For example:

{% entity_example %}
type: plugin
data:
  name: rate-limiting-advanced
  config:
    limit:
      - 10
      - 100
    window_size:
      - 60
      - 3600
formats:
  - deck
  - admin-api
  - konnect-api
  - kic
  - terraform
{% endentity_example %}

This example applies two rate limiting policies, one of which will trip when 10 hits have been counted in 60 seconds, or the other when 100 hits have been counted in 3600 seconds.

The number of configured window sizes and limits parameters must be equal, otherwise you will get the following error:

```plaintext
You must provide the same number of windows and limits
```
{:.no-copy-code}

## Namespace

The namespace field is auto-generated for the plugin instance. It's optional when configuring the plugin through API commands or decK.

If you are managing {{site.base_gateway}} with decK or running {{site.base_gateway}} in DB-less mode, set the namespace explicitly in your declarative configuration.
Otherwise the field will be regenerated automatically with every update.


## Strategies

{% include_cached /plugins/rate-limiting/strategies.md name=page.name %}

### Using cloud authentication with Redis {% new_in 3.13 %}

{% include_cached /plugins/redis/redis-cloud-auth.md tier=page.tier %}

{% include_cached /plugins/redis/enterprise.md name=page.name heading_level=3 redis_group="strategy" %}

### Fallback from Redis

{% include md/ai-gateway/v1/redis-fallback.md %}

## Limit by IP address

{% include_cached /plugins/rate-limiting/limit-by-ip.md %}

## Headers sent to the client

{% include_cached /plugins/rate-limiting/headers.md name=page.name %}

## Rate limiting for Consumer Groups

You can use the [Consumer Groups entity](/gateway/entities/consumer-group/) to manage custom rate limiting configurations for
subsets of Consumers.

You can see an example of this in the guide on [enforcing rate limiting tiers with the Rate Limiting Advanced plugin](/how-to/add-rate-limiting-tiers-with-kong-gateway/).

## Throttle rate limits {% new_in 3.12 %}

In {{site.base_gateway}} 3.12 or later, you can enable request throttling using the Rate Limiting Advanced plugin to improve clients' experience and protect upstream origin servers from being overwhelmed by traffic spikes. With throttling, requests that exceed the rate limit threshold can be delayed and retried, rather than immediately rejected with a `429` status code.

We recommend setting `disable_penalty` to `true` when using throttle rate limits with sliding window. Because for the sliding window type, if you set `disable_penalty` to `false`, all requests, including denied ones, will still be counted toward the rate limit. This can lead to a situation where every subsequent window immediately reaches the limit, causing all requests to be denied. In this case, the throttling mechanism will not take effect, because there are no accepted requests left to throttle.

Throttled rate limits work like the following:
1. When a request hits the rate limit, it's placed into a "waiting room" or queue. The client's connection is held during this delay.
   * This queue uses local, Redis, or cluster strategies to manage the queue of throttled requests using a counter-based approach.
1. Requests in the queue are automatically retried after a configurable interval ([`config.throttling.interval`](/plugins/rate-limiting-advanced/reference/#schema--config-interval)).
   * There's a limit to retries for individual requests ([`config.throttling.retry_times`](/plugins/rate-limiting-advanced/reference/#schema--config-retry-times)), and a cap to the total number of requests waiting ([`config.throttling.queue_limit`](/plugins/rate-limiting-advanced/reference/#schema--config-queue-limit)).
   * All concurrent requests will retry at approximately the same time once the specified interval has elapsed.
1. If a request exceeds its maximum retries or if the waiting room is full, it will ultimately be rejected with a 429 response.

For an example plugin configuration, see [Throttle requests](/plugins/rate-limiting-advanced/examples/throttle-requests/).

## Consumer counter key {% new_in 3.15 %}

When [`identifier`](/plugins/rate-limiting-advanced/reference/#schema--config-identifier) is set to `consumer`, you can use the [`counter_key`](/plugins/rate-limiting-advanced/reference/#schema--config-counter-key) field to control which consumer attribute keys the rate limit counter.
By default, the counter is keyed by `consumer.id`.
You can also key by `consumer.username` or `consumer.custom_id`.

When you use `consumer.username` or `consumer.custom_id`, consumers with identical attribute values contribute to the same rate limit counter, even if they were authenticated by different control planes.
This enables consistent rate limiting across distributed deployments that share a Redis backend.

`counter_key` also applies when using [`compound_identifier`](/plugins/rate-limiting-advanced/reference/#schema--config-compound-identifier) with a Consumer segment, for example `["ip", "consumer"]`.

For an example plugin configuration, see [Rate limit by consumer username](/plugins/rate-limiting-advanced/examples/rate-limit-counter-key/).

## Rate limit by Principal {% new_in 3.16 %}

Set [`identifier`](/plugins/rate-limiting-advanced/reference/#schema--config-identifier) to `principal` to rate limit based on the authenticated [{{site.identity}} Principal](/identity/principals/) instead of the Consumer, credential, IP address, or other supported identifiers. `principal` is also a valid segment in [`compound_identifier`](/plugins/rate-limiting-advanced/reference/#schema--config-compound-identifier).

```yaml
config:
  identifier: principal
  limit:
    - 10
  window_size:
    - 60
```

`principal` requires an auth plugin that populates the Principal, such as Key Auth configured for Kong Identity Principal authentication.

In [hybrid mode](/gateway/hybrid-mode/), if the control plane is running {{site.base_gateway}} 3.16 or later and a data plane is running an earlier version, {{site.base_gateway}} falls back to `identifier: ip` for that data plane, and drops `principal` from `compound_identifier` if it's set.

[`custom_key`](/plugins/rate-limiting-advanced/reference/#schema--config-custom-key) overrides the computed rate limiting key with a literal string, regardless of `identifier` or `compound_identifier`. This is most useful in combination with [expressible config fields](#dynamic-configuration-with-cel), where `custom_key`'s value comes from a CEL expression instead of a fixed string.

## Dynamic configuration with CEL {% new_in 3.16 %}

`limit` and `custom_key` are [expressible config fields](/gateway/plugins/expressible-fields/#expressible-config-fields): instead of always using the static value in `config`, {{site.base_gateway}} can compute the field's value per request from a CEL expression, for example, reading an attribute of the authenticated Consumer or Principal. If the expression is unset, invalid, or fails to evaluate, {{site.base_gateway}} falls back to the field's static value in `config`.

Because `limit` is an array field (one value per configured window), its expression is also an array, with one expression per element, in the same order:

```yaml
config:
  identifier: principal
  custom_key: unknown-partner    # static fallback
  limit:
    - 10                         # static fallback
  window_size:
    - 60
expressions:
  custom_key: principal.metadata.partner_id
  limit:
    - principal.metadata.rate_limit
```

{:.info}
> **Note**: `window_size` is **not** expressible because it is unreliable.
> For the `cluster` and `redis` strategies, window sizes are registered for cross-node counter synchronization once, from the static config, when the plugin is configured. 
> A per-request expression-driven window size would never be picked up by that registration.

See also:
* For an example plugin configuration, see [Rate limit by Principal metadata](/plugins/rate-limiting-advanced/examples/rate-limit-by-principal-metadata/).
* For a full walkthrough, see the how-to guide [Configure dynamic plugin config with CEL](/gateway/configure-dynamic-plugin-config-with-cel/).
* For general information on expressible config fields, including limitations, see [Dynamic plugin config with CEL](/gateway/plugins/expressible-fields/).



