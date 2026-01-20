---
title: Set up AI Proxy with Gemini in {{site.base_gateway}}

content_type: how_to

related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using Gemini.

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
  - gemini

tldr:
  q: How do I use the AI Proxy plugin with Gemini?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the Gemini provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: Gemini
      content: |
        Before you begin, you must get the following credentials from Google Cloud:

        - **Service Account Key**: A JSON key file for a service account with Vertex AI permissions
        - **Project ID**: Your Google Cloud project identifier
        - **Location ID**: The region where your Vertex AI endpoint is deployed (for example, `us-central1`)
        - **API Endpoint**: The Vertex AI API endpoint URL (typically `https://{location}-aiplatform.googleapis.com`)

        Export these values as environment variables:
        ```sh
        export DECK_GEMINI_API_KEY="<your_gemini_api_key>"
        export GCP_PROJECT_ID="<your-gemini-project-id>"
        export GEMINI_LOCATION_ID="<your-gemini-location_id>"
        export GEMINI_API_ENDPOINT="<your_gemini_api_endpoint>"
        ```
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

To set up AI Proxy with Gemini, configure API key authentication and specify the Gemini model to use. 

In this example, we use the gemini-2.0-flash-exp model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          param_name: key
          param_value: ${gemini_api_key}
          param_location: query
        model:
          provider: gemini
          name: gemini-1.5-flash
variables:
  gemini_api_key:
    value: $GEMINI_API_KEY
    description: The API key to use to connect to Gemini.
{% endentity_examples %}
<!--vale on-->

## Validate
To validate, send a request to the Route:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  messages:
    - role: "system"
      content: "You are a mathematician."
    - role: "user"
      content: "What is 1+1?"
{% endvalidation %}
