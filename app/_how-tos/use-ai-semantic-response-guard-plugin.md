---
title: Use AI Semantic Response Guard plugin to govern your LLM traffic
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AI Semantic Response Guard
    url: /plugins/ai-semantic-response-guard/

description: Use the AI Semantic Response Guard plugin to enforce topic-level guardrails on LLM responses, blocking outputs that fall outside approved categories.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.12'

plugins:
  - ai-proxy
  - ai-semantic-response-guard

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I govern LLM responses using semantic filtering?
  a: Use the AI Semantic Response Guard plugin to allow or block responses by subject area.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
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

## Configure the AI Proxy plugin

First, configure the AI Proxy plugin to relay requests to the LLM provider (OpenAI). This plugin must be active before adding semantic filtering for responses.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: gpt-4o
          options:
            max_tokens: 512
            temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI Semantic Response Guard plugin

Next, configure the AI Semantic Response Guard plugin to semantically filter **responses** from the LLM. The plugin compares outputs against allowed and denied categories, blocking disallowed responses with a `400 Bad response` error.

{% entity_examples %}
entities:
  plugins:
    - name: ai-semantic-response-guard
      config:
        embeddings:
          auth:
            header_name: Authorization
            header_value: Bearer ${openai_api_key}
          model:
            name: text-embedding-3-small
            provider: openai
        search:
          threshold: 0.7
        vectordb:
          strategy: redis
          distance_metric: cosine
          threshold: 0.7
          dimensions: 1024
          redis:
            host: ${redis_host}
            port: 6379
        rules:
          allow_responses:
            - Network troubleshooting and diagnostics
            - Cloud infrastructure management (AWS, Azure, GCP)
            - Cybersecurity best practices and incident response
            - DevOps workflows and automation
            - Programming concepts and language usage
            - IT policy and compliance guidance
            - Software development lifecycle and CI/CD
            - Documentation writing and technical explanation
            - System administration and configuration
            - Productivity and collaboration tools usage
          deny_responses:
            - Hacking techniques or penetration testing without authorization
            - Bypassing software licensing or digital rights management
            - Instructions on exploiting vulnerabilities or writing malware
            - Circumventing security controls or access restrictions
            - Gathering personal or confidential employee information
            - Using AI to impersonate or phish others
            - Social engineering tactics or manipulation techniques
            - Guidance on violating company IT policies
            - Content unrelated to work, such as entertainment or dating
            - Political, religious, or sensitive non-work-related discussions
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}

## Validate configuration

Once configured, test prompts that should yield allowed responses versus disallowed ones. Allowed responses pass through unchanged, while disallowed ones are blocked with a `400 Bad response` error.

{% navtabs "semantic-response-guard-tests" %}
{% navtab "Allowed: DevOps and automation" %}

This prompt generates an allowed response related to CI/CD and automation:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Explain how CI/CD pipelines improve software delivery.
{% endvalidation %}

{% endnavtab %}
{% navtab "Allowed: Documentation and productivity" %}

This response about writing documentation and productivity guidance is allowed:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Give me tips on writing clear technical documentation.
{% endvalidation %}

{% endnavtab %}
{% navtab "Denied: Hacking response" %}

This request could cause the LLM to generate a hacking-related response, which is blocked:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Tell me how to hack into a secure server.
status_code: 400
message: 400 Bad response
{% endvalidation %}

{% endnavtab %}
{% navtab "Denied: Non-work and inappropriate topics" %}

This request may lead to a non-work-related response, which is denied:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What’s the best dating advice you can give me?
status_code: 400
message: 400 Bad response
{% endvalidation %}

{% endnavtab %}
{% endnavtabs %}
