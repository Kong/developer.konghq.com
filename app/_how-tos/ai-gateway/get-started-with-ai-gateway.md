---
title: Get started with {{site.ai_gateway}}
content_type: how_to
permalink: /ai-gateway/get-started/
description: Learn how to quickly get started with {{site.ai_gateway}}
products:
  - ai-gateway
  - gateway

works_on:
    - on-prem
    - konnect

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
    - get-started
    - ai
    - openai

tldr:
  q: What is {{site.ai_gateway}}, and how can I get started with it?
  a: |
    With {{site.ai_gateway}}, you can deploy AI infrastructure for traffic
    that is sent to one or more LLMs. This lets you semantically route, secure, observe, accelerate,
    and govern traffic using a special set of AI plugins that are bundled with {{site.base_gateway}} distributions.

    This tutorial will help you get started with {{site.ai_gateway}} by setting up the AI Proxy plugin with OpenAI.

    {:.info}
    > **Note:**
    > This quickstart runs a Docker container to explore {{ site.base_gateway }}'s capabilities.
    If you want to run {{ site.base_gateway }} as a part of a production-ready API platform, start with the [Install](/gateway/install/) page.

tools:
    - deck

prereqs:
  inline:
    - title: OpenAI
      content: |
        This tutorial uses the AI Proxy plugin with OpenAI. You'll need to [create an OpenAI account](https://auth.openai.com/create-account) and [get an API key](https://platform.openai.com/api-keys). Once you have your API key, create an environment variable:

        ```sh
        export OPENAI_API_KEY='<api-key>'
        ```

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.6'

next_steps:
  - text: Set up load balancing using AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: Cache traffic using the AI Semantic cache plugin
    url: /plugins/ai-semantic-cache/
  - text: Secure traffic with the AI Prompt Guard
    url: /plugins/ai-prompt-guard/
  - text: Provide prompt templates with AI Prompt Template
    url: /plugins/ai-prompt-template/
  - text: Programmatically inject system or assistant prompts to all incoming prompts with the AI Prompt Decorator
    url: /plugins/ai-prompt-decorator/
  - text: Learn about all the AI plugins
    url: /plugins/?category=ai

---

## Check that {{site.base_gateway}} is running

{% include how-tos/steps/ping-gateway.md %}


## Create a Gateway Service

Create a Service to contain the Route for the LLM provider:

{% entity_examples %}
entities:
    services:
    - name: llm-service
      url: http://localhost:32000
{% endentity_examples %}

The URL can point to any empty host, as it won't be used by the plugin.

## Create a Route

Create a Route for the LLM provider. In this example we're creating a chat route, so we'll use `/chat` as the path:

{% entity_examples %}
entities:
    routes:
    - name: openai-chat
      service:
        name: llm-service
      paths:
      - /chat
{% endentity_examples %}

## Enable the AI Proxy plugin

Enable the AI Proxy plugin to create a chat route:

{% entity_examples %}
entities:
    plugins:
    - name: ai-proxy
      config:
        route_type: "llm/v1/chat"
        model:
          provider: "openai"
{% endentity_examples %}

In this example, we're setting up the plugin with minimal configuration, which means:
* The client is allowed to use any model in the `openai` provider and must provide the model name in the request body.
* The client must provide an `Authorization` header with an OpenAI API key.

If needed, you can restrict the models that can be consumed by specifying the model name explicitly using the [`config.model.name`](/plugins/ai-proxy/reference/#schema--config-model-name) parameter.

You can also provide the OpenAI API key directly in the configuration with the [`config.auth.header_name`](/plugins/ai-proxy/reference/#schema--config-auth-header-name) and [`config.auth.header_value`](/plugins/ai-proxy/reference/#schema--config-auth-header-value) parameters so that the client doesn’t have to send them.

## Validate

To validate, you can send a `POST` request to the `/chat` endpoint, using the correct [input format](/plugins/ai-proxy/#input-formats).
Since we didn't add the model name and API key in the plugin configuration, make sure to include them in the request:

{% validation request-check %}
url: /chat
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  model: gpt-5-mini
  messages:
  - role: "user"
    content: "Say this is a test!"
{% endvalidation %}

You should get a `200 OK` response, and the response body should contain `This is a test`.
