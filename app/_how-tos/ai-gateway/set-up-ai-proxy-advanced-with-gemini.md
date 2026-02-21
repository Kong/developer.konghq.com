---
title: Set up AI Proxy Advanced with Gemini in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-advanced-with-gemini/

content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using Gemini.

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - gemini

tldr:
  q: How do I use the AI Proxy Advanced plugin with Gemini?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the Gemini provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: Gemini
      content: |

        Before you begin, you must get the Gemini API key from Google Cloud:

        1. Go to the Google Cloud Console.
        1. Select or create a project.
        1. Navigate to APIs & Services.
        1. In the APIs & Services sidebar, click Library.
        1. Search for “Generative Language API”.
        1. Click Gemini API.
        1. Click Enable.
        1. Navigate back to APIs & Services.
        1. In the APIs & Services sidebar, clickCredentials.
        1. From the Create Credentials dropdown menu, select API Key.
        1. Copy the generated API key.
        1. Export the API key as an environment variable:

        ```sh
        export DECK_GEMINI_API_KEY="YOUR-GEMINI-API-KEY"
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

To set up AI Proxy Advanced with Gemini, configure API key authentication and specify the Gemini model to use. 

In this example, we use the `gemini-2.5-flash` model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - model:
              provider: gemini
              name: gemini-2.5-flash
            auth:
              param_name: key
              param_value: ${gemini_api_key}
              param_location: query
            route_type: llm/v1/chat
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

