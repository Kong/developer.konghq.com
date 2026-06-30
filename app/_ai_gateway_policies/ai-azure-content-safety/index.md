---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI Azure Content Safety Policy allows administrators to enforce 
introspection with the [Azure AI Content Safety](https://azure.microsoft.com/en-us/products/ai-services/ai-content-safety) service 
for all requests and responses handled by the [AI Model](/ai-gateway/entities/ai-model/) entity.
This Policy enables configurable thresholds for the different moderation categories 
and you can specify an array set of pre-configured blocklist IDs from your Azure Content Safety instance.

You can observe and report on audit failures using the {{site.base_gateway}} logging plugins.

## How it works

The AI Azure Content Safety Policy can be applied to:
* Input data (requests)
* Output data (responses)
* Both input and output data

Here's how it works if you apply it to both requests and responses:

1. The AI Azure Content Safety Policy intercepts the request and sends the request body to the Azure AI Content Safety service.
   1. The Azure AI Content Safety service analyzes the request against configured moderation categories and allows or blocks the request.
1. If allowed, the request is forwarded upstream with the AI Model entity.
1. On the way back, the Policy intercepts the response and sends the response body to the Azure AI Content Safety service.
   1. The Azure AI Content Safety service analyzes the response against configured moderation categories and allows or blocks the response.
1. If allowed, the response is forwarded to the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Plugin as AI Azure Content Safety Policy
    participant Safety as Azure AI Content Safety service
    participant Proxy as AI Proxy/Advanced
    participant AI as Upstream AI Service
    
    Client->>Plugin: Send request
    Plugin->>Safety: Intercept & send request body
    Safety->>Safety: Check against moderation <br>categories and blocklists
    Safety->>Plugin: Allow or block request
    Plugin->>Proxy: Forward allowed request
    Proxy->>AI: Process allowed request
    AI->>Proxy: Return AI response
    Proxy->>Plugin: Forward response
    Plugin->>Safety: Intercept & send response body
    Safety->>Safety: Check against moderation <br>categories and blocklists
    Safety->>Plugin: Allow or block response
    Plugin->>Client: Forward allowed response
{% endmermaid %}
<!--vale on-->

> _Figure 1: Diagram showing the request and response flow with the AI Azure Content Safety Policy._

## TLS verification

[`config.ssl_verify`](/ai-gateway/policies/ai-azure-content-safety/reference/#schema--config-ssl-verify) is enabled by default. The AI Azure Content Safety Policy verifies the TLS certificate when connecting to the Azure Content Safety service. To disable this, set `ssl_verify: false`.

## Logging

The AI Azure Content Safety Policy emits structured log data for every inspected request and response. For the full list of log fields, see the [{{site.ai_gateway}} audit log reference](/ai-gateway/ai-audit-log-reference/#ai-azure-content-safety-logs).

To log the raw content of blocked requests and responses, enable [`config.log_blocked_content`](/ai-gateway/policies/ai-azure-content-safety/reference/#schema--config-log-blocked-content). When enabled, the blocked prompt or response body appears under `ai.proxy.azure-content-safety.input_faulty_prompt` and `ai.proxy.azure-content-safety.output_faulty_response` in the log entry.

## Format

This Policy works with all of the AI Proxy plugin's `route_type` settings (excluding the `preserve` mode), and is able to
compose an Azure Content Safety text check by compiling all chat history, or just the `'user'` content.
