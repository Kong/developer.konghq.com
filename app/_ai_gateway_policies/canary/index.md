---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Gradually roll out a new upstream to a subset of requests for your AI Models, AI Agents, and AI MCP Servers.'
categories:
  - traffic-control
tags:
  - traffic-control
  - upgrade
  - ai
search_aliases:
  - canary
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
---

If you're moving to a new provider endpoint or upstream version, switching all traffic in one step puts every client at risk if the new upstream misbehaves.
The Canary Release [AI Policy](/ai-gateway/entities/ai-policy/) sends a share of requests to a second upstream instead of the one configured on the entity.
This lets you try the new upstream on a small group of clients first, then increase the share or roll back by removing the policy.

## How does the Canary Release Policy work?

The Canary Release Policy leaves the upstream configured on the entity in place as the primary upstream.
You define the canary upstream in the Policy with [`config.upstream_host`](/ai-gateway/policies/canary/reference/#schema--config-upstream-host) and [`config.upstream_port`](/ai-gateway/policies/canary/reference/#schema--config-upstream-port).
To replace the request path, set [`config.upstream_uri`](/ai-gateway/policies/canary/reference/#schema--config-upstream-uri).
For each request, the Policy selects the primary or the canary upstream.

You can control the share of requests that use the canary upstream in two ways:
- **Fixed percentage:** set [`config.percentage`](/ai-gateway/policies/canary/reference/#schema--config-percentage) to the share of requests that use the canary upstream. Use this for a trial at a steady share, such as 10% for a week.
- **Time-based rollout:** set [`config.start`](/ai-gateway/policies/canary/reference/#schema--config-start) to a Unix timestamp and [`config.duration`](/ai-gateway/policies/canary/reference/#schema--config-duration) to a number of seconds. Use this to ramp up without manual changes. All requests use the primary upstream until `start`, and the share that uses the canary upstream then increases over the duration. The Policy ignores `start` when `percentage` is set.

The following example sends 20% of requests to a canary upstream. Setting `hash` to `none` selects the upstream for each request, so even a single client sees about 20% on the canary:

{% entity_example %}
type: policy
data:
  name: canary-20-percent
  display_name: Canary 20 percent
  type: canary
  config:
    percentage: 20
    hash: none
    upstream_host: canary.example.com
    upstream_port: 443
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

The default `hash` value is `consumer`, which assigns each client to one upstream.
A single client, or all clients behind one IP address, then always use the same upstream.
For details, see [Choose how requests are grouped](#choose-how-requests-are-grouped).

## Choose how requests are grouped

The Policy assigns each request to one of [`config.steps`](/ai-gateway/policies/canary/reference/#schema--config-steps) buckets.
Each bucket uses either the primary or the canary upstream.
[`config.hash`](/ai-gateway/policies/canary/reference/#schema--config-hash) controls which requests share a bucket:

<!--vale off-->
{% table %}
columns:
  - title: Value
    key: value
  - title: Requests are grouped by
    key: grouped
  - title: Use it when
    key: use
rows:
  - value: "`consumer` (default)"
    grouped: The authenticated [AI Consumer](/ai-gateway/entities/ai-consumer/)
    use: Each client must stay on the same upstream across requests.
  - value: "`header`"
    grouped: The value of the header named in [`config.hash_header`](/ai-gateway/policies/canary/reference/#schema--config-hash-header)
    use: You want to group by something other than the AI Consumer, such as a tenant or application ID.
  - value: "`ip`"
    grouped: The client IP address
    use: Requests aren't authenticated.
  - value: "`none`"
    grouped: Nothing, requests are spread evenly
    use: The same client can use either upstream on consecutive requests, for example when you test with a single client.
{% endtable %}
<!--vale on-->

With `consumer`, `header`, or `ip`, the Policy assigns a client to the same upstream on every request.
When a bucket moves to the canary upstream, every client in that bucket moves with it.
The split is by client, so a client that sends more traffic than average skews the request split.
For example, a 50% rollout moves about half of the clients, which can be more or less than half of the requests.
With a single client or one IP address, all requests use the same upstream.

If the Policy can't identify the AI Consumer, IP address, or header value for a request, it falls back to the AI Consumer, then the IP address, then `none`.

{:.warning}
> **IP address grouping:** {{site.ai_gateway}} reads the client IP from a forwarded header only when the sender is listed in the [`trusted_ips`](/ai-gateway/configuration/#trusted-ips) Nginx property.
> Without it, all requests from behind one proxy or load balancer share an IP address, so they all belong to the same bucket.

## Let clients choose the upstream

Set [`config.canary_by_header_name`](/ai-gateway/policies/canary/reference/#schema--config-canary-by-header-name) to a header name to let clients override the rollout.
A request with the value `always` uses the canary upstream, and a request with the value `never` uses the primary upstream.

To test a canary upstream before any live traffic uses it, set `percentage` to `0` and send `always` from your test client.

## What changes on a canary request

The Policy replaces only the destination host and port, plus the path when you set `upstream_uri`.
The rest of the request depends on the entity:

- **AI Model:** the request keeps the provider's hostname in the `Host` header and TLS server name, for example `api.openai.com`. It also keeps the provider's path, for example `/v1/chat/completions`, unless you set `upstream_uri`.
- **AI Agent:** the request uses the canary host and port in the `Host` header.

For an AI Model, the canary upstream must serve a TLS certificate that's valid for the provider's hostname and trusted by the data plane.
The canary upstream must also accept the provider's request format.

If you set `upstream_uri` without `upstream_host`, requests that use the canary upstream still go to the original host, at the new path.

## Scopes

Apply the Canary Release Policy to an [AI Model](/ai-gateway/entities/ai-model/), an [AI Agent](/ai-gateway/entities/ai-agent/), an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), or globally.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

Streaming responses from the canary upstream work the same way as streaming responses from the primary upstream.

{:.warning}
> **Global scope:** A global Canary Release Policy applies to every AI Model, AI Agent, and AI MCP Server on the data plane.
> To limit the effect, set `percentage` to `0` and `canary_by_header_name`, so only requests with the override header use the canary upstream.

## Finish or roll back the rollout

When the canary share reaches 100% and you're satisfied with the new upstream, point the entity at the new upstream and remove the Policy.
To roll back at any time, remove the Policy or set `percentage` to `0`.
Removing the Policy sends all traffic back to the primary upstream immediately.

## Limitations

- The Policy ignores [`config.upstream_fallback`](/ai-gateway/policies/canary/reference/#schema--config-upstream-fallback). When the canary upstream is unreachable, the request fails with a `502` status code.
- The policy doesn't health check the canary upstream. Monitor it separately before you increase the percentage.
