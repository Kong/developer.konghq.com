---
title: Use AI PII Sanitizer to protect sensitive data in requests
permalink: /ai-gateway/protect-sensitive-information-with-ai/
content_type: how_to

description: Use the AI Sanitizer plugin to protect sensitive information in requests.

products:
    - ai-gateway

works_on:
    - konnect

tools:
    - kongctl

tags:
  - ai
  - security
  - openai

tldr:
  q: How can I anonymize PII in requests using AI?
  a: Start an AI PII Anonymizer service, and enable the AI Sanitizer policy to use this service to anonymize the specified information.

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
    - title: AI PII Anonymizer service access
      include_content: prereqs/ai-sanitizer
      icon_url: /assets/icons/cloudsmith.svg

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: Use AI PII Sanitizer plugin to protect sensitive information in responses
    url: /ai-gateway/protect-sensitive-information-output-with-ai/
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
            - phone
            - general
        port: 8080
        host: host.docker.internal
        redact_type: synthetic
        stop_on_error: true
        recover_redacted: false


ai_gateway_models:
  - ref: my-gpt-4o
    display_name: my-gpt-4o
    name: my-gpt-4o
    ai_gateway: ai-quickstart
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - my-gpt-4o
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

To validate, send a request that contains PII, for example:

<!-- vale off -->
{% validation request-check %}
url: /v1/chat/completions
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  messages:
  - role: "system"
    content: "You are a helpful assistant. Please repeat the following information back to me."
  - role: "user"
    content: "My name is John Doe, my phone number is 123-456-7890."
  model: my-gpt-4o
{% endvalidation %}
<!-- vale on -->

If the plugin was configured correctly, you will received a response with all PII information scrubbed, for example:

```
Your name is Jesse Mason and your phone number is 001-204-028-1684x83574.
```
{:.no-copy-code}