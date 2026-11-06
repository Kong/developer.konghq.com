---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Reference for the Proxy Cache Advanced AI Policy, which stores upstream responses in memory or Redis and serves repeated requests from the cache.'
categories:
  - traffic-control
tags:
  - traffic-control
  - caching
  - ai
search_aliases:
  - proxy-cache-advanced
  - proxy cache advanced
  - proxy caching
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
---

Repeating the same request to a slow, rate-limited, or per-request-billed upstream wastes time and money.
The Proxy Cache Advanced [AI Policy](/ai-gateway/entities/ai-policy/) stores upstream responses in memory or in Redis and serves repeated requests from the cache.
{{site.ai_gateway}} serves the cached response until the entry expires.

This policy extends the [Proxy Cache Policy](/ai-gateway/policies/proxy-cache/) with Redis storage.

## Use cases

The following are common reasons to cache responses:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: An [AI Agent](/ai-gateway/entities/ai-agent/) sends the same GET request many times
    description: Cache successful GET responses for a fixed time, so repeated requests don't reach a slow or rate-limited upstream.
  - usecase: You want cache entries outside the data plane
    description: Set [`config.strategy`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-strategy) to `redis` to store entries in Redis instead of memory.
  - usecase: A Redis outage must not break requests
    description: Set [`config.bypass_on_err`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-bypass-on-err) to `true` so {{site.ai_gateway}} sends the request upstream when Redis fails.
  - usecase: Responses differ by tenant or page
    description: Add the headers or query parameters that change the response to the cache key, so each variation gets its own entry.
  - usecase: Only some clients need caching
    description: Attach the policy to an [AI Consumer](/ai-gateway/entities/ai-consumer/) or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) instead of the AI Agent or an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).
  - usecase: You need to know where a response came from
    description: Read the `X-Cache-Status` response header to see whether {{site.ai_gateway}} served the response from the cache.
{% endtable %}
<!--vale on-->

## How does the Proxy Cache Advanced Policy work?

The Proxy Cache Advanced Policy builds a cache key for each request that matches the policy configuration and looks the key up in the storage backend.
If an entry exists, {{site.ai_gateway}} returns it without calling the upstream.
If not, {{site.ai_gateway}} sends the request upstream and stores the response when it meets the policy configuration.

The policy stores entries for the number of seconds set in [`config.cache_ttl`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-cache-ttl), which is 300 by default.
After an entry expires, the next request goes to the upstream and the response replaces the entry.

### What does the policy cache?

The Proxy Cache Advanced Policy caches a response when the request method, the response status code, and the response content type all match the policy configuration.
Set these conditions in [`config.request_method`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-request-method), [`config.response_code`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-response-code), and [`config.content_type`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-content-type).

The response content type must match one of the `config.content_type` values exactly.
For a configuration that caches successful GET responses, see [Cache responses to successful GET requests](/ai-gateway/policies/proxy-cache-advanced/examples/cache-get-responses/).

### Storage strategies

The [`config.strategy`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-strategy) setting chooses where {{site.ai_gateway}} stores cache entries:

* `memory`: {{site.ai_gateway}} stores entries in the memory of the data plane node.
* `redis`: {{site.ai_gateway}} stores each entry as a hash in a Redis database.
  Set the connection in [`config.redis`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-redis), for example `config.redis.host` and `config.redis.port`.
  The Redis entry expires after `config.cache_ttl` seconds, or after [`config.storage_ttl`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-storage-ttl) seconds when you set it.
  For a Redis configuration, see [Cache responses with Redis](/ai-gateway/policies/proxy-cache-advanced/examples/redis-strategy/).

If Redis fails, for example when the database is down, the result depends on [`config.bypass_on_err`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-bypass-on-err):

* When `true`, {{site.ai_gateway}} sends the request upstream and sets `X-Cache-Status: Bypass`. See [Keep serving requests when Redis fails](/ai-gateway/policies/proxy-cache-advanced/examples/redis-bypass-on-error/).
* When `false` or unset, {{site.ai_gateway}} returns a `502` response.

### Storage TTL

The `config.storage_ttl` setting keeps entries in the Redis database for longer than `config.cache_ttl`.
When an entry is older than `config.cache_ttl` and `config.cache_control` is `false`, the next request goes to the upstream.
{{site.ai_gateway}} replaces the entry with the response and sets the `X-Cache-Status` header to `Refresh`.

### Cache key

{{site.ai_gateway}} builds the cache key from the following parts of the request:

* The request method and path
* The query parameters
* The request headers listed in [`config.vary_headers`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-vary-headers)
* The authenticated AI Consumer, when the request is authenticated
* The authenticated principal, when [`config.cache_by_principal`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-cache-by-principal) is `true`. See [Cache by principal](/ai-gateway/policies/proxy-cache-advanced/examples/cache-by-principal/).

Use these settings to control which requests share a cache entry:

* By default, all query parameters are part of the key.
  Set [`config.vary_query_params`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-vary-query-params) to use only the listed parameters.
* By default, the path is case-sensitive.
  Set [`config.ignore_uri_case`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-ignore-uri-case) to `true` to treat `/Items` and `/items` as the same path.
* By default, request headers aren't part of the key.
  List the headers that change the response in `config.vary_headers`.

{{site.ai_gateway}} returns the key of each request in the `X-Cache-Key` response header.

### Cache control

The [`config.cache_control`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-cache-control) setting controls whether the policy follows the `Cache-Control` header defined in [RFC 7234](https://datatracker.ietf.org/doc/html/rfc7234#section-5.2).
Set it to `true` to turn this on.

When `config.cache_control` is `true`:

* A request with `Cache-Control: no-cache` skips the cache.
* Without `config.storage_ttl`, an entry expires when the `max-age` directive of the upstream response runs out.

### Cache status

{{site.ai_gateway}} reports the cache result in the `X-Cache-Status` response header:

* `Miss`: The request matches the policy configuration, but an entry doesn't exist. {{site.ai_gateway}} sent the request upstream and stored the response.
* `Hit`: {{site.ai_gateway}} served the response from the cache. The `age` header shows how many seconds ago the entry was stored.
* `Refresh`: The entry was older than `config.cache_ttl`. {{site.ai_gateway}} sent the request upstream and replaced the entry.
* `Bypass`: The policy didn't use the cache, for example because the request method, response status code, or response content type isn't in the policy configuration.

To remove a header from responses, set `X-Cache-Key`, `X-Cache-Status`, or `age` in [`config.response_headers`](/ai-gateway/policies/proxy-cache-advanced/reference/#schema--config-response-headers) to `false`.

## Scopes

You can apply the Proxy Cache Advanced Policy globally, or attach it to an [AI Model](/ai-gateway/entities/ai-model/), an AI Agent, an AI MCP Server, an AI Consumer, or an AI Consumer Group.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

Global scope applies the policy to all traffic, so use it only when every entity needs the same caching.

* At AI Agent and AI MCP Server scope, the policy caches responses for requests to that entity.
  Use this scope to cache the traffic of one entity.
* At AI Consumer and AI Consumer Group scope, the policy caches responses for authenticated requests from that Consumer or from members of that group.
  Use this scope when only some clients need caching.
* At AI Model scope, {{site.ai_gateway}} sends every request to the upstream.
  See [Limitations](#limitations).

## Execution order

The Proxy Cache Advanced Policy has a priority of 100.
For details, see [AI Policy priority](/ai-gateway/entities/ai-policy/#ai-policy-priority).

Authentication and policies with a higher priority run before the cache.
For example, an unauthenticated request receives a `401` response, and the [IP Restriction Policy](/ai-gateway/policies/ip-restriction/) rejects a denied client even when a cached entry exists.

A [Request Termination Policy](/ai-gateway/policies/request-termination/) has a lower priority, so it runs after the cache.
A request that hits the cache returns the cached response even when it carries the trigger header of the Request Termination Policy.

## Limitations

* {{site.ai_gateway}} doesn't have an endpoint to look up, delete, or purge cache entries.
  To clear an entry, wait for `config.cache_ttl`, or `config.storage_ttl` when you set it, to expire.
* At AI Model scope, the policy sets `X-Cache-Status: Bypass` on every response and {{site.ai_gateway}} sends every request to the upstream, so AI Model responses are never cached.
