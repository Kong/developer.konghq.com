---
title: 'AI GCP Model Armor'
name: 'AI GCP Model Armor'

content_type: plugin

publisher: kong-inc
description: 'Audit and validate LLM prompts with Google Cloud Model Armor before forwarding them to an upstream LLM.'


products:
    - gateway

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


icon: plugin-slug.png

tags:
   - ai
---

# GCP Model Armor Plugin

The **GCP Model Armor** plugin integrates Kong AI Gateway with Google Cloud's Model Armor service to enforce content safety guardrails on AI requests and responses. It leverages GCP SaaS APIs to inspect text inputs and outputs, helping prevent unsafe content from being processed or returned to users.

## Features

The plugin provides GCP Model Armor features to enforce content safety and improve guardrail reliability:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Description
    key: description
rows:
  - feature: Request & Response Guardrails
    description: Checks chat requests, embeddings requests, and chat responses to prevent unsafe content. Controlled by `guarding_mode` (INPUT for request-only, BOTH for request + response). Requires valid `project_id` and `location_id`.
  - feature: Single Template
    description: Enforces a single GCP Model Armor template for all inspections to maintain consistent filtering. Set with `template_id`.
  - feature: Reveal Blocked Categories
    description: When enabled, the user sees why content was blocked (e.g., "hate speech"). Controlled by `reveal_blocked_categories`.
  - feature: Multi-Language Detection
    description: Allows inspection of content in multiple languages. Requires `enable_multi_language_detection` set to true and `source_language` defined.
  - feature: Streaming Response Inspection
    description: Asynchronously checks chunks of streaming responses, terminating if unsafe content is detected. Configurable via `response_buffer_size`.
{% endtable %}

## How it works

The plugin inspects requests and responses using GCP Model Armor:

* **Request inspection**: All chat and embeddings requests are checked via the [GCP Sanitize Text Prompts API](https://cloud.google.com/security-command-center/docs/sanitize-prompts-responses#text-prompts).
* **Response inspection:** Only chat responses are validated via the [GCP Sanitize Model API](https://cloud.google.com/security-command-center/docs/sanitize-prompts-responses#sanitize-model).

All inspections use a single GCP Model Armor template, which defines the filtering rules. By default, the plugin inspects only the final chat message to maximize accuracy. You can combine multiple messages for inspection, but this reduces reliability.

If the `reveal_blocked_categories` option is enabled, users receive detailed feedback on why content was blocked (for example, “hate speech” or “jailbreak attempt”).

## Best practices

The following table maps each best practice to its corresponding config field (or notes if no direct field exists):

{% table %}
columns:
  - title: Config Field / Setting
    key: field
  - title: Description
    key: description
rows:
  - field: Default Last Message Inspection
    description: Uses the default plugin behavior of inspecting only the last chat message for maximum accuracy.
  - field: guarding_mode
    description: Set to INPUT for request-only inspection, OUTPUT for response-only, or BOTH for both request and response checks.
  - field: reveal_blocked_categories
    description: Enable to show users why content was blocked (e.g., "hate speech", "jailbreak attempt").
  - field: response_buffer_size
    description: Adjust to control how much of the upstream response is buffered before inspection; smaller sizes minimize latency.
  - field: enable_multi_language_detection + source_language
    description: Enable to inspect multiple languages; must set the source_language ISO code when using this mode.
{% endtable %}

## Limitations

The plugin has several important limitations to keep in mind when enforcing content safety:

* Inspects only a single chat message or response at a time; combining multiple messages reduces accuracy.
* Only chat responses are validated; embeddings responses are not checked.
* Asynchronous chunk checking during SSE streaming may briefly emit unsafe content before termination.
* Only a single template can be configured per plugin instance.
* For SSE streaming, response chunks are checked asynchronously; unsafe content may appear briefly before the connection is terminated with `"stop_reason: blocked by content safety"`.