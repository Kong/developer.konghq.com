---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Cache upstream responses in memory and serve repeated requests without calling the upstream again.'
categories:
  - traffic-control
tags:
  - traffic-control
  - caching
  - ai
search_aliases:
  - proxy-cache
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
---

Repeating the same request to a slow, rate-limited, or per-request-billed upstream wastes time and money.
The Proxy Cache [AI Policy](/ai-gateway/entities/ai-policy/) stores upstream responses in memory and serves repeated requests from the cache.
{{site.ai_gateway}} serves the cached response until the entry expires.

The policy caches a response when the request method, the response status code, and the response content type all match the policy configuration.

The [Proxy Cache Advanced Policy](/ai-gateway/policies/proxy-cache-advanced/) extends the Proxy Cache Policy with Redis, Redis Cluster, and Redis Sentinel support.

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
  - usecase: Responses differ by tenant or page
    description: Add the headers or query parameters that change the response to the cache key, so each variation gets its own entry.
  - usecase: Clients must be able to request fresh data
    description: Turn on [`config.cache_control`](/ai-gateway/policies/proxy-cache/reference/#schema--config-cache-control) so a client `Cache-Control` request header can skip the cache.
  - usecase: Only some clients need caching
    description: Attach the policy to an [AI Consumer](/ai-gateway/entities/ai-consumer/) or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) instead of the AI Agent or an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).
  - usecase: You need to know where a response came from
    description: Read the `X-Cache-Status` response header to see whether {{site.ai_gateway}} served the response from the cache.
{% endtable %}
<!--vale on-->

## How does the Proxy Cache Policy work?

When a request matches the policy, {{site.ai_gateway}} builds a cache key and looks it up in memory.
If an entry exists, {{site.ai_gateway}} returns it without calling the upstream.
If not, {{site.ai_gateway}} sends the request upstream and stores the response when it meets the policy configuration.

The policy stores entries for the number of seconds set in [`config.cache_ttl`](/ai-gateway/policies/proxy-cache/reference/#schema--config-cache-ttl).
After an entry expires, the next request goes to the upstream and the response replaces the entry.

### What does the policy cache?

By default, the policy caches responses that meet all of the following conditions:

* The request method is `GET` or `HEAD`, as set in [`config.request_method`](/ai-gateway/policies/proxy-cache/reference/#schema--config-request-method).
* The response status code is `200`, `301`, or `404`, as set in [`config.response_code`](/ai-gateway/policies/proxy-cache/reference/#schema--config-response-code).
* The response content type is `application/json` or `text/plain`, as set in [`config.content_type`](/ai-gateway/policies/proxy-cache/reference/#schema--config-content-type).

The content type must match one of the listed values exactly.
To cache a streamed response, add `text/event-stream` to `config.content_type`.

Requests to AI MCP Servers use `POST`.
To cache them, add `POST` to `config.request_method`.
Because the cache key excludes the request body, add `POST` only for endpoints where the body doesn't change the response.
See [Limitations](#limitations).

### Cache key

{{site.ai_gateway}} builds the cache key from the following parts of the request:

* The request method and path
* The query parameters
* The request headers listed in [`config.vary_headers`](/ai-gateway/policies/proxy-cache/reference/#schema--config-vary-headers)
* The authenticated AI Consumer, when the request is authenticated
* The authenticated principal, when [`config.cache_by_principal`](/ai-gateway/policies/proxy-cache/reference/#schema--config-cache-by-principal) is `true`. See [Cache by Principal](/ai-gateway/policies/proxy-cache/examples/cache-by-principal/).

Use these settings to control which requests share a cache entry:

* By default, all query parameters are part of the key.
  Set [`config.vary_query_params`](/ai-gateway/policies/proxy-cache/reference/#schema--config-vary-query-params) to use only the listed parameters.
* By default, the path is case-sensitive.
  Set [`config.ignore_uri_case`](/ai-gateway/policies/proxy-cache/reference/#schema--config-ignore-uri-case) to `true` to treat `/Items` and `/items` as the same path.
* By default, no request headers are part of the key.
  List the headers that change the response in `config.vary_headers`.

{{site.ai_gateway}} returns the key of each request in the `X-Cache-Key` response header.


### Cache status

{{site.ai_gateway}} reports the cache result in the `X-Cache-Status` response header:

* `Miss`: The request matches the policy configuration, but no entry exists. {{site.ai_gateway}} sent the request upstream and stored the response.
* `Hit`: {{site.ai_gateway}} served the response from the cache. The `age` header shows how many seconds ago the entry was stored.
* `Bypass`: The policy didn't use the cache, for example because the request method, response status code, or response content type isn't in the policy configuration.

To remove a header from responses, set `X-Cache-Key`, `X-Cache-Status`, or `age` in [`config.response_headers`](/ai-gateway/policies/proxy-cache/reference/#schema--config-response-headers) to `false`.


## Scopes

You can apply the Proxy Cache Policy globally, or attach it to an [AI Model](/ai-gateway/entities/ai-model/), an AI Agent, an AI MCP Server, an AI Consumer, or an AI Consumer Group.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

Attach the policy to an AI Agent or an AI MCP Server to cache the traffic of one entity.
Attach it to an AI Consumer or an AI Consumer Group when only some clients need caching.

* With an AI Agent and AI MCP Server scope, the policy caches responses for requests to that entity.
* At AI Consumer and AI Consumer Group scope, the policy caches responses only for authenticated requests from that Consumer or from members of that group.
  Requests from other clients are sent to the upstream.
* With an AI Model scope, {{site.ai_gateway}} sends every request to the upstream.
  See [Limitations](#limitations).

## Execution order

The Proxy Cache Policy has a priority of 100.
For details, see [AI Policy priority](/ai-gateway/entities/ai-policy/#ai-policy-priority).

Authentication and policies with a higher priority run before the cache.
For example, an unauthenticated request receives a `401` response, and the [IP Restriction Policy](/ai-gateway/policies/ip-restriction/) rejects a denied client even when a cached entry exists.

A [Request Termination Policy](/ai-gateway/policies/request-termination/) has a lower priority, so it runs after the cache.
A request that hits the cache returns the cached response even when it carries the trigger header of the Request Termination Policy.

## Limitations

* The policy stores entries in memory only.
  The only supported value for [`config.strategy`](/ai-gateway/policies/proxy-cache/reference/#schema--config-strategy) is `memory`.
* To clear an entry, wait for `config.cache_ttl` to expire.
  The {{site.ai_gateway}} API doesn't have an endpoint to look up, delete, or purge cache entries.
* When it's scoped to an AI Model, the policy sets `X-Cache-Status: Bypass` on every response and {{site.ai_gateway}} sends every request to the upstream, so {{site.ai_gateway}} doesn't cache AI Model responses.
  This applies to chat completion requests, with and without streaming.
* The cache key is built without the request body.
  At AI Agent and AI MCP Server scope, `POST` requests to the same path with different bodies share one cache entry, so the cached response answers all of them until it expires.
