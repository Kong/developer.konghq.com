---
title: Use AI PII Sanitizer to protect sensitive data in requests
permalink: /how-to/protect-sensitive-information-with-ai/
content_type: how_to

description: Use the AI Sanitizer plugin to protect sensitive information in requests.

entities:
  - certificate
  - service

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

plugins:
  - ai-proxy
  - ai-sanitizer

tags:
  - ai
  - security
  - openai

tldr:
  q: How can I anonymize PII in requests using AI?
  a: Start an AI PII Anonymizer service, and enable the AI Sanitizer plugin to use this service to anonymize the specified information.

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: AI PII Anonymizer service access
      include_content: prereqs/ai-sanitizer
      icon_url: /assets/icons/cloudsmith.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/ai.svg

min_version:
  gateway: '3.10'

related_resources:
  - text: Use AI PII Sanitizer plugin to protect sensitive information in responses
    url: /how-to/protect-sensitive-information-output-with-ai/
  - text: AI PII Sanitizer
    url: /plugins/ai-sanitizer/
---

## Start the Kong AI PII Sanitizer service

Make sure you have [access to the  AI PII service](#ai-pii-anonymizer-service-access), then run the following command to start it locally with Docker:

```sh
docker run --rm -p 8080:8080 docker.cloudsmith.io/kong/ai-pii/service:v0.1.2-en
```

## Enable the AI Proxy plugin

Use the following command to enable the AI Proxy plugin configured with a chat route using OpenAI:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${key}
        model:
          provider: openai
          name: gpt-4
          options:
            max_tokens: 512
            temperature: 1.0

variables:
  key:
    value: $OPENAI_API_KEY
    description: The API key to use to connect to OpenAI.
{% endentity_examples %}

## Enable the AI Sanitizer plugin

Configure the AI Sanitizer plugin to use the AI PII Anonymizer service to anonymize general information and phone numbers:

{% entity_examples %}
entities:
  plugins:
    - name: ai-sanitizer
      config:
        anonymize:
            - phone
            - general
        port: 8080
        host: host.docker.internal
        redact_type: synthetic
        stop_on_error: true
        recover_redacted: false
{% endentity_examples %}

## Validate

To validate, send a request that contains PII, for example:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    messages:
        - role: "system"
          content: "You are a helpful assistant. Please repeat the following information back to me."
        - role: "user"
          content: "My name is John Doe, my phone number is 123-456-7890."
{% endvalidation %}

If the plugin was configured correctly, you will received a response with all PII information scrubbed, for example:

```
Your name is Jesse Mason and your phone number is 001-204-028-1684x83574.
```
{:.no-copy-code}