---
title: Model
content_type: reference
entities:
  - model

products:
  - ai-gateway

description: AI Models registered with the {{site.ai_gateway}}.

schema:
    api: konnect/ai-gateway
    path: /schemas/AIGatewayModel

works_on:
    - konnect

tools:
    - konnect-api
    - deck
---


## Set up a Model

{% entity_example %}
type: model
data:
  model: openai-something
{% endentity_example %}

## Schema

{% entity_schema %}