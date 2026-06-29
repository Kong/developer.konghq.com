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
    Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to connect and authenticate to an LLM service like OpenAI, then create a [Model](/ai-gateway/entities/ai-model/) entity to specify which model is available for requests.

    This tutorial shows you how to set up an AI Provider and AI Model for OpenAI in {{site.konnect_product_name}} using the {{site.konnect_product_name}} API and how to proxy your first request to OpenAI.

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
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

min_version:
  ai-gateway: '2.0'

---

## Create an AI Provider entity

Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to define your connection to OpenAI and store your authentication credentials:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  type: openai
  display_name: generic-openai
  name: generic-openai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $OPENAI_API_KEY
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Provider with:

* `type: openai`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-openai`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/models
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: my-gpt-4o
  name: my-gpt-4o
  type: model
  formats:
    - type: openai
  config:
    route:
      paths:
        - /v1
    model: {}
    logging:
      payloads: false
      statistics: true
  targets:
    - name: gpt-4o
      provider: generic-openai
      config:
        type: openai
  policies: []
  capabilities:
    - generate
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-gpt-4o`: A unique identifier for this model.
* `formats: [type: openai]`: Declares that this model accepts requests in OpenAI-compatible format.
* `config.route.paths: [/v1]`: Configures the custom base path where this model's routes will be accessible. Clients will send requests to paths that combine this base path with capability-specific routes.
* `capabilities: [generate]`: Enables the text generation capability. The `generate` capability creates a `/chat/completions` endpoint, so combined with your base path, clients send chat requests to `/v1/chat/completions`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: generic-openai` references the AI Provider you created earlier, and `name: gpt-4o` specifies which OpenAI model to call upstream.
* `config.logging`: Configures what gets logged. With `statistics: true`, usage metrics (tokens, latency, cost) are logged for monitoring and billing. With `payloads: false`, full request/response bodies are not logged for privacy.

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
  messages:
  - role: "user"
    content: "Say this is a test!"
{% endvalidation %}
<!-- vale on -->
