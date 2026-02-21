---
title: Route OpenAI chat traffic using semantic balancing and Vault-stored keys
permalink: /how-to/use-semantic-load-balancing-with-dynamic-vault-authentication/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Use the AI Proxy Advanced plugin to route chat requests to OpenAI models based on semantic intent, secured with API keys stored in HashiCorp Vault.

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.8'

series:
  id: hashicorp-vault-llms
  position: 2

plugins:
  - ai-proxy-advanced

entities:
  - vault
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I route OpenAI chat traffic with dynamic credentials from Vault?
  a: Configure the [AI Proxy Advanced plugin](/plugins/ai-proxy-advanced/) to resolve OpenAI API keys dynamically from HashiCorp Vault, then route chat traffic to the most relevant model using semantic balancing based on user input.

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

automated_tests: false
---

## Configure the plugin

We configure the **AI Proxy Advanced** plugin to route chat requests to different LLM providers based on semantic similarity, using secure API keys stored in **HashiCorp Vault**. Secrets for OpenAI and Mistral are referenced securely using the `{vault://...}` syntax. The plugin uses OpenAI’s `text-embedding-3-small` model to embed incoming requests and compares them against target descriptions in a Redis vector database. Based on this similarity, the **semantic balancer** chooses the best-matching target:
- **GPT-3.5** for programming queries.
- **GPT-4o** for prompts related to mathematics.
- **Mistral tiny** as the catchall fallback when no close semantic match is found.

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

You can test the plugin’s semantic routing logic by sending prompts that align with the intent of each configured target. The AI Proxy Advanced uses dynamic authentication to inject the appropriate API key from HashiCorp Vault based on the selected model. Responses should include the correct `"model"` value, confirming that the request was both routed and authenticated as expected.

### Programming questions

These prompts are routed to **OpenAI GPT-3.5-Turbo**, since it performs well on technical and programming-related tasks. The responses should include `"model": "gpt-3.5-turbo"`.

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: How can I build a REST API using Flask?
{% endvalidation %}
<!-- vale on -->

You can also try a question regarding debugging JavaScript code:

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: How can you effectively debug asynchronous code in JavaScript to identify where a Promise or callback might be failing?
{% endvalidation %}
<!-- vale on -->

### Math questions

These prompts should match the **OpenAI GPT-4o** target, which is designated for mathematics topics like algebra and calculus. The responses should include `"model": "gpt-4o"`.

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What is the derivative of sin(x)?
{% endvalidation %}
<!-- vale on -->

You can also try asking a question related to theorems:

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Explain me Gödel`s incompleteness theorem.
{% endvalidation %}
<!-- vale on -->

### Test fallback questions

These general-purpose or unmatched prompts are routed to **Mistral Tiny**, acting as the fallback target. The responses should include `"model": "mistral-tiny"`.

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What is Wulfila Bible?
{% endvalidation %}
<!-- vale on -->

You can also try another general question:

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Who was Edward Gibbon and what he is famous for?
{% endvalidation %}
<!-- vale on -->
