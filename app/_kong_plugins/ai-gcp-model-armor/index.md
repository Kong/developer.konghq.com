---
title: 'AI GCP Model Armor'
name: 'AI GCP Model Armor'

tier: ai_gateway_enterprise
content_type: plugin

publisher: kong-inc
description: 'Audit and validate LLM prompts with Google Cloud Model Armor before forwarding them to an upstream LLM.'

categories:
  - ai
products:
  - gateway
  - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-gcp-model-armor.png

tags:
   - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

faqs:
  - q: What do I do if I see the error `Blocked by Model Armor Floor Setting`?
    a: |
      If you see the following error:

      ```json
      {
        "reason": "MODEL_ARMOR",
        "message": "Blocked by Model Armor Floor Setting: The prompt violated X, Y, and Z filters.",
        "error": true
      }
      ```
      This means the plugin is conflicting with settings configured in GCP Vertex.
      We recommend disabling the GCP Model Armor Floor in GCP, as this setting fails in some modes (for example, streaming response mode), and blocks all analytics.

next_steps:
  - text: Use the AI GCP Model Armor plugin
    url: /how-to/use-ai-gcp-model-armor-plugin/
---

The **GCP Model Armor** plugin integrates {{site.ai_gateway}} with [Google Cloud’s Model Armor](https://cloud.google.com/security-command-center/docs/model-armor-overview) service to enforce content safety guardrails on AI requests and responses.
It leverages GCP SaaS APIs to inspect prompts and model outputs, preventing unsafe content from being processed or returned to users.

## Features

The plugin provides the following content safety capabilities:

<!-- vale off -->
{% table %}
columns:
  - title: Feature
    key: feature
  - title: Description
    key: description
rows:
  - feature: Request and response guardrails
    description: Checks chat requests and chat responses to prevent unsafe content. Controlled by `guarding_mode` (`INPUT`, `OUTPUT`, or `BOTH`).
  - feature: Single template enforcement
    description: Applies one GCP Model Armor template for all inspections, ensuring consistent filtering. Set with `template_id`.
  - feature: Reveal blocked categories
    description: Optionally show the categories that triggered blocking (for example, `"hate speech"`). Controlled by `reveal_failure_categories`.
  - feature: Streaming response inspection
    description: Buffers streaming responses and terminates if unsafe content is detected. Configurable via `response_buffer_size`.
  - feature: Custom failure messages
    description: Configure user-facing messages with `request_failure_message` and `response_failure_message` when content is blocked.
{% endtable %}
<!-- vale on -->

## How it works

The plugin inspects requests and responses using GCP Model Armor:

* **Request inspection**: Chat prompts are intercepted, and the relevant content (by default, the last chat message) is sent to the [sanitizeUserPrompt](https://cloud.google.com/security-command-center/docs/sanitize-prompts-responses#text-prompts) API.
* **Response inspection:** Chat responses are buffered (supporting gzip and streaming) and sent to the [sanitizeModelResponse](https://cloud.google.com/security-command-center/docs/sanitize-prompts-responses#sanitize-model) API. SSE streaming is supported with chunk buffering.

### Request guarding flow

1. An incoming request to an LLM (for example, a chat completion) is intercepted by the plugin.
2. The plugin extracts the relevant content, usually the last user message in the conversation.
3. The content is submitted to GCP Model Armor’s `sanitizeUserPrompt` endpoint for analysis.

### Response guarding flow

1. The plugin buffers the upstream response body (including gzipped responses).
2. It extracts the model’s response content.
3. The content is sent to GCP Model Armor’s `sanitizeModelResponse` endpoint for validation.

### Sanitization and action

1. GCP Model Armor evaluates the provided content against the configured `template_id`.
2. The plugin interprets the `sanitizationResult` from GCP.
3. If a violation is detected (for example, hatred, sexually explicit content, harassment, or jailbreak attempts), the request or response is blocked.
4. Blocked traffic results in a `400 Bad Request` response with the configured `request_failure_message` or `response_failure_message`.
5. If `reveal_failure_categories` is enabled, the response also lists the categories that triggered blocking.

{:.info}
> When configuring `template_id` in the AI GCP Model Armor plugin, ensure that it aligns with the content safety policies and categories defined in your GCP Model Armor service.
>
> Review whether your organization requires custom categories or additional policy definitions, and integrate them into the selected template to match compliance and safety requirements.

## Best practices

The following configuration guidance helps ensure effective content safety enforcement:

{% table %}
columns:
  - title: Setting
    key: field
  - title: Description
    key: description
rows:
  - field: |
      `guarding_mode`
    description: Set to `INPUT` for request-only inspection, `OUTPUT` for response-only, or `BOTH` to guard both directions.
  - field: |
      `request_failure_message` / `response_failure_message`
    description: Provide user-friendly error messages when prompts or responses are blocked.
  - field: |
      `reveal_failure_categories`
    description: Enable to return details on why content was blocked.
  - field: |
      `response_buffer_size`
    description: Tune how much of the upstream response is buffered before inspection; smaller values reduce latency.
  - field: Default last message inspection with `text_source`
    description: Keep the default behavior of checking only the last user prompt message for highest accuracy.
{% endtable %}

{:.warning}
> **Caution**: Do **not** set the Model Armor Floor Setting directly in GCP, as it will cause conflicts with this plugin.
See the [FAQ entry for this error](#what-do-i-do-if-i-see-the-error-blocked-by-model-armor-floor-setting) for more information.

## Limitations

* Only chat prompts and chat responses are inspected; embeddings and other modalities are not checked.
* Inspects one chat message or one response body at a time. Combining multiple messages reduces accuracy.
* For SSE streaming, unsafe content may appear briefly before termination with `"stop_reason: blocked by content safety"`.
* Only one `template_id` can be configured per plugin instance.