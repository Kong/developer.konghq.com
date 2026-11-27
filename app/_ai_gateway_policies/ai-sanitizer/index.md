---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
categories:
  - ai
tags:
  - ai
  - dlp
  - security
related_resources:
  - text: How to protect sensitive data in requests
    url: /ai-gateway/protect-sensitive-information-with-ai/
  - text: How to protect sensitive data in responses
    url: /ai-gateway/protect-sensitive-information-output-with-ai/
  - text: AI Custom Guardrail Policy
    url: /ai-gateway/policies/ai-custom-guardrail/
  - text: "{{site.ai_gateway}} audit log reference"
    url: /ai-gateway/ai-audit-log-reference/#ai-pii-sanitizer-logs
---

The AI PII Sanitizer Policy for {{site.ai_gateway}} helps protect sensitive information in client request bodies before they reach upstream AI providers or tools.

By integrating with an external PII service, this Policy ensures compliance with data privacy regulations while preserving the usability of request data.

The AI PII Sanitizer supports multiple sanitization modes, including replacing sensitive information with fixed placeholders or generating synthetic replacements that retain category-specific characteristics.

Additionally, AI PII Sanitizer offers an optional restoration feature, allowing the original request data to be reinstated in responses when needed.

The AI PII Sanitizer Policy uses the AI PII Anonymizer Service, which can run in a Docker container, to detect and sanitize sensitive data.

## How it works

The AI PII Sanitizer Policy can be applied to:
* Input data (requests)
* Output data (responses)
* Both input and output data

Here's how it works if you apply it to both requests and responses:

1. The Policy intercepts the request body and sends it to the external PII service.
   - The PII service detects sensitive data and applies the chosen sanitization method (placeholders or synthetic replacements).
1. The sanitized request is forwarded upstream to the selected AI Model.
1. On the way back, the Policy intercepts the response body and sends it to the external PII service.
   - The PII service detects sensitive data and applies the chosen sanitization method (placeholders or synthetic replacements).
1. (_Only applies to input data sanitization_) If restoration is enabled, the Policy restores the original request data in responses before returning them to the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Policy as AI PII Sanitizer
    participant PII as PII Service
    participant AI as Upstream AI Service

    Client->>Policy: Send request
    Policy->>PII: Intercept & send request body
    PII->>PII: Detect sensitive data in request
    PII->>Policy: Return sanitized request<br/>(placeholders/synthetic data)
    Policy->>{{site.ai_gateway}}: Forward sanitized request
    {{site.ai_gateway}}->>AI: Process sanitized request
    AI->>{{site.ai_gateway}}: Return AI response
    {{site.ai_gateway}}->>Policy: Forward response
    Policy->>PII: Intercept & send response body
    PII->>PII: Detect sensitive data in response
    PII->>Policy: Return sanitized response<br/>(placeholders/synthetic data)
    Policy->>Client: Return sanitized response
{% endmermaid %}
<!--vale on-->

> _Figure 1: Diagram showing the request and response flow with the AI PII Sanitizer Policy._

### Restore original values in responses

When [`recover_redacted`](./reference/#schema--config-recover-redacted) is `true`, which is the default, the Policy restores the original values in the response by replacing every placeholder.
The Policy doesn't track which text is a placeholder, so it also replaces text such as `PLACEHOLDER1` or `CUSTOM1` that was part of your own content.
That part of the response then contains the wrong text.
Keep text that looks like a placeholder out of the content that you sanitize.
If you can't control the content, set `recover_redacted` to `false`.

## Message selection

{% include_cached md/ai-gateway/v2/guardrail-message-selection.md policy="ai-sanitizer" subject="request" action="sends to the PII service" %}

This Policy replaces `allow_all_conversation_history`.

The Policy sends each selected message to the PII service as a separate text, because the Policy writes the sanitized text back into that message.
On requests in the OpenAI chat completions format or the Anthropic Messages format, the Policy sends nothing for `tool_call`.
It sends each `tool_result` without the tool name.
On requests in the OpenAI Responses format, the Policy sends tool calls as `name(arguments)` and tool results as `name: output`.


## Text chunking

{% include_cached md/ai-gateway/v2/guardrail-chunking.md service="PII service" subject="a request" window=10000 messages=true single_call=true %}

A sanitized part can't repeat, so `chunk_overlap` must be `0`.
The Policy sanitizes every request, so this always applies.

## AI PII Anonymizer service

{% include /md/ai-gateway/v2/policies/pii-service.md policy_name="AI PII Sanitizer" show_endpoints=true %}

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}