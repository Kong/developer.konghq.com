---
title: Rate Limiting Strategies

description: This page describes the rate limiting strategies supported by {{site.base_gateway}} plugins.

content_type: reference
layout: reference

products:
   - gateway

plugins:
  - rate-limiting
  - response-ratelimiting
  - rate-limiting-advanced
  - ai-rate-limiting-advanced
  - graphql-rate-limiting-advanced

breadcrumbs:
  - /gateway/
  - /gateway/rate-limiting/

works_on:
  - on-prem
  - konnect

related_resources:
  - text: DNS configuration reference
    url: /gateway/network/dns-config-reference/

---

All rate limiting plugins support some subset of the following strategies:

{% table %}
columns:
  - title: Strategy
    key: strategy
  - title: Pros
    key: pros
  - title: Cons
    key: cons
  - title: Supported in plugin
    key: supported
rows:
  - strategy: "`local`"
    pros: "Minimal performance impact."
    cons: "Less accurate. Unless there's a consistent-hashing load balancer in front of Kong, it diverges when scaling the number of nodes."
    supported: "AI Rate Limiting Advanced<br>Rate Limiting Advanced<br>Rate Limiting<br>Response Rate Limiting"
  - strategy: "`cluster`"
    pros: "Accurate<sup>1</sup>, no extra components to support."
    cons: "Each request forces a read and a write on the data store. Therefore, relatively, the biggest performance impact."
    supported: "AI Rate Limiting Advanced<br>Rate Limiting Advanced<br>Rate Limiting<br>Response Rate Limiting<br>GraphQL Rate Limiting Advanced"
  - strategy: "`redis`"
    pros: "Accurate<sup>1</sup>, less performance impact than a `cluster` policy."
    cons: "Needs a Redis installation. Bigger performance impact than a `local` policy."
    supported: "AI Rate Limiting Advanced<br>Rate Limiting Advanced<br>Rate Limiting<br>Response Rate Limiting<br>GraphQL Rate Limiting Advanced"
{% endtable %}

<!-- 

| Plugin | local | cluster | redis |
| ------ | ----- | ------- | ----- |
| Rate Limiting | ✅ | ✅ | ✅ |
| Rate Limiting Advanced | ✅ | ✅ | ✅ |
| AI Rate Limiting Advanced | ✅ | ✅ | ✅ |
| GraphQL Rate Limiting Advanced | ❌ | ✅ | ✅ |
| Response Ratelimiting | ✅ | ✅ | ✅ | -->

{:.info .no-icon}
> **\[1\]**: Only when `sync_rate` option is set to `0` (synchronous behavior). See the configuration reference for each plugin for more details.

Two common use cases are:

1. _Every transaction counts_. The highest level of accuracy is needed. An example is a transaction with financial
   consequences.
2. _Backend protection_. Accuracy is not as relevant. The requirement is
   only to protect backend services from overloading that's caused either by specific
   users or by attacks.

## Every transaction counts

In this scenario, because accuracy is important, the `local` policy is not an option. Consider the support effort you might need
for Redis, and then choose either `cluster` or `redis`.

You could start with the `cluster` policy, and move to `redis`
if performance reduces drastically.

Do remember that you cannot port the existing usage metrics from the data store to Redis.
This might not be a problem with short-lived metrics (for example, seconds or minutes)
but if you use metrics with a longer time frame (for example, months), plan
your switch carefully.

## Backend protection

If accuracy is of lesser importance, choose the `local` policy. You might need to experiment a little
before you get a setting that works for your scenario. As the cluster scales to more nodes, more user requests are handled.
When the cluster scales down, the probability of false negatives increases. So, adjust your limits when scaling.

For example, if a user can make 100 requests every second, and you have an
equally balanced 5-node Kong cluster, setting the `local` limit to something like 30 requests every second
should work. If you see too many false negatives, increase the limit.

To minimize inaccuracies, consider using a consistent-hashing load balancer in front of
Kong. The load balancer ensures that a user is always directed to the same Kong node, thus reducing
inaccuracies and preventing scaling problems.

## Fallback from Redis

When the `redis` strategy is used and a {{site.base_gateway}} node is disconnected from Redis, the plugin will fall back to `local`. This can happen when the Redis server is down or the connection to Redis broken.
{{site.base_gateway}} keeps the local counters for rate limiting and syncs with Redis once the connection is re-established.
{{site.base_gateway}} will still rate limit, but the {{site.base_gateway}} nodes can't sync the counters. As a result, users will be able
to perform more requests than the limit, but there will still be a limit per node.


## Policy strategies
Two common use cases are:

{% table %}
columns:
  - title: You need...
    key: need
  - title: Use the following plugin policy strategies...
    key: strategy
rows:
  - need: "A high level of accuracy in critical transactions. An example is a transaction with financial consequences."
    strategy: "`cluster` or `redis`"
  - need: "Protect backend services from overloading caused by specific users or attacks. High accuracy is not as relevant."
    strategy: "`local`"
{% endtable %}

If the plugin can't retrieve the selected policy, it falls back to [limiting usage by identifying the IP address](#limit-by-ip-address).

### High accuracy use case recommendations

In this scenario, because accuracy is important, the `local` policy is not an option. Consider the support effort you might need
for Redis, and then choose either `cluster` or `redis`.

You could start with the `cluster` policy, and move to `redis`
if performance reduces drastically.

Do remember that you cannot port the existing usage metrics from the data store to Redis.
This might not be a problem with short-lived metrics (for example, seconds or minutes)
but if you use metrics with a longer time frame (for example, months), plan
your switch carefully.

### Backend protection use case recommendations

If accuracy is of lesser importance, choose the `local` policy. You might need to experiment a little
before you get a setting that works for your scenario. As the cluster scales to more nodes, more user requests are handled.
When the cluster scales down, the probability of false negatives increases. So, adjust your limits when scaling.

For example, if a user can make 100 requests every second, and you have an
equally balanced 5-node Kong cluster, setting the `local` limit to something like 30 requests every second
should work. If you see too many false negatives, increase the limit.

To minimize inaccuracies, consider using a consistent-hashing load balancer in front of
Kong. The load balancer ensures that a user is always directed to the same Kong node, thus reducing
inaccuracies and preventing scaling problems.

