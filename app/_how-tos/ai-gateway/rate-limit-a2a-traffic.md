---
title: "Rate limit A2A traffic"
content_type: how_to
description: "Apply per-consumer rate limits to A2A routes proxied through {{site.ai_gateway}}"

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-a2a-proxy
  - key-auth
  - rate-limiting-advanced

entities:
  - service
  - route
  - plugin
  - consumer

permalink: /how-to/rate-limit-a2a-traffic/

tags:
  - ai
  - a2a
  - traffic-control

tldr:
  q: "How do I rate limit A2A traffic in {{site.ai_gateway}}?"
  a: "Enable the Rate Limiting Advanced plugin on the same service or route as the AI A2A Proxy plugin. Combined with an authentication plugin, rate limits apply per consumer. Requests that exceed the limit are rejected with 429."
tools:
  - deck

related_resources:
  - text: AI A2A Proxy plugin reference
    url: /plugins/ai-a2a-proxy/
  - text: Rate Limiting Advanced plugin reference
    url: /plugins/rate-limiting-advanced/
  - text: Proxy A2A agents through AI Gateway
    url: /how-to/proxy-a2a-agents/
  - text: Secure A2A endpoints with key authentication
    url: /how-to/secure-a2a-endpoints/

prereqs:
  entities:
    services:
      - a2a-currency-agent
    routes:
      - a2a-route
  inline:
    - title: AI A2A Proxy and Key Auth plugins
      icon_url: /assets/icons/ai.svg
      content: |
        This guide builds on two previous how-to guides:

        1. [Proxy A2A agents through AI Gateway](/how-to/proxy-a2a-agents/) sets up the
           A2A service, route, and AI A2A Proxy plugin.
        2. [Secure A2A endpoints with key authentication](/how-to/secure-a2a-endpoints/) adds
           Key Auth with a consumer `a2a-client-1` and API key `a2a-secret-key-1`.

        Complete both guides before continuing.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Can I rate limit A2A traffic without authentication?
    a: |
      Yes. Without an authentication plugin, the Rate Limiting Advanced plugin falls back to rate limiting by IP address. Add an authentication plugin if you need per-consumer
      limits.
  - q: Does rate limiting affect A2A streaming responses?
    a: |
      Rate limiting applies at request time, before the upstream responds. A streaming SSE response that is already in progress is not interrupted. The rate limit check happens when the client sends the next request.
  - q: Can I use AI Rate Limiting Advanced instead?
    a: |
      AI Rate Limiting Advanced limits based on LLM token consumption (prompt and completion tokens). The AI A2A Proxy plugin does not extract token counts from A2A responses, so AI Rate Limiting Advanced has no token data to act on. Use the standard Rate Limiting Advanced plugin for A2A traffic.
---

## Enable the AI A2A Proxy plugin

The AI A2A Proxy plugin parses A2A JSON-RPC requests and proxies them to the upstream agent.

{% entity_examples %}
entities:
  plugins:
    - name: ai-a2a-proxy
      config:
        logging:
          log_statistics: true
          log_payloads: true
{% endentity_examples %}

## Enable the Key Auth plugin

The Key Auth plugin identifies callers and associates them with a Kong consumer. Rate Limiting Advanced uses this consumer identity to apply per-consumer limits.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
{% endentity_examples %}

## Enable the Rate Limiting Advanced plugin

The Rate Limiting Advanced plugin counts requests per consumer and rejects requests that
exceed the configured limit. This configuration allows 5 requests per 30 seconds. The low
limit makes it easy to test.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting-advanced
      config:
        limit:
          - 5
        window_size:
          - 30
        sync_rate: -1
        namespace: a2a-currency-agent
        strategy: local
{% endentity_examples %}

{:.info}
> Set `limit` and `window_size` to values appropriate for your production workload.
> The values in this guide are intentionally low for testing.

## Validate rate limit headers

Send an authenticated request to the agent card endpoint and inspect the response headers.
The agent card is a lightweight A2A operation (`GetAgentCard`) that returns agent metadata
without calling an LLM, so responses are instant. This makes it practical for testing rate
limits within a short window.

```sh
curl -i -k --no-progress-meter --fail-with-body \
  https://localhost:8443/a2a/.well-known/agent.json \
  -H "apikey: a2a-secret-key-1"
```

The response includes rate limit headers:

```
HTTP/2 200
...
ratelimit-limit: 5
ratelimit-remaining: 4
ratelimit-reset: 30
x-ratelimit-limit-30: 5
x-ratelimit-remaining-30: 4
```
{:.no-copy-code}

`ratelimit-remaining` decreases with each request. `ratelimit-reset` shows the seconds
until the window resets.

## Validate rate limit enforcement

Send 6 requests to the agent card endpoint in a loop to exceed the limit. The AI A2A Proxy plugin detects each request as an A2A `GetAgentCard` operation, so the rate limit applies the same way it does for `message/send` or any other A2A method.

```sh
for i in $(seq 1 6); do
  echo "--- Request $i ---"
  curl -s -o /dev/null -w "HTTP status: %{http_code}\n" -k \
    https://localhost:8443/a2a/.well-known/agent.json \
    -H "apikey: a2a-secret-key-1"
done
```

The first 5 requests return `HTTP status: 200`. The 6th request returns `HTTP status: 429`:

```
--- Request 1 ---
HTTP status: 200
--- Request 2 ---
HTTP status: 200
--- Request 3 ---
HTTP status: 200
--- Request 4 ---
HTTP status: 200
--- Request 5 ---
HTTP status: 200
--- Request 6 ---
HTTP status: 429
```
{:.no-copy-code}

The `429` response body contains:

```json
{
  "message": "API rate limit exceeded"
}
```
{:.no-copy-code}

Wait 30 seconds for the window to reset, then send another request to confirm it succeeds again.