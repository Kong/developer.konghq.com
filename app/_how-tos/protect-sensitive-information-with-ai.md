---
title: Use AI to protect sensitive information in requests
content_type: how_to

description: Use the AI Sanitizer plugin to protect sensitive information in requests.

entities: 
  - certificate
  - service

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

plugins:
  - ai-proxy
  - ai-sanitizer

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
      content: |
        In this tutorial, we'll use the [AI PII Anonymizer service](https://hub.docker.com/r/kong/ai-pii-service) provided by Kong. Since this Docker image is private, you need to reach out to [Kong Support](https://support.konghq.com/support/s/) to get access.

        You can also use your own service.

      icon_url: /assets/icons/ai.svg

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

---

## 1. Start the Kong AI PII Anonymizer service

Make sure you have [access to the service](#ai-pii-anonymizer-service-access) and run the following command to start it:

```sh
docker run --platform linux/x86_64 -d --name pii-service -p 9000:8080 kong/ai-pii-service 
```

## 2. Enable the AI Proxy plugin

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

## 3. Enable the AI Sanitizer plugin

Configure the AI Sanitizer plugin to use the AI PII Anonymizer service to anonymize general information and phone numbers:

{% entity_examples %}
entities:
  plugins:
    - name: ai-sanitizer
      config: 
        anonymize:
            - phone
            - general
        port: 9000
        host: host.docker.internal
        redact_type: synthetic
        stop_on_error: true
        recover_redacted: false
{% endentity_examples %}

## 4. Validate

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

The response should contain a randomized name and phone number.
