---
title: Set up AI Proxy with Vertex AI in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-with-vertex-ai/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using Vertex AI.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - vertex-ai

tldr:
  q: How do I use the AI Proxy plugin with Vertex AI?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the Vertex AI provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: Vertex AI
      include_content: prereqs/vertex-ai
      icon_url: /assets/icons/gcp.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the plugin

To set up AI Proxy with Vertex AI, specify the model and set the appropriate authentication header.

In this example, we'll use the Gemini 2.0 Flash Exp model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        model:
          provider: gemini
          name: gemini-2.0-flash-exp
          options:
            gemini:
              api_endpoint: ${gcp_api_endpoint}
              project_id: ${gcp_project_id}
              location_id: ${gcp_location_id}
        auth:
          gcp_use_service_account: true
          gcp_service_account_json: ${gcp_service_account_json}
variables:
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_location_id:
    value: $GCP_LOCATION_ID
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
    literal_block: true
  gcp_api_endpoint:
    value: $GCP_API_ENDPOINT  
formats:
  - deck
{% endentity_examples %}
<!--vale on-->


## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
