---
description: Limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days, months, or years.
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
faqs:
  - q: Can I set different rate limits for different AI Models?
    a: |
      Yes. An AI Policy's scope is determined by where it's referenced, so create one Rate Limiting
      Policy per [AI Model](/ai-gateway/entities/ai-model/), AI Agent, or AI MCP Server and reference it
      from that entity's `policies` array. Each AI Policy is independent, so the same type can be
      attached in several places with different configurations.
  - q: "How does the `policy` option affect rate limiting?"
    a: |
      The `policy` option determines how rate limits are stored and enforced. The `local` policy uses
      in-memory storage on each data plane node, while the `redis` policy uses Redis, which is useful
      when rate limiting needs to be consistent across multiple {{site.ai_gateway}} data plane nodes.
related_resources:
  - text: AI Rate Limiting Advanced Policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
---

Rate limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days, months, or years.
If the AI Model, AI Agent, or AI MCP Server handling the request has no authentication layer, the [client IP address](#limit-by-ip-address) is used to identify clients.
Otherwise, the AI Consumer is used once an [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/) has authenticated the request.

This Policy counts requests. To rate limit on LLM token usage or cost instead, use the [AI Rate Limiting Advanced Policy](/ai-gateway/policies/ai-rate-limiting-advanced/), which reads the token data returned by the AI Model Provider.

## Scopes

Reference the Rate Limiting Policy from the `policies` array on an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), [AI Consumer](/ai-gateway/entities/ai-consumer/), or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/), or create it as a global AI Policy to apply it to all {{site.ai_gateway}} traffic on the data plane. See [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

The following example creates a global Rate Limiting Policy that allows 100 requests per minute per AI Consumer:

{% entity_example %}
type: policy
data:
  display_name: Rate Limiting - Global
  name: rate-limiting-global
  type: rate-limiting
  enabled: true
  global: true
  config:
    minute: 100
    limit_by: consumer
    policy: local
formats:
  - kongctl
{% endentity_example %}

## Strategies

{% include md/ai-gateway/v2/policies/rate-limiting/strategies.md %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md %}

## Limit by

{% include md/ai-gateway/v2/policies/rate-limiting/limit-by.md %}

## Headers sent to the client

{% include md/ai-gateway/v2/policies/rate-limiting/headers.md %}
