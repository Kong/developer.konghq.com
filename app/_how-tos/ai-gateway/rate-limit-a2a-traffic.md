---
title: "Rate limit A2A traffic"
content_type: how_to
description: "Apply rate limits to A2A routes proxied through {{site.ai_gateway}}"
permalink: /ai-gateway/rate-limit-a2a-traffic/

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - a2a
  - traffic-control

tldr:
  q: "How do I rate limit A2A traffic in {{site.ai_gateway}}?"
  a: "Create a Rate Limiting Advanced Policy and attach it to an AI Agent. Requests that exceed the limit are rejected with 429. You can combine this with an authentication policy so that rate limits apply per consumer."
tools:
  - kongctl

related_resources:
  - text: AI Agent
    url: /ai-gateway/entities/ai-agent/
  - text: Rate Limiting Advanced policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: "Proxy A2A agents through {{site.ai_gateway}}"
    url: /ai-gateway/get-started-with-ai-agent/
prereqs:
  inline:
    - title: OpenAI API key
      content: |
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        2. [Get an API key](https://platform.openai.com/api-keys).
        3. Export your key:
           ```bash
           export OPENAI_API_KEY='YOUR_OPENAI_API_KEY'
           ```
    - title: A2A agent
      include_content: md/ai-gateway/v2/prereqs/a2a-agent

cleanup:
  inline:
    - title: Stop the A2A agent
      content: |
        ```bash
        docker compose down
        docker rm -f a2a-kongair-agent
        ```
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: Can I rate limit A2A traffic without authentication?
    a: |
      Yes. Without an authentication policy, the Rate Limiting Advanced policy falls back to rate limiting by IP address. Add an authentication policy if you need per-consumer
      limits.
  - q: Does rate limiting affect A2A streaming responses?
    a: |
      Rate limiting applies at request time, before the upstream responds. A streaming SSE response that is already in progress is not interrupted. The rate limit check happens when the client sends the next request.
  - q: Can I use AI Rate Limiting Advanced instead?
    a: |
      AI Rate Limiting Advanced limits based on LLM token consumption (prompt and completion tokens). The AI Agent doesn't extract token counts from A2A responses, so an AI Rate Limiting Advanced Policy has no token data to act on. Use the standard Rate Limiting Advanced Policy for A2A traffic.

automated_tests: false

---

## Create an AI Agent and attach a rate limiting AI Policy

Create an [AI Agent](/ai-gateway/entities/ai-agent/) entity that proxies A2A traffic to your upstream agent and a [Rate Limiting Advanced Policy](/ai-gateway/policies/rate-limiting-advanced/) that counts requests per consumer and rejects requests that exceed the configured limit. 

This configuration allows 5 requests per 30 seconds. 
These settings are intentionally low to make it easy to trigger during testing. 
The AI Policy is attached to the AI Agent by using  `!ref rate-limit-bookings-agent#name` to refer to it by name.

{% entity_examples %}
ai_gateway_policies:
  - ref: rate-limit-bookings-agent
    ai_gateway: !lookup name:ai-quickstart
    name: rate-limit-bookings-agent
    display_name: "Rate limit Kong Air Flight Booking Agent"
    type: rate-limiting-advanced
    config:
      limit:
        - 5
      window_size:
        - 30
      sync_rate: -1
      namespace: a2a-kongair-agent
      strategy: local
ai_gateway_agents:
  - ref: kongair-flight-booking-agent
    ai_gateway: !lookup name:ai-quickstart
    display_name: "Kong Air Flight Booking Agent"
    type: a2a
    enabled: true
    policies:
      - !ref rate-limit-bookings-agent#name
    config:
      url: http://host.docker.internal:10000
      route:
        paths:
          - /a2a
        methods:
          - GET
          - POST
        protocols:
          - http
          - https
        strip_path: true
      logging:
        payloads: true
        statistics: true
        max_payload_size: 1048576
      max_request_body_size: 8388608
{% endentity_examples %}

{:.info}
> The `limit` and `window_size` are intentionally set low for testing.
> You should adjust these to appropriate values for production workloads.

## Validate rate limit headers

Send an authenticated request to the agent card endpoint and inspect the response headers. The agent card is a lightweight A2A operation (`GetAgentCard`) that returns agent metadata without calling an LLM, so responses are instant.

<!-- vale off -->
{% validation request-check %}
url: /a2a/.well-known/agent-card.json
display_headers: true
status_code: 200
method: GET
headers:
  - 'apikey: a2a-secret-key-1'
{% endvalidation %}
<!-- vale on -->

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

`ratelimit-remaining` decreases with each request. `ratelimit-reset` shows the seconds until the window resets.

## Validate rate limit enforcement

Send 6 requests to the agent card endpoint in a loop to exceed the limit. The AI Agent detects each request as an A2A `GetAgentCard` operation, so the rate limit applies the same way it does for `message/send` or any other A2A method.


{% konnect %}
content: |
  ```sh
  for i in $(seq 1 6); do
    echo "--- Request $i ---"
    curl -s -o /dev/null -w "HTTP status: %{http_code}\n"\
      $KONNECT_PROXY_URL/a2a/.well-known/agent-card.json \
      -H "apikey: a2a-secret-key-1"
  done
  ```
{% endkonnect %}

The first four requests return `HTTP status: 200`. The 5th request returns `HTTP status: 429`:

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
HTTP status: 429
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