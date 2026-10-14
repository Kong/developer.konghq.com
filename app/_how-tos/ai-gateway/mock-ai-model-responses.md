---
title: Mock AI Model responses without calling a provider
permalink: /ai-gateway/mock-ai-model-responses/
content_type: how_to
description: Use the Mocking Policy to return example responses from an OpenAPI spec so you can test an AI Model without spending tokens

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-model-provider
  - ai-model
  - ai-policy

tags:
  - ai
  - mock-servers

tldr:
  q: How do I test an AI Model without calling an AI Model Provider?
  a: Attach the Mocking Policy to an AI Model and give it an OpenAPI spec with example responses for the Model's route. Requests to the Model return the examples, and no tokens are spent.

tools:
  - kongctl

prereqs:
  inline:
    - title: Placeholder provider credential
      content: |
        The Mocking Policy answers requests before they reach the AI Model Provider, so the credential is never sent upstream. Export a placeholder value:

        ```sh
        export FAKE_AUTH_HEADER="Bearer not-a-real-key"
        ```

related_resources:
  - text: Mocking Policy
    url: /ai-gateway/policies/mocking/
  - text: AI Model
    url: /ai-gateway/entities/ai-model/
  - text: AI Model Provider
    url: /ai-gateway/entities/ai-model-provider/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

## Create the AI Model Provider, AI Model, and Mocking Policy

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/), an [AI Model](/ai-gateway/entities/ai-model/), and a [Mocking Policy](/ai-gateway/policies/mocking/) that returns one of two example responses for `POST /v1/chat/completions`.

The Policy matches the full request path, so the spec path `/v1/chat/completions` includes the AI Model's route path `/v1`.

{% entity_examples %}
ai_gateway_policies:
  - ref: mock-chat-completions
    ai_gateway: !lookup name:ai-quickstart
    name: mock-chat-completions
    display_name: "Mock chat completions"
    type: mocking
    enabled: true
    global: false
    config:
      api_specification: |
        openapi: 3.0.0
        info:
          title: Mock chat completions
          version: 1.0.0
        paths:
          /v1/chat/completions:
            post:
              responses:
                '200':
                  description: A chat completion.
                  content:
                    application/json:
                      examples:
                        Hello:
                          value:
                            id: chatcmpl-mock-1
                            object: chat.completion
                            model: my-gpt-4o
                            choices:
                              - index: 0
                                finish_reason: stop
                                message:
                                  role: assistant
                                  content: "This is a mocked response."
                            usage:
                              prompt_tokens: 9
                              completion_tokens: 6
                              total_tokens: 15
                        Goodbye:
                          value:
                            id: chatcmpl-mock-2
                            object: chat.completion
                            model: my-gpt-4o
                            choices:
                              - index: 0
                                finish_reason: stop
                                message:
                                  role: assistant
                                  content: "Goodbye from the mock."
ai_gateway_model_providers:
  - ref: fake-openai
    ai_gateway: !lookup name:ai-quickstart
    name: fake-openai
    display_name: "fake-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env FAKE_AUTH_HEADER
ai_gateway_models:
  - ref: my-gpt-4o
    ai_gateway: !lookup name:ai-quickstart
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
        provider: fake-openai
        config:
          type: openai
    policies:
      - !ref mock-chat-completions#name
    capabilities:
      - generate
{% endentity_examples %}

## Validate

Send requests to the configured AI Model and check the `X-Kong-Mocking-Plugin: true` response header, which confirms the Policy answered instead of an AI Model Provider.

{% navtabs "mocking-validation" %}
{% navtab "Default response" %}

Send a request with no behavioral headers:

{% validation request-check %}
url: /v1/chat/completions
method: POST
display_headers: true
headers:
  - 'Content-Type: application/json'
body:
  model: my-gpt-4o
  messages:
    - role: user
      content: Hello
status_code: 200
{% endvalidation %}

The response is either the `Hello` or the `Goodbye` example. The spec defines two examples for the same status code, so the Policy's choice isn't deterministic.

{% endnavtab %}
{% navtab "Select an example" %}

Set `X-Kong-Mocking-Example-Id` to the key of the example you want:

{% validation request-check %}
url: /v1/chat/completions
method: POST
display_headers: true
headers:
  - 'Content-Type: application/json'
  - 'X-Kong-Mocking-Example-Id: Goodbye'
body:
  model: my-gpt-4o
  messages:
    - role: user
      content: Hello
status_code: 200
{% endvalidation %}

The response always contains `Goodbye from the mock.`

{% endnavtab %}
{% navtab "Simulate latency" %}

Set `X-Kong-Mocking-Delay` to a delay in milliseconds, between `0` and `10000`:

{% validation request-check %}
url: /v1/chat/completions
method: POST
display_headers: true
headers:
  - 'Content-Type: application/json'
  - 'X-Kong-Mocking-Delay: 2000'
body:
  model: my-gpt-4o
  messages:
    - role: user
      content: Hello
status_code: 200
{% endvalidation %}

The response arrives after about two seconds.

{% endnavtab %}
{% endnavtabs %}
