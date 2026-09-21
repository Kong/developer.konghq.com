---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: Rate Limiting Policy
    url: /ai-gateway/policies/rate-limiting/
  - text: Rate Limiting Advanced Policy
    url: /ai-gateway/policies/rate-limiting-advanced/
  - text: AI Rate Limiting Advanced Policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
---

The Response Rate Limiting Policy counts arbitrary units of usage that the upstream service reports back in a response header. This lets an upstream with variable per-request costs report its own usage instead of {{site.ai_gateway}} inferring cost implicitly. You can define as many named limits as you want, and instruct the upstream to increment them by any number of units.

## How it works

Define one or more limits in [`config.limits`](./reference/#schema--config-limits), each with its own `second`, `minute`, `hour`, `day`, `month`, or `year` threshold. From your upstream service, report usage against those names using a response header in the form:

```
<header-name>: <limit-name>=<value>[,<limit-name>=<value>]
```

By default, the header is named `x-kong-limit` ([`config.header_name`](./reference/#schema--config-header-name)). For example, to report 1 unit of usage against a limit named `video`:

```
x-kong-limit: video=1
```

{{site.ai_gateway}} removes this header before returning the response to the original client, and increments the named counter by the reported value.

This Policy doesn't prevent the upstream from being called once a limit is reached. Every request, including the one that trips the limit, is still proxied to the upstream.

## Example: Rate limit on usage reported by a self-hosted model backend

You can use this Policy in {{site.ai_gateway}} with a self-hosted, OpenAI-API-compatible backend, such as a `vllm`-type [AI Model Provider](/ai-gateway/entities/ai-model-provider/), that reports its own usage on every response. The following configuration allows 2 units of a `test` limit per minute, aggregated by client IP address:

{% entity_example %}
type: policy
data:
  display_name: my-response-ratelimiting
  name: my-response-ratelimiting
  type: response-ratelimiting
  enabled: true
  global: false
  config:
    limit_by: ip
    policy: local
    limits:
      test:
        minute: 2
formats:
  - kongctl
{% endentity_example %}

Once the upstream has reported 2 units of the `test` limit within a minute (for example, by returning `x-kong-limit: test=1` on each of its first two responses), the third request still reaches the upstream, but {{site.ai_gateway}} discards that response and rejects the request with `429 Too Many Requests` instead.

## Strategies

Use [`config.policy`](./reference/#schema--config-policy) to choose how counters are stored:

* `local`: Counters are stored in-memory on the node. Minimal performance impact, but not shared across {{site.ai_gateway}} nodes.
* `redis`: Counters are stored on a Redis server and shared across nodes.

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md %}

### Fallback from Redis

{% include md/ai-gateway/v2/redis-fallback.md %}

## Limit by

Use [`config.limit_by`](./reference/#schema--config-limit-by) to choose what the Policy aggregates counters against: `consumer`, `credential`, or `ip`. If the AI Consumer or credential can't be determined, {{site.ai_gateway}} falls back to `ip`.

### Limit by IP address

{% include md/ai-gateway/v2/policies/rate-limiting/limit-by-ip.md %}

## Headers sent to the client

{{site.ai_gateway}} sends additional headers back to the client, indicating how many units are still available and how many are allowed in total. For example, for a limit named `video` with a per-minute threshold:

```plaintext
X-RateLimit-Limit-Video-Minute: 10
X-RateLimit-Remaining-Video-Minute: 9
```

If more than one limit or time window is configured, {{site.ai_gateway}} returns a combination of all of them. You can hide these headers with [`config.hide_client_headers`](./reference/#schema--config-hide-client-headers).

## Headers sent to the upstream

{{site.ai_gateway}} also appends usage headers for each limit before proxying the request to the upstream service, so the upstream can decide whether to process the request at all when no limits remain. These headers are in the form `X-RateLimit-Remaining-<LIMIT_NAME>`, for example:

```plaintext
X-RateLimit-Remaining-Video: 3
X-RateLimit-Remaining-Image: 0
```
