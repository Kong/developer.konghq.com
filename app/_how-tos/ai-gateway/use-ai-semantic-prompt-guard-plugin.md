---
title: Use AI Semantic Prompt Guard plugin to govern your LLM traffic
permalink: /how-to/use-ai-semantic-prompt-guard-plugin/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AI Semantic Prompt Guard
    url: /plugins/ai-semantic-prompt-guard/

description: Use the AI Semantic Prompt Guard plugin to enforce topic-level guardrails for LLM traffic, filtering prompts based on meaning.

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.8'

plugins:
  - ai-proxy
  - ai-semantic-prompt-guard

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I govern prompt topics using semantic filtering?
  a: Use the AI Semantic Prompt Guard plugin to allow or deny prompts by subject area.

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
---

## Configure the AI Proxy plugin

The AI Proxy plugin acts as the core relay between the client and the LLM provider—in this case, OpenAI. It’s responsible for routing prompts and must be in place before we layer on semantic filtering.

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

## Configure the AI Semantic Prompt guard plugin

Now, we can set up the AI Semantic Prompt Guard plugin to semantically filter incoming prompts based on topic. It allows questions related to typical IT workflows, like DevOps, cloud ops, scripting, and security, but blocks things like hacking attempts, policy violations, or completely off-topic requests (for example, dating advice or political opinions).

{% entity_examples %}
entities:
  plugins:
    - name: ai-semantic-prompt-guard
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
          threshold: 0.5
          dimensions: 1024
          redis:
            host: ${redis_host}
            port: 6379
        rules:
          match_all_conversation_history: true
          allow_prompts:
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
          deny_prompts:
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

Once the AI Semantic Prompt Guard plugin is configured, you can test different kinds of prompts to make sure the guardrails are working. Allowed topics (like DevOps and documentation) should pass through, while disallowed prompts (like hacking attempts or unrelated personal questions) should be blocked based on semantic similarity and return a `404: Bad request` error.


{% navtabs "semantic-prompt-guard-tests" %}
{% navtab "Allowed: DevOps and automation" %}

This prompt is within allowed IT topics like automation, DevOps, and CI/CD:

{% validation request-check %}
url: /anything
display_headers: true
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What are the best tools for DevOps?
status_code: 200
{% endvalidation %}


{% endnavtab %}
{% navtab "Allowed: Productivity and documentation" %}

This prompt relates to the allowed topic about productivity tools:

{% validation request-check %}
url: /anything
display_headers: true
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What productivity tools would you recommend?
status_code: 200
{% endvalidation %}


{% endnavtab %}
{% navtab "Denied: Hacking" %}

This prompt attempts to access or modify systems without permission:

{% validation request-check %}
url: /anything
display_headers: true
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How can I bypass admin login on a web app?
status_code: 404
message: 404 Bad request
{% endvalidation %}


{% endnavtab %}
{% navtab "Denied: Non-work and inappropriate topics" %}

This prompt falls outside the scope of acceptable work-related use:


{% validation request-check %}
url: /anything
display_headers: true
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Who should I vote for in the next election?
status_code: 404
message: 404 Bad request
{% endvalidation %}

{% endnavtab %}
{% endnavtabs %}

