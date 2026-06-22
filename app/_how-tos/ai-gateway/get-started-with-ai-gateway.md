---
title: Get started with {{site.ai_gateway}}
content_type: how_to
permalink: /ai-gateway/get-started/
description: Learn how to proxy LLM traffic with {{site.ai_gateway}} entities in {{site.konnect_product_name}}
products:
  - ai-gateway

works_on:
  - konnect

entities:
  - ai-provider
  - ai-model

tags:
  - get-started
  - ai

tldr:
  q: How do I proxy LLM traffic with {{site.ai_gateway}} entities?
  a: |
    {{site.ai_gateway}} provides first-class entities for managing LLM providers and models in {{site.konnect_product_name}}.
    Create a Provider entity to connect to an LLM service like OpenAI, then create Model entities
    to specify which models are available for requests.

    This tutorial shows you how to set up a Provider and Model in {{site.konnect_product_name}} using the {{site.konnect_product_name}} API.

tools:
  - konnect-api

prereqs:
  inline:
    - title: OpenAI credentials
      content: |
        This tutorial uses OpenAI as the LLM provider. You'll need to [create an OpenAI account](https://auth.openai.com/create-account)
        and [get an API key](https://platform.openai.com/api-keys). Save your API key for the next steps:

        ```sh
        export OPENAI_API_KEY='<api-key>'
        ```
cleanup:
  inline:
    - title: Clean up {{site.konnect_product_name}} environment
      include_content: md/ai-gateway/v2/cleanup/konnect

min_version:
  ai-gateway: '2.0'

---

## Create a Provider entity

Create a [Provider](/ai-gateway/entities/ai-provider/) entity to define your LLM service and store authentication credentials:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: OpenAI Production
  name: my-openai-account
  type: openai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $OPENAI_API_KEY
{% endkonnect_api_request %}
<!-- vale on -->

Save the Provider ID from the response for cleanup:

```bash
export PROVIDER_ID=ai-provider-id
```

## Create a Model entity

Create a [Model](/ai-gateway/entities/ai-model/) entity to specify which LLM models are available and declare their capabilities. Each capability generates a route on the service:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/models
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: GPT-4o
  name: my-gpt-4o
  type: model
  enabled: true
  capabilities:
    - generate
  formats:
    - type: openai
  config:
    route:
      paths:
        - /v1
  target_models:
    - name: gpt-4o
      provider: openai-provider
{% endkonnect_api_request %}
<!-- vale on -->

Save the Model ID from the response for cleanup:

```bash
export MODEL_ID=ai-model-id
```

{:.info}
> The `generate` capability creates a `/chat/completions` route. The `paths: ["/v1"]` setting defines the base path, so the final route becomes `/v1/chat/completions`.

## Validate

Send a chat request to verify your setup:

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
  model: my-gpt-4o
  messages:
  - role: "user"
    content: "Say this is a test!"
{% endvalidation %}
<!-- vale on -->
