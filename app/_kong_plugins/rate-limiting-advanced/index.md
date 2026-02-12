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
  In Konnect, DB-less, and hybrid modes, the <code>cluster</code> config strategy
  is not supported.
  <br><br>
  For DB-less mode, use one of <code>redis</code> or <code>local</code>;
  for Konnect and hybrid mode, use <code>redis</code>, or <code>local</code> for data
  planes only. In Serverless gateways only the <code>local</code> config strategy is supported.

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

{% include plugins/redis-cloud-auth.md %}

### Fallback from Redis

When the `redis` strategy is used and a {{site.base_gateway}} node is disconnected from Redis, the `rate-limiting-advanced` plugin will fall back to `local`.
This can happen when the Redis server is down or the connection to Redis broken.
{{site.base_gateway}} keeps the local counters for rate limiting and syncs with Redis once the connection is re-established.
{{site.base_gateway}} will still rate limit, but the {{site.base_gateway}} nodes can't sync the counters. As a result, users will be able
to perform more requests than the limit, but there will still be a limit per node.

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


