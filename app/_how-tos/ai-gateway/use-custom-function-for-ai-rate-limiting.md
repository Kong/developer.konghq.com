---
title: Enforce AI rate limits with a custom function
permalink: /how-to/use-custom-function-for-ai-rate-limiting/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AI Rate Limiting Advanced
    url: /plugins/ai-rate-limiting-advanced/

description: Configure the AI Proxy plugin to create a chat route using Cohere, and apply usage-based rate limiting with the AI Rate Limiting Advanced plugin.

tldr:
  q: How do I limit Cohere usage through {{site.ai_gateway}}?
  a: Set up AI Proxy to route requests to Cohere, use a custom Lua function to count tokens via the `x-prompt-count` header, and enforce usage limits with Redis-based rate limiting.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy
  - ai-rate-limiting-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tools:
  - deck

prereqs:
  inline:
    - title: Cohere
      include_content: prereqs/cohere
      icon_url: /assets/icons/cohere.svg
    - title: Redis
      include_content: prereqs/redis
      icon_url: /assets/icons/redis.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the plugin

Enable the [AI Proxy](/plugins/ai-proxy/) plugin with your Cohere API key and the model details to proxy requests to Cohere. In this example, we'll use the `command-a-03-2025` model.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${cohere_api_key}
        model:
          provider: cohere
          name: command-a-03-2025
          options:
            max_tokens: 512
            temperature: 1.0
variables:
  cohere_api_key:
    value: $COHERE_API_KEY
{% endentity_examples %}

## Configure the AI Rate Limiting Advanced plugin

Now, configure the **AI Rate Limiting Advanced** plugin. This configuration enforces usage limits on AI model requests by tracking token consumption through a custom Lua function. Rate limit counters are stored in Redis, and the `x-prompt-count` HTTP header is used to count tokens per request. This setup helps prevent quota overruns and protects your AI infrastructure from excessive usage.

{% entity_examples %}
entities:
  plugins:
    - name: ai-rate-limiting-advanced
      config:
        strategy: redis
        redis:
          host: ${redis_host}
          port: 16379
        sync_rate: 0
        llm_providers:
        - name: cohere
          limit:
          - 100
          - 1000
          window_size:
          - 60
          - 3600
        request_prompt_count_function: |
          local header_count = tonumber(kong.request.get_header("x-prompt-count"))
          if header_count then
            return header_count
          end
          return 0
variables:
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}


## Validate the configuration

Now, you can test the rate limiting configuration.

* The **first request** sends a `x-prompt-count` of `100000`, which is within the configured token limits and should receive a `200 OK` response.
* The **second request**, sent shortly after with a `x-prompt-count` of `950000`, exceeds the allowed token quota and is expected to return a `429` response.


<!--vale off-->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
  - 'x-prompt-count: 100000'
display_headers: true
body:
  messages:
    - role: system
      content: You are an IT specialist.
    - role: user
      content: Tell me about Google?
status_code: 200
message: "HTTP/1.1 200 OK"
{% endvalidation %}
<!--vale on-->

Now, you can test the rate limiting function by sending the following request:

<!--vale off-->
{% validation request-check %}
url: /anything
method: POST
display_headers: true
headers:
  - 'Content-Type: application/json'
  - 'x-prompt-count: 950000'
body:
  messages:
    - role: system
      content: You are an IT specialist.
    - role: user
      content: Tell me about Google?
status_code: 429
message: "HTTP/1.1 429 AI token rate limit exceeded for provider(s): cohere"
{% endvalidation %}
<!--vale on-->