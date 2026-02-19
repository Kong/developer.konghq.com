---
title: 'AI Azure Content Safety'
name: 'AI Azure Content Safety'

tier: ai_gateway_enterprise
content_type: plugin

publisher: kong-inc
description: 'Use Azure AI Content Safety to check and audit AI Proxy plugin messages before proxying them to an upstream LLM'

products:
    - ai-gateway
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.7'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-azure-content-safety.png

categories:
  - ai

tags:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
  - moderation
  - azure cognitive services
---

The AI Azure Content Safety plugin allows administrators to enforce 
introspection with the [Azure AI Content Safety](https://azure.microsoft.com/en-us/products/ai-services/ai-content-safety) service 
for all requests and responses handled by the [AI Proxy](/plugins/ai-proxy/) plugin.
The plugin enables configurable thresholds for the different moderation categories 
and you can specify an array set of pre-configured blocklist IDs from your Azure Content Safety instance.

Audit failures can be observed and reported on using the {{Site.base_gateway}} logging plugins.

{% include plugins/ai-plugins-note.md %}

## How it works

The AI Azure Content Safety plugin can be applied to:
* Input data (requests)
* Output data (responses) {% new_in 3.12 %}
* Both input and output data {% new_in 3.12 %}

Here's how it works if you apply it to both requests and responses:

1. The plugin intercepts the request and sends the request body to the Azure AI Content Safety service.
   1. The Azure AI Content Safety service analyzes the request against configured moderation categories and allows or blocks the request.
1. If allowed, the request is forwarded upstream with the AI Proxy or AI Proxy Advanced plugin.
1. On the way back, the plugin intercepts the response and sends the response body to the Azure AI Content Safety service. {% new_in 3.12 %}
   1. The Azure AI Content Safety service analyzes the response against configured moderation categories and allows or blocks the response.
1. If allowed, the response is forwarded to the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Plugin as AI Azure Content Safety plugin
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

> _Figure 1: Diagram showing the request and response flow with the AI Azure Content Safety plugin._

## Format

This plugin works with all of the AI Proxy plugin's `route_type` settings (excluding the `preserve` mode), and is able to
compose an Azure Content Safety text check by compiling all chat history, or just the `'user'` content.
