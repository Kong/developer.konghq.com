---
title: Set up AI Proxy Advanced with OpenAI
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using OpenAI.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I use the AI Proxy Advanced plugin with OpenAI?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the OpenAI provider, the gpt-4o model, and your OpenAI API key.

tools:
  - deck

prereqs:
  inline:
    - title: Redis stack
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

We configure the **AI Proxy Advanced** plugin to route chat requests to different LLM providers based on semantic similarity, using secure API keys stored in **HashiCorp Vault**. Secrets for OpenAI and Mistral are referenced securely using the `{vault://...}` syntax. The plugin uses OpenAI’s `text-embedding-3-small` model to embed incoming requests and compares them against target descriptions using **cosine similarity** in a Redis vector database. Based on this similarity, the **semantic balancer** chooses the best-matching target: GPT-3.5 for programming queries, GPT-4o for IT support, and **Mistral Tiny** as the catchall fallback when no close semantic match is found.

{% entity_examples %}
entities:
  plugins:
  - name: ai-proxy-advanced
    config:
      embeddings:
        auth:
          header_name: Authorization
          header_value: "{vault://hashicorp-vault/openai/key}"
        model:
          provider: openai
          name: text-embedding-3-small
      vectordb:
        dimensions: 1536
        distance_metric: cosine
        strategy: redis
        threshold: 0.8
        redis:
          host: ${redis_host}
          port: 6379
      balancer:
        algorithm: semantic
      targets:
      - route_type: llm/v1/chat
        logging:
          log_payloads: true
          log_statistics: true
        auth:
          header_name: Authorization
          header_value: "{vault://hashicorp-vault/openai/key}"
        model:
          provider: openai
          name: gpt-3.5-turbo
          options:
            max_tokens: 826
            temperature: 0
            input_cost: 1.0
            output_cost: 2.0
        description: "programming, coding, software development, Python, JavaScript, APIs, debugging"
      - route_type: llm/v1/chat
        logging:
          log_payloads: true
          log_statistics: true
        auth:
          header_name: Authorization
          header_value: "{vault://hashicorp-vault/openai/key}"
        model:
          provider: openai
          name: gpt-4o
          options:
            max_tokens: 512
            temperature: 0.3
            input_cost: 1.0
            output_cost: 2.0
        description: "mathematics, algebra, calculus, trigonometry, equations, integrals, derivatives, theorems"
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: "{vault://hashicorp-vault/mistral/key}"
        model:
          provider: mistral
          name: mistral-tiny
          options:
            mistral_format: openai
            upstream_url: https://api.mistral.ai/v1/chat/completions
        description: CATCHALL
variables:
  redis_host:
    value: $DECK_REDIS_HOST
{% endentity_examples %}


## Validate configuration

You can test the plugin’s semantic routing logic by sending prompts that align with the intent of each configured target. The plugin uses dynamic authentication to inject the appropriate API key from HashiCorp Vault based on the selected model. Responses should include the correct `"model"` value, confirming that the request was both routed and authenticated as expected.

### Test programming-related questions

These prompts are routed to **OpenAI GPT-3.5-Turbo**, selected for its strong performance on technical and programming-related tasks. The response should include `"model": "gpt-3.5-turbo"`.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: How do I build a REST API using Flask?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What does the `map()` function do in Python?
{% endvalidation %}


### Test math-related questions

These prompts should match the **OpenAI GPT-4o** target, which is designated for mathematics topics like algebra and calculus. The response should include `"model": "gpt-4o"`.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What's the derivative of sin(x)?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What's the Fermat's last theorem?
{% endvalidation %}

### Test fallback questions

These general-purpose or unmatched prompts are routed to **Mistral Tiny**, acting as the fallback target. The response should include `"model": "mistral-tiny"`.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What's the capital of Argentina?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Tell me a fun fact about dolphins
{% endvalidation %}

