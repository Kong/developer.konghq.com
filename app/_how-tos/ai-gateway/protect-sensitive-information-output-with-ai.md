---
title: Use AI PII Sanitizer plugin to protect sensitive data in responses
permalink: /ai-gateway/protect-sensitive-information-output-with-ai/
content_type: how_to

description: Use the AI PII Sanitizer plugin to protect sensitive information in responses from a Mistral LLM model.

products:
    - ai-gateway

works_on:
    - konnect

tools:
    - kongctl

tags:
  - ai
  - security
  - mistral

tldr:
  q: How can I anonymize sensitive information in API responses using AI?
  a: Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and [AI Model](/ai-gateway/entities/ai-model/) and add an [AI PII Sanitizer](/ai-gateway/policies/ai-sanitizer/) policy in `OUTPUT` mode to automatically redact or replace sensitive data in the responses from your service.

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
    - title: AI PII Anonymizer service access
      include_content: prereqs/ai-sanitizer
      icon_url: /assets/icons/cloudsmith.svg

related_resources:
  - text: Use AI PII Sanitizer plugin to protect sensitive information in responses
    url: /ai-gateway/protect-sensitive-information-with-ai/
  - text: AI PII Sanitizer
    url: /ai-gateway/policies/ai-sanitizer/

---
## Start the Kong AI PII Sanitizer service

Make sure you have [access to the  AI PII service](#ai-pii-anonymizer-service-access), then run the following command to start it locally with Docker:

```sh
docker run --rm -p 8080:8080 docker.cloudsmith.io/kong/ai-pii/service:v0.1.2-en
```

## Create the AI Model Provider, AI Model, and AI PII Sanitizer Policy

Create both an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and an [AI Model](/ai-gateway/entities/ai-model/) with a single `kongctl` apply command.

You'll also configure the [AI PII Sanitizer Policy](/ai-gateway/policies/ai-sanitizer/) to filter LLM traffic based on an existing AWS Guardrail.


```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl: { namespace: ai-gateway-get-started }

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: ai-quickstart

ai_gateway_model_providers:
  - ref: generic-openai
    name: generic-openai
    ai_gateway: ai-quickstart
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_AUTH_HEADER

ai_gateway_policies:
  - ref: my-ai-sanitizer-policy
    name: my-ai-sanitizer-policy
    ai_gateway: ai-quickstart
    type: ai-sanitizer
    enabled: true
    global: false
    config:
      anonymize:
          - all_and_credentials
        sanitization_mode: OUTPUT
        host: host.docker.internal
        port: 8080
        redact_type: placeholder
        recover_redacted: false
        stop_on_error: true


ai_gateway_models:
  - ref: my-gpt-4o
    display_name: my-gpt-4o
    name: my-gpt-4o
    ai_gateway: ai-quickstart
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route: { paths: [/] }
      model: { name_header: true }
    capabilities: [generate]
    policies: [ !ref my-ai-sanitizer-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
EOF
```

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