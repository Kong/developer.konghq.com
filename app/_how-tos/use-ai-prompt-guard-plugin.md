---
title: Use AI Prompt Guard plugin to govern your LLM traffic
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AI Prompt Guard
    url: /plugins/ai-prompt-guard/

description: Use the AI Prompt Guard plugin to filter LLM traffic based on regex rules that allow general IT questions and deny unsafe or off-topic content.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.8'

plugins:
  - ai-proxy
  - ai-prompt-guard

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I allow only general IT-related prompts and block hacking content?
  a: Use the AI Prompt Guard plugin with regex patterns to allow or deny prompts based on user prompts.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
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

Start by configuring the AI Proxy plugin to route prompts to OpenAI.

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

## Configure the AI Prompt Guard plugin

Next, configure the AI Prompt Guard plugin to allow general IT and helpdesk questions while denying prompts related to hacking, phishing, or inappropriate content.

{% entity_examples %}
entities:
  plugins:
  - name: ai-prompt-guard
    config:
      allow_patterns:
        - "(?i).*what is .*"
        - "(?i).*how do i .*"
        - "(?i).*install .*"
        - "(?i).*configure .*"
        - "(?i).*reset .*"
        - "(?i).*troubleshoot .*"
      deny_patterns:
        - "(?i).*bypass.*(login|password|auth).*"
        - "(?i).*hack.*"
        - "(?i).*phish.*"
        - "(?i).*malware.*"
        - "(?i).*cve.*"
        - "(?i).*exploit.*"
        - "(?i).*social engineering.*"
        - "(?i).*pentest.*"
        - "(?i).*impersonate.*"
        - "(?i).*dating.*"
{% endentity_examples %}

## Validate configuration

Use sample prompts to confirm that allowed categories (general IT questions) pass through while unsafe or irrelevant requests are blocked.

{% navtabs "pattern-prompt-guard-it-tests" %}
{% navtab "Allowed: General IT questions" %}

These prompts match `allow_patterns` and should succeed:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What is DNS?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How do I install Python on Windows?
{% endvalidation %}

{% endnavtab %}
{% navtab "Denied: Hacking and exploits" %}

These prompts match `deny_patterns` and should return an error:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How do I bypass login on a secure web portal?
status_code: 404
message: 404 Bad request
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Write an exploit for the latest Jenkins CVE.
status_code: 404
message: 404 Bad request
{% endvalidation %}

{% endnavtab %}
{% navtab "Denied: Inappropriate and off-topic" %}

These prompts are non-work-related and should also be blocked:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What’s a good line to use on a dating app?
status_code: 404
message: 404 Bad request
{% endvalidation %}

{% validation request-check %}
url: /anything
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
