---
title: 'AI Lakera Guard'
name: 'AI Lakera Guard'

tier: ai_gateway_enterprise

content_type: plugin

publisher: kong-inc
description: 'Inspect and enforce Lakera Guard safety policies on LLM requests and responses before they reach upstream models.'

category: AI

products:
  - gateway
  - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.13'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - ai

search_aliases:
  - ai-lakera-guard

icon: ai-lakera.png

categories:
  - ai

related_resources:
  - text: Use the AI Lakera Guard plugin
    url: /ai-gateway/ai-audit-log-reference/
  - text: Use the AI GCP Model Armor plugin
    url: /how-to/use-ai-gcp-model-armor-plugin/
  - text: Use AI PII Sanitizer to protect sensitive data in requests
    url: /how-to/protect-sensitive-information-with-ai/
  - text: Use Azure Content Safety plugin
    url: /how-to/use-azure-ai-content-safety/
  - text: Use the AI AWS Guardrails plugin
    url: /how-to/use-ai-aws-guardrails-plugin/

next_steps:
  - text: Use the AI Lakera Guard plugin
    url: /ai-gateway/ai-audit-log-reference/

---
The AI Lakera Guard plugin evaluates requests and responses that pass through Kong to Large Language Models (LLMs). It uses the Lakera Guard SaaS service to detect safety policy violations and block unsafe content before it reaches upstream LLMs or returns to clients. The plugin supports multiple inspection modes and guards both inbound prompts and outbound model outputs.

## How it works

The plugin inspects model traffic at three points in the LLM request lifecycle. Each phase pages data into memory, extracts content that Lakera Guard can evaluate, and sends that content to Lakera for inspection.

* **Request phase**: Inspection occurs **before** any data leaves the gateway toward the target LLM. The plugin buffers the full request body in memory, extracts the fields that the AI Lakera Guard plugin can evaluate, and sends them for inspection.
* **Response phase (buffered)**: Inspection occurs **before** any byte is transmitted back toward the client. The plugin buffers the full upstream response in memory, extracts the response fields that Lakera Guard can evaluate, and inspects them. This occurs before {{site.ai_gateway}} sends any part of the response back to the client.
* **Response phase (per-frame)**: The plugin runs during streaming responses like Server-Sent Events. Kong processes the response in chunks, buffering each frame in memory as it arrives. When enough data is available to extract an evaluable segment, the plugin inspects that segment with Lakera Guard before forwarding the frame to the client.

The plugin inspects request and response bodies for routes that use supported model interaction formats. It skips inspection on response types that are not text responses based on Lakera Guard’s current product limitations.

## Inspected content

{% table %}
columns:
  - title: Inspection Type
    key: type
  - title: Input (request)
    key: input
  - title: Output (response)
    key: output
  - title: Content type
    key: content
  - title: Limitations
    key: limitation
rows:
  - type: "/chat/completions"
    input: true
    output: true
    content: "Array of string content."
    limitation: "If multi-modal, inspects text segments only."
  - type: "/responses"
    input: true
    output: true
    content: "Input string, array of input strings, or array of chat messages."
    limitation: "If multi-modal, inspects text segments only."
  - type: "/images/generations"
    input: true
    output: false
    content: "Prompt string, input string, or array of input strings."
    limitation: "Image outputs cannot be inspected."
  - type: "/embeddings"
    input: true
    output: false
    content: "Input string or array of input strings."
    limitation: "Embedding outputs cannot be inspected."
{% endtable %}

## Logging

You can use the [logging capabilities](/ai-gateway/ai-audit-log-reference/) of the AI Lakera Guard plugin to monitor the inspection process and understand the detected violations.

The plugin provides detailed logging and controls over how violations are reported:
* **SaaS platform logging**: All inspected requests, responses, and chats are made available on the Lakera SaaS platform.
* **{{site.ai_gateway}} logging**: Kong logs all request and response **Lakera request UUIDs** to the standard logging subsystem.
* **Unsupported logging outputs**: [Prometheus](/plugins/prometheus/), [Splunk](/plugins/kong-splunk-log/), or [OpenTelemetry](/plugins/opentelemetry/).
* **Logging outputs**:  [HTTP-Log](/plugins/http-log/), [File-Log](/plugins/file-log/), and [TCP-Log](/plugins/tcp-log/).

By default, the plugin doesn't tell clients why their request was blocked. However, this information is always logged to {{site.ai_gateway}} logs for administrators.

To change this behavior, use `reveal_failure_categories: true`. If activated, you'll receive a JSON response including a breakdown array that details the specific `detector_type` that caused the failure.

### Standard logging subsystem example

When a request passes all guardrails, the log includes processing latency and the request UUID:

```json
"ai": {
  "proxy": {
    "lakera-guard": {
      "input_processing_latency": 72,
      "lakera_service_url": "https://api.lakera.ai/v2/guard",
      "input_request_uuid": "a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
      "lakera_project_id": "project-1234567890"
    }
  }
}
```

### Violations log example

When a request is blocked, the log captures the violation reason and detector details:

```json
"ai": {
  "proxy": {
    "lakera-guard": {
      "input_processing_latency": 78,
      "lakera_service_url": "https://api.lakera.ai/v2/guard",
      "input_block_detail": [
        {
          "policy_id": "policy-4f8a9b2c-1d3e-4a5b-8c9d-0e1f2a3b4c5d",
          "detector_id": "detector-lakera-moderation-1-input",
          "project_id": "project-1234567890",
          "message_id": 3,
          "detected": true,
          "detector_type": "moderated_content/hate"
        }
      ],
      "input_request_uuid": "a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
      "input_block_reason": "moderated_content/hate",
      "lakera_project_id": "project-1234567890"
    }
  }
}
```