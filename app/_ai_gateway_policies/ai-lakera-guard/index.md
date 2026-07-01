---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI Lakera Guard Policy evaluates requests and responses that pass through {{site.ai_gateway}} to Large Language Models (LLMs). It uses the Lakera Guard SaaS service to detect safety policy violations and block unsafe content before it reaches upstream LLMs or returns to clients. The AI Lakera Guard Policy supports multiple inspection modes and guards both inbound prompts and outbound model outputs.

## How it works

The AI Lakera Guard Policy inspects model traffic at three points in the LLM request lifecycle. Each phase pages data into memory, extracts content that Lakera Guard can evaluate, and sends that content to Lakera for inspection.

* **Request phase**: Inspection occurs **before** any data leaves the gateway toward the target LLM. The AI Lakera Guard Policy buffers the full request body in memory, extracts the fields that the AI Lakera Guard Policy can evaluate, and sends them for inspection.
* **Response phase (buffered)**: Inspection occurs **before** any byte is transmitted back toward the client. The AI Lakera Guard Policy buffers the full upstream response in memory, extracts the response fields that Lakera Guard can evaluate, and inspects them. This occurs before {{site.ai_gateway}} sends any part of the response back to the client.
* **Response phase (per-frame)**: The AI Lakera Guard Policy runs during streaming responses like Server-Sent Events. {{site.ai_gateway}} processes the response in chunks, buffering each frame in memory as it arrives. When enough data is available to extract an evaluable segment, the AI Lakera Guard Policy inspects that segment with Lakera Guard before forwarding the frame to the client.

The AI Lakera Guard Policy inspects request and response bodies for routes that use supported model interaction formats. It skips inspection on response types that are not text responses based on Lakera Guard's current product limitations.

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

You can use the [logging capabilities](/ai-gateway/ai-audit-log-reference/) of the AI Lakera Guard Policy to monitor the inspection process and understand the detected violations. For the full list of log fields, see the [{{site.ai_gateway}} audit log reference](/ai-gateway/ai-audit-log-reference/#ai-lakera-guard-logs).

The AI Lakera Guard Policy provides detailed logging and controls over how violations are reported:
* **SaaS platform logging**: All inspected requests, responses, and chats are made available on the Lakera SaaS platform.
* **{{site.ai_gateway}} logging**: {{site.ai_gateway}} logs all request and response **Lakera request UUIDs** to the standard logging subsystem.
* **Unsupported logging outputs**: [Prometheus](/ai-gateway/policies/prometheus/), or [OpenTelemetry](/ai-gateway/policies/opentelemetry/).
* **Logging outputs**: [HTTP Log](/ai-gateway/policies/http-log/), [File Log](/ai-gateway/policies/file-log/), and [TCP Log](/ai-gateway/policies/tcp-log/).

By default, the AI Lakera Guard Policy doesn't tell clients why their request was blocked. However, this information is always logged to {{site.ai_gateway}} logs for administrators.

To change this behavior, use `reveal_failure_categories: true`. If activated, you'll receive a JSON response including a breakdown array that details the specific `detector_type` that caused the failure.

To log the raw content of blocked requests and responses, enable [`config.log_blocked_content`](/ai-gateway/policies/ai-lakera-guard/reference/#schema--config-log-blocked-content). When enabled, the blocked prompt or response body appears under `ai.proxy.lakera-guard.input_faulty_prompt` and `ai.proxy.lakera-guard.output_faulty_response` in the log entry.

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

When a request is blocked, the log captures the violation reason, detector details, and the blocking AI Policy name, AI Consumer ID, and a running trigger counter:

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
      "input_block_source": "ai-lakera-guard",
      "input_block_consumer_id": "consumer-uuid-1234",
      "guards_triggered_count": 1,
      "lakera_project_id": "project-1234567890"
    }
  }
}
```
