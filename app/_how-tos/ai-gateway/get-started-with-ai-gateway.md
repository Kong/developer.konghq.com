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
    - title: Delete the Provider and Model entities
      content: |
        Delete the Provider and Model entities you created by sending `DELETE` requests to the {{site.konnect_product_name}} API.

min_version:
  ai-gateway: '2.0.0'

---

## Create a Provider entity

Create a [Provider](/ai-gateway/entities/ai-provider/) entity to define your LLM service and store authentication credentials:

{% entity_example %}
type: ai-provider
data:
  name: openai-provider
  provider_type: openai
  config:
    auth:
      header_name: Authorization
      header_value: Bearer $OPENAI_API_KEY
{% endentity_example %}

Save the `id` from the response—you’ll need it to create Model entities.

## Create a Model entity

Create a [Model](/ai-gateway/entities/ai-model/) entity to specify which LLM models are available and declare their capabilities. Each capability generates a route on the service:

{% entity_example %}
type: model
data:
  name: gpt-4-turbo
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4-turbo
      provider:
        name: openai-provider
{% endentity_example %}

The `chat` capability creates a `/chat` route for chat completions. You can add other capabilities like `embeddings`, `assistants`, or `audio-transcriptions` as needed.

## Validate

Send a chat request to verify your setup:

{% validation request-check %}
url: /chat
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  model: gpt-4-turbo
  messages:
  - role: "user"
    content: "Say this is a test!"
{% endvalidation %}
