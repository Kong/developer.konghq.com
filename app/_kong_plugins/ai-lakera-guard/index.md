---
title: 'AI Lakera Guard'
name: 'AI Lakera Guard'

content_type: plugin

publisher: kong-inc
description: 'Audit and enforce safety policies on LLM requests and responses using the AI AWS Lakera plugin before they reach upstream LLMs.'

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

---
The AI Lakera Guard plugin integrates with Kong to inspect and guard traffic that is flowing to and from Large Language Models (LLMs) across different phases of the client's LLM call.

## Overview

Depending on the phase of the client's LLM call, the plugin performs three distinct operations depending on the phase of the client’s LLM call:
* **Request Phase**: Also known as the **Access** phase in Kong. Inspection occurs **before** any data leaves the gateway toward the target LLM. The plugin buffers the full request body in memory, extracts the fields that Lakera Guard can evaluate, and sends them for inspection.
* **Response Phase (buffered)**: Also known as the **Response** phase in Kong. Inspection occurs **before** any byte is transmitted back toward the client. The plugin buffers the full upstream response in memory, extracts the response fields that Lakera Guard can evaluate, and inspects them. This occurs before Kong sends any part of the response back to the client.”
* **Response Phase (per-frame)**: Also called the **body_filter** phase in Kong. The plugin runs during streaming responses like Server-Sent Events. Kong processes the response in chunks, buffering each frame in memory as it arrives. When enough data is available to extract an evaluable segment, the plugin inspects that segment with Lakera Guard before forwarding the frame to the client.

The plugin operates on both the request and response phases. However, it skips Lakera Guard checks on responses that are not "text responses" based on the current limitations of the Lakera Guard product itself.

Content that the plugin inspects:

{% feature_table %} 
item_title: Supported Content Inspection
columns:
  - title: Inspection Type
    key: type
  - title: Input (Request)
    key: input
  - title: Output (Response)
    key: output
  - title: Content type
    key: content
  - title: Limitations
    key: limitation     

features:
  - type: "Chat Completions"
    input: true
    output: true
    content: Array of string content.
    limitation: If multi-modal, it only inspects the text segments.
  - type: "/responses"
    input: true
    output: true
    content: Input string, array of input strings, or array of input chat messages. 
    limitation: If multi-modal, it only inspects the text segments.
  - type: "/images/generations"
    input: true
    output: false
    content: Prompt string, input string, or array of input strings.
    limitation: N/A
  - type: "/embeddings"
    input: true
    output: false
    content: Input string or array of input strings.
    limitation: N/A
{% endfeature_table %}

## Logging
Use the logging capabilities of the `ai-lakera-guard` plugin to monitor the inspection process and understand the detected violations. The plugin provides detailed logging and controls over how violations are reported:
* **SaaS Platform Logging**: All inspected requests, responses, and chats are made available on the Lakera SaaS platform.
* **Standard Kong Logging**: Kong logs all request and response "Lakera request UUIDs" to the standard logging subsystem.
* **Unsupported Logging Outputs**: Prometheus, Splunk, or OpenTelemetry.
* **Logging Outputs**:  HTTP-Log, File-Log, and TCP-Log.

 By default, the plugin doesn't tell clients why their request was blocked. However, this information is always logged to Kong logs for administrators. To change this behavior, use `reveal_failure_categories: true`. If activated, you'll receive a JSON response including a breakdown array that details the specific `detector_type` that caused the failure.

 Standard logging subsystem example:
 ```
 "ai": {
  "proxy": {
    "lakera-guard": {
      "input_processing_latency": 72,
      "lakera_service_url": "https://api.lakera.ai/v2/guard",
      "input_request_uuid": "c420d835-551c-47e3-9f39-82f87d56f3c0",
      "lakera_project_id": "default"
    }
  }
}
```

Violations log example:
```
"ai": {
  "proxy": {
    "lakera-guard": {
      "input_processing_latency": 78,
      "lakera_service_url": "https://api.lakera.ai/v2/guard",
      "input_block_detail": [
        {
          "policy_id": "policy-lakera-default",
          "detector_id": "detector-lakera-default-moderated-content",
          "project_id": "project-lakera-default",
          "message_id": 3,
          "detected": true,
          "detector_type": "moderated_content/hate"
        }
      ],
      "input_request_uuid": "77cf5fda-4bde-4b76-a830-eba67ecafd00",
      "input_block_reason": "moderated_content/hate",
      "lakera_project_id": "default"
    }
  }
```