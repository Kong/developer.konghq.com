---
description: 'Block requests with bodies greater than a specified size.'
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
---

Block incoming requests where the body is greater than a specific size.
You can limit the payload size in bytes, kilobytes, or megabytes (default).

Because prompt payloads are client-controlled and can be large, capping request size stops oversized bodies before {{site.ai_gateway}} forwards them to an AI Model Provider.

{:.warning}
> For security reasons, we suggest enabling this Policy across your {{site.ai_gateway}} traffic to prevent a DOS (Denial of Service) attack.

## Example

The following example creates a global Request Size Limiting Policy that rejects any request body larger than 256 kilobytes.

{% entity_example %}
type: policy
data:
  display_name: Request Size Limiting - Global
  name: request-size-limiting-global
  type: request-size-limiting
  enabled: true
  global: true
  config:
    allowed_payload_size: 256
    size_unit: kilobytes
formats:
  - kongctl
{% endentity_example %}
