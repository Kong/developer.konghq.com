---
title: Moderate user requests to AI Gateway with Azure AI Content Safety
description: Configure the AI Proxy and AI Azure Content Safety plugins to moderate requests to your LLM
content_type: how_to

products:
    - gateway

works_on:
    - on-prem
    - konnect

plugins:
  - ai-proxy
  - ai-azure-content-safety

entities: 
  - service
  - route
  - plugin

tags:
    - ai-gateway
    - azure-ai

tldr: 
  q: ""
  a: ""
    

tools:
    - deck
  
prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
  - title: OpenAI
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
  - title: Azure
    content: |
      This tutorial uses an Azure Content Safety. You will need an Azure subscription with permissions to create a Content Safety instance.
    icon_url: /assets/icons/azure.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.6'

---
## 1. Enable the AI Proxy plugin

{% entity_examples %}
entities:
  plugins:
  - name: ai-proxy
    config:
      route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: Bearer ${openai_key}
      model:
        provider: openai
        name: gpt-4

variables:
  openai_key:
    value: $OPENAI_API_KEY
    
{% endentity_examples %}

## 2. Set up an Azure AI Content Safety instance

In your Azure portal, go to [**Azure AI services** > **Content safety**](https://portal.azure.com/#view/Microsoft_Azure_ProjectOxford/CognitiveServicesHub/~/ContentSafety) and create a new instance.

## 3. Define environment variables

Open the content safety resource and get the endpoint from the **Overview**, and an AP key from **Resource Management** > **Keys and Endpoints**, and add them to your environment:

```sh
export DECK_CONTENT_SAFETY_ENDPOINT=<endpoint-url>
export DECK_CONTENT_SAFETY_KEY=<key-content>
```

## 4. Enable the AI Azure Content Safety plugin 

{% entity_examples %}
entities:
  plugins:
  - name: ai-azure-content-safety
    config:
      content_safety_key: ${content_safety_key}
      categories:
      - name: Hate
        rejection_level: 2
      - name: Violence
        rejection_level: 2
      
variables:
  content_safety_key:
    value: $CONTENT_SAFETY_KEY
  content_safety_url:
    value: $CONTENT_SAFETY_ENDPOINT
{% endentity_examples %}