---
description: Use powerful regular expressions, variables, and templates to transform API requests
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
tags:
  - transformations
categories:
  - transformations
search_aliases:
  - request-transformer-advanced
faqs:
  - q: Can I use the Request Transformer Advanced Policy to rename or replace XML in the request body?
    a: No, you can only rename or replace JSON in the request body.
related_resources:
  - text: Request Transformer Policy
    url: /ai-gateway/policies/request-transformer/
  - text: AI Request Transformer Policy
    url: /ai-gateway/policies/ai-request-transformer/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
---

{% include md/ai-gateway/v2/policies/request-response-transformer/request-transformer-description.md %}

The Request Transformer Advanced Policy provides features that aren't available in the [Request Transformer Policy](/ai-gateway/policies/request-transformer/), including the ability to limit the list of allowed parameters in the request body with the [config.allow.body](./reference/#schema--config-allow-body) parameter.

## Order of execution

{% include md/ai-gateway/v2/policies/request-response-transformer/transformation-order.md %}

## Templates

{% include md/ai-gateway/v2/policies/request-response-transformer/templates.md %}

## Arrays and nested objects

{% include md/ai-gateway/v2/policies/request-response-transformer/arrays-nested-objects.md %}

## Body transformations

Body transformations are only performed for requests where the `Content-Type` header is set to `application/json`.

## Example

Allowlist which JSON body fields a client can send, then move a query parameter into the body before {{site.ai_gateway}} forwards the request upstream:

{% entity_example %}
type: policy
data:
  display_name: Transform multiple request elements
  name: transform-multiple-request-elements
  type: request-transformer-advanced
  enabled: true
  global: false
  config:
    allow:
      body:
        - customer_id
        - customer_name
        - customer_zipcode
    remove:
      querystring:
        - customer_id
    add:
      body:
        - 'customer_id:$(query_params["customer_id"])'
formats:
  - kongctl
{% endentity_example %}

Attach this Policy to an [AI Model](/ai-gateway/entities/ai-model/)'s `policies` array so it applies before {{site.ai_gateway}} forwards the request upstream. Don't remove the `model` field: {{site.ai_gateway}} uses it to select the target, and removing it breaks routing.
