---
title: Use AI PII Sanitizer plugin to protect sensitive data in responses
permalink: /how-to/protect-sensitive-information-output-with-ai/
content_type: how_to

description: Use the AI PII Sanitizer plugin to protect sensitive information in responses from a Mistral LLM model.

entities:
  - certificate
  - service

products:
  - ai-gateway
  - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

plugins:
  - ai-proxy
  - ai-sanitizer
  - file-log

tags:
  - ai
  - security
  - mistral

tldr:
  q: How can I anonymize sensitive information in API responses using AI?
  a: Enable the [AI Proxy](/plugins/ai-proxy/) and then [AI PII Sanitizer](/plugins/ai-sanitizer) plugin in `OUTPUT` mode to automatically redact or replace sensitive data in the responses from your service. Then, use [File Log](/plugins/file-log) plugin to audit what PII data was sanitized.

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg
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
  gateway: '3.12'

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

Use the AI Proxy plugin to connect to Mistral:

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
          provider: mistral
          name: mistral-tiny
          options:
            mistral_format: openai
            upstream_url: https://api.mistral.ai/v1/chat/completions

variables:
  key:
    value: $MISTRAL_API_KEY
    description: The API key to connect to OpenAI.
{% endentity_examples %}

## Enable the AI PII Sanitizer plugin for output

Configure the AI PII Sanitizer plugin to sanitize **all sensitive data in responses**, using placeholders in the output, pointing to your local Docker host where the PII Sanitizer service container works:

{% entity_examples %}
entities:
  plugins:
    - name: ai-sanitizer
      config:
        anonymize:
          - all_and_credentials
        sanitization_mode: OUTPUT
        host: host.docker.internal
        port: 8080
        redact_type: placeholder
        recover_redacted: false
        stop_on_error: true
{% endentity_examples %}

## Configure the File Log plugin

To inspect what the AI PII Sanitizer plugin redacts, we can configure the [File Log](/plugins/file-log/) plugin. It records each sanitization event, including the original sensitive items, how they were replaced, and the number of occurrences. This makes it easy to audit what was sanitized and verify the AI PII Sanitizer plugin’s behavior.

{% entity_examples %}
entities:
    plugins:
        - name: file-log
          config:
            path: "/tmp/file.json"
{% endentity_examples %}

## Validate

Send a request that would normally include sensitive information in the response:

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

If configured correctly, the response should have sensitive output data replaced with placeholders:

```
Your name is PLACEHOLDER1, and your phone number is PLACEHOLDER2.
```
{:.no-copy-code}

We can also check `file.json` to inspect the collected logs and see what PII data has been sanitized by the plugin. To do this, enter the following command in your terminal to access the log file within your Docker container:

```sh
docker exec kong-quickstart-gateway cat /tmp/file.json | jq
```

This should give you the following output:

```json
"ai": {
  "sanitizer": {
    "sanitized_items": [
      {
        "original_text": "John Doe",
        "entity_type": "PERSON",
        "redact_text": "PLACEHOLDER1",
        "count": 1
      },
      {
        "original_text": "123-456-7890",
        "entity_type": "PHONE_NUMBER",
        "redact_text": "PLACEHOLDER2",
        "count": 1
      }
    ],
    "sanitized": 2,
    "identified": 2,
    "duration": 24
  }
  ...
}
```