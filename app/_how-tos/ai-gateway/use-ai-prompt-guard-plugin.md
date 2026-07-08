---
title: Use AI Prompt Guard Policy to govern your LLM traffic
permalink: /ai-gateway/how-to/use-ai-prompt-guard-policy/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Prompt Guard
    url: /ai-gateway/policies/ai-prompt-guard/

description: Use the AI Prompt Guard Policy to filter LLM traffic based on regex rules that allow general IT questions and deny unsafe or off-topic content.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-provider
  - ai-model
  - ai-policy

tags:
  - ai
  - mistral

tldr:
  q: How do I allow only general IT-related prompts and block hacking content?
  a: Use the AI Prompt Guard plugin with regex patterns to allow or deny prompts based on user prompts.

tools:
  - konnect-api
  - kongctl

prereqs:
  inline:
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
major_version:
  ai-gateway: 2

---

## Configure an AI Provider


## Configure an AI Prompt Guard Policy

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

## Configure an AI Model using the AI Prompt Guard Policy

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
status_code: 400
message: prompt pattern is blocked.
{% endvalidation %}


{% endnavtab %}
{% navtab "Denied: Inappropriate and off-topic" %}

This prompt isn’t related to work and should also be blocked:

{% validation request-check %}
url: /anything
method: POST
headers:
  - ‘Content-Type:application/json’
body:
  messages:
    - role: user
      content: What’s a good line to use on a dating app?
status_code: 400
message: prompt pattern is blocked.
{% endvalidation %}


{% endnavtab %}
{% endnavtabs %}
