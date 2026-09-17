---
description: Use regular expressions, variables, and templates to transform requests
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
  - request-transformer
related_resources:
  - text: Request Transformer Advanced Policy
    url: /ai-gateway/policies/request-transformer-advanced/
  - text: AI Request Transformer Policy
    url: /ai-gateway/policies/ai-request-transformer/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
---

{% include md/ai-gateway/v2/policies/request-response-transformer/request-transformer-description.md %}

For more advanced features, see the [Request Transformer Advanced Policy](/ai-gateway/policies/request-transformer-advanced/).

## Order of execution

{% include md/ai-gateway/v2/policies/request-response-transformer/transformation-order.md %}

## Templates

{% include md/ai-gateway/v2/policies/request-response-transformer/templates.md %}

## Example

A common use for this Policy in {{site.ai_gateway}} is removing headers, query string parameters, or body fields that a client sends but that a specific upstream AI Model Provider rejects. For example, a client that sends Anthropic-specific beta fields to a provider whose API doesn't support them:

{% entity_example %}
type: policy
data:
  display_name: Strip unsupported beta fields
  name: strip-unsupported-beta-fields
  type: request-transformer
  enabled: true
  global: false
  config:
    remove:
      headers:
        - anthropic-beta
      querystring:
        - beta
      body:
        - output_config
        - context_management
        - mcp_servers
        - container
        - service_tier
formats:
  - kongctl
{% endentity_example %}

Attach this Policy to an [AI Model](/ai-gateway/entities/ai-model/)'s `policies` array so it applies before {{site.ai_gateway}} forwards the request upstream. Don't remove the `model` field: {{site.ai_gateway}} uses it to select the target, and removing it breaks routing.
