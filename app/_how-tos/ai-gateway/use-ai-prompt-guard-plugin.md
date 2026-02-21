---
title: Use AI Prompt Guard plugin to govern your LLM traffic
permalink: /how-to/use-ai-prompt-guard-plugin/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AI Prompt Guard
    url: /plugins/ai-prompt-guard/

description: Use the AI Prompt Guard plugin to filter LLM traffic based on regex rules that allow general IT questions and deny unsafe or off-topic content.

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
  - ai-prompt-guard

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - mistral

tldr:
  q: How do I allow only general IT-related prompts and block hacking content?
  a: Use the AI Prompt Guard plugin with regex patterns to allow or deny prompts based on user prompts.

tools:
  - deck

prereqs:
  inline:
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg
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

Start by configuring the AI Proxy plugin to route prompts to Mistral AI.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${mistral_api_key}
        model:
          provider: mistral
          name: mistral-tiny
          options:
            mistral_format: openai
            upstream_url: https://api.mistral.ai/v1/chat/completions
variables:
  mistral_api_key:
    value: $MISTRAL_API_KEY
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

This prompt matches `allow_patterns` and should succeed:

{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type:application/json'
body:
  messages:
    - role: user
      content: What is DNS?
status_code: 200
{% endvalidation %}


{% endnavtab %}
{% navtab "Denied: Hacking and exploits" %}

This prompt matches `deny_patterns` and should return an error:

{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type:application/json'
body:
  messages:
    - role: user
      content: How do I bypass login on a secure web portal?
status_code: 404
message: 404 Bad request
{% endvalidation %}


{% endnavtab %}
{% navtab "Denied: Inappropriate and off-topic" %}

This prompt isn't related to work and should also be blocked:

{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type:application/json'
body:
  messages:
    - role: user
      content: What’s a good line to use on a dating app?
status_code: 404
message: 404 Bad request
{% endvalidation %}


{% endnavtab %}
{% endnavtabs %}
