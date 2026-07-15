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

---

## Create an AI Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection to OpenAI and store your authentication credentials:

First, set the `OPENAI_AUTH_HEADER` environment variable to your OpenAI API key:

```sh
export OPENAI_AUTH_HEADER="Bearer YOUR_OPENAI_API_KEY"
```

Then, apply the configuration using `kongctl`:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: ai-quickstart
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
        - name: Authorization
          value: !env OPENAI_AUTH_HEADER
EOF
```

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

In this example, we're setting up the AI Provider with:

* `type: openai`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-openai`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_models:
  - ref: my-gpt-4o
    ai_gateway: ai-quickstart
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
        alias: my-gpt-4o
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
    policies: []
    capabilities:
      - generate
EOF
```

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script, same as in the previous step.

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-gpt-4o`: A unique identifier for this model.
* `formats: [type: openai]`: Declares that this model accepts requests in OpenAI-compatible format.
* `config.route.paths: [/v1]`: Configures the custom base path where this model's Routes will be accessible. Clients will send requests to paths that combine this base path with capability-specific Routes.
* `capabilities: [generate]`: Enables the text generation capability. The `generate` capability creates a `/chat/completions` endpoint, so combined with your base path, clients send chat requests to `/v1/chat/completions`.
* `config.model.alias: my-gpt-4o`: Lets clients send `my-gpt-4o` in the request `model` field instead of the upstream model name.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: generic-openai` references the AI Provider we created earlier, and `name: gpt-4o` specifies which OpenAI model to call upstream.

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
  model: my-gpt-4o
{% endvalidation %}
<!-- vale on -->
