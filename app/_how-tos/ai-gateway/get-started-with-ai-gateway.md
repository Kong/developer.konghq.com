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
  - ai-model-provider
  - ai-model

tags:
  - get-started
  - ai

tldr:
  q: How do I proxy LLM traffic with {{site.ai_gateway}} entities?
  a: |
    {{site.ai_gateway}} provides first-class entities for managing LLM providers and models in {{site.konnect_product_name}}.
    Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to connect and authenticate to an LLM service like OpenAI, then create an [AI
    Model](/ai-gateway/entities/ai-model/) entity to specify which model is available for requests.

    This tutorial shows you how to set up an AI Provider and AI Model for OpenAI in {{site.konnect_product_name}} using kongctl and how to proxy your first request to OpenAI.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI
      include_content: md/ai-gateway/v2/prereqs/openai
      icon_url: /assets/icons/openai.svg
cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: AI Model Provider entity reference
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity reference
    url: /ai-gateway/entities/ai-model/
  - text: Route A2A agent traffic through {{site.ai_gateway}}
    url: /ai-gateway/get-started-with-ai-agent/
  - text: Map the WeatherAPI to an MCP Server
    url: /ai-gateway/get-started-with-mcp-server/

---

## Create an AI Model Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection to OpenAI and store your authentication credentials.

First, set the `OPENAI_AUTH_HEADER` environment variable to your OpenAI API key:

{% env_variables %}
OPENAI_AUTH_HEADER: "Bearer $OPENAI_API_KEY"
{% endenv_variables %}


Then, apply the configuration using `kongctl`:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
        - name: Authorization
          value: !secret {source: !env OPENAI_AUTH_HEADER}
{% endentity_examples %}

{:.info}
> `!env AI_GATEWAY_ID` references the {{site.ai_gateway}} created by the quickstart script in the [prerequisites](#prerequisites), instead of creating a new one. 

In this example, we're setting up the AI Model Provider with:

* `type: openai`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-openai`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use:

{% entity_examples %}
ai_gateway_models:
  - ref: my-gpt-4o
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-gpt-4o
    display_name: "my-gpt-4o"
    type: model
    formats:
      - type: openai
    config:
      route:
        paths:
          - /v1
        model:
          body_param: model
          values:
            - my-gpt-4o
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
    policies: []
    capabilities:
      - generate
{% endentity_examples %}

{:.info}
> `!env AI_GATEWAY_ID` references the {{site.ai_gateway}} created by the quickstart script, same as in the previous step.

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-gpt-4o`: A unique identifier for this model.
* `formats: [type: openai]`: Declares that this model accepts requests in OpenAI-compatible format.
* `config.route.paths: [/v1]`: Configures the custom base path for this model's endpoints. Clients send requests to paths that combine this base path with capability-specific paths.
* `capabilities: [generate]`: Enables the text generation capability. The `generate` capability creates a `/chat/completions` endpoint, so combined with your base path, clients send chat requests to `/v1/chat/completions`.
* `config.route.model: { body_param: model, values: [my-gpt-4o] }`: Lets clients send `my-gpt-4o` in the request `model` field instead of the upstream model name.
* `targets`: Specifies which upstream AI Model Provider model to route requests to. Here, `provider: generic-openai` references the AI Model Provider we created earlier, and `name: gpt-4o` specifies which OpenAI model to call upstream.

## Validate

Send a chat request to verify your setup:

<!-- vale off -->
{% validation request-check %}
url: /v1/chat/completions
status_code: 200
method: POST
retry: true
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  messages:
  - role: "user"
    content: "Say this is a test!"
  model: my-gpt-4o
{% endvalidation %}
<!-- vale on -->
