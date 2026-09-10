---
description: Limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days, months, or years.
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: AI Rate Limiting Advanced Policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
---

Rate limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days, months, or years.
{% include md/ai-gateway/v2/policies/rate-limiting/identify-clients.md %}

This Policy counts requests. To rate limit on LLM token usage or cost instead, use the [AI Rate Limiting Advanced Policy](/ai-gateway/policies/ai-rate-limiting-advanced/), which reads the token data returned by the AI Model Provider.

## Example

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
