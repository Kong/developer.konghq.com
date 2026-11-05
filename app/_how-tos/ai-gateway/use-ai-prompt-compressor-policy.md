---
title: Reduce prompt size with the AI Prompt Compressor Policy
permalink: /ai-gateway/use-ai-prompt-compressor-policy/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Prompt Compressor Policy
    url: /ai-gateway/policies/ai-prompt-compressor/
  - text: AI Prompt Template Policy
    url: /ai-gateway/policies/ai-prompt-template/
  - text: AI RAG Injector Policy
    url: /ai-gateway/policies/ai-rag-injector/
  - text: Model cost management
    url: /ai-gateway/model-cost-management/

description: Use the AI Prompt Compressor Policy with the LLMLingua compressor service to shrink prompts before they reach the LLM, and combine it with an AI Prompt Template Policy that wraps client input in LLMLINGUA tags so only that input is compressed.

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
  - performance

tldr:
  q: How do I reduce the number of tokens sent to an LLM without rewriting my prompts?
  a: Run the LLMLingua compressor service, then attach an AI Prompt Compressor Policy to an AI Model. The Policy compresses prompts by a ratio that depends on their length. Add an AI Prompt Template Policy that wraps client input in `<LLMLINGUA>` tags, so only that input is compressed and the instruction stays intact.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
    - title: AI Prompt Compressor service
      include_content: md/ai-gateway/v2/prereqs/ai-prompt-compressor
      icon_url: /assets/icons/third-party/docker.svg

cleanup:
  inline:
    - title: Remove the AI Prompt Compressor service
      content: |
        ```bash
        docker rm -f compress-service
        ```
      icon_url: /assets/icons/third-party/docker.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Create the AI Model Provider, AI Model, and AI Policies

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/), an [AI Model](/ai-gateway/entities/ai-model/), and an [AI Prompt Compressor Policy](/ai-gateway/policies/ai-prompt-compressor/) that compresses prompts by ratio before the AI Model forwards them to OpenAI.
Also create an [AI Prompt Template Policy](/ai-gateway/policies/ai-prompt-template/) that wraps client input in `<LLMLINGUA>` tags, and a [File Log Policy](/ai-gateway/policies/file-log/) that records compression metrics for each request:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    name: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_policies:
  - ref: my-ai-prompt-compressor-policy
    name: my-ai-prompt-compressor-policy
    display_name: my-ai-prompt-compressor-policy
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: ai-prompt-compressor
    enabled: true
    global: false
    config:
      compressor_type: rate
      compressor_url: http://host.docker.internal:8080
      compression_ranges:
        - min_tokens: 20
          max_tokens: 100
          value: 0.8
        - min_tokens: 100
          max_tokens: 1000000
          value: 0.3
      stop_on_error: true
  - ref: my-ai-prompt-template-policy
    name: my-ai-prompt-template-policy
    display_name: my-ai-prompt-template-policy
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: ai-prompt-template
    enabled: true
    global: false
    config:
      templates:
        - name: summarize
          template: |-
            {
              "messages": [
                {
                  "role": "user",
                  "content": "Summarize the following in one sentence: <LLMLINGUA>{% raw %}{{document}}{% endraw %}</LLMLINGUA>"
                }
              ]
            }
  - ref: my-file-log
    name: my-file-log
    display_name: my-file-log
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: file-log
    enabled: true
    global: false
    config:
      path: /tmp/compressor.json
ai_gateway_models:
  - ref: my-gpt-4o
    name: my-gpt-4o
    display_name: my-gpt-4o
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
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
    policies:
      - !ref my-ai-prompt-template-policy#name
      - !ref my-ai-prompt-compressor-policy#name
      - !ref my-file-log#name
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}

Clients send only the `{% raw %}{{document}}{% endraw %}` value, so the tags always surround the client input and never the instruction.
Prompts under 20 tokens aren't compressed. Prompts of 20 to 100 tokens are compressed to 80% of their length, and longer prompts to 30%.

{:.info}
> If your {{site.ai_gateway}} data plane doesn't run in Docker, set `compressor_url` to `http://localhost:8080` instead.

## Validate configuration

Send a short prompt, then a long document through the template, and compare the `usage.prompt_tokens` value in each response.

{% navtabs "prompt-compressor-tests" %}
{% navtab "Short prompt" %}

A prompt under 20 tokens isn't compressed, so `usage.prompt_tokens` stays small and unchanged:

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: my-gpt-4o
  messages:
    - role: user
      content: What is DNS?
status_code: 200
{% endvalidation %}
<!--vale on-->

The response reports `"prompt_tokens": 11`.

{% endnavtab %}
{% navtab "Long document" %}

Reference the template and pass the document as a property.
The template wraps the document in `<LLMLINGUA>` tags, so the Policy compresses the document and leaves the instruction as is:

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: my-gpt-4o
  messages: "{template://summarize}"
  properties:
    document: "Kong Gateway is an API gateway that sits in front of upstream services and handles authentication, rate limiting, logging, and traffic control through a plugin architecture. Teams deploy it as a single entry point for their APIs, where it routes requests to the correct service, enforces security policies, and records detailed analytics for every call. Plugins extend the gateway without changes to the upstream services, so teams can add new capabilities such as caching, request transformation, and observability on their own schedule. The control plane distributes configuration to data planes that run close to the services, which keeps latency low and lets each environment scale independently of the others. Operators manage the same gateway across cloud, on-premises, and Kubernetes environments with one consistent configuration model."
status_code: 200
{% endvalidation %}
<!--vale on-->

Without compression, the document is about 150 tokens.
The response reports roughly 60 `prompt_tokens`, and the model still returns an accurate summary.
See [Check compression metrics](#check-compression-metrics) for the exact counts.

{% endnavtab %}
{% endnavtabs %}

## Check compression metrics

The File Log Policy writes each request to `/tmp/compressor.json`, and the AI Prompt Compressor Policy records its results in the `ai.compressor` object of every entry.
For the full list of fields, see the [audit log reference](/ai-gateway/ai-audit-log-reference/#ai-prompt-compressor-logs).

Read the log from inside your {{site.ai_gateway}} Docker container to show the compression metrics of the most recent request:

<!--vale off-->
{% validation custom-command %}
command: |
  docker exec kong-ai-quickstart-gateway cat /tmp/compressor.json \
    | jq -s 'map(.ai.compressor | select(.)) | last'
expected:
  return_code: 0
  message: Compression was performed
render_output: false
{% endvalidation %}
<!--vale on-->

The following output for the long document shows the token counts before and after compression:

```json
{
  "compress_items": [
    {
      "information": "Compression was performed and saved 103 tokens",
      "original_token_count": 147,
      "compress_token_count": 44,
      "msg_id": 1,
      "compressor_model": "microsoft/llmlingua-2-xlm-roberta-large-meetingbank",
      "compress_type": "rate",
      "compress_value": 0.3,
      "save_token_count": 103
    }
  ],
  "duration": 681,
  "compress_token_count": 44,
  "save_token_count": 103,
  "compressed_message_count": 1,
  "compress_type": "rate",
  "provider": "kong",
  "original_token_count": 147
}
```

The top-level `original_token_count`, `compress_token_count`, and `save_token_count` fields total the tokens across all compressed messages.
The prompt shrank from 147 to 44 tokens, a saving of 103 tokens.
After the short prompt, the same command reports `save_token_count: 0` and an `information` message that explains why compression was skipped.
