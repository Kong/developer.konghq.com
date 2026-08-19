---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: "{{site.ai_gateway}} logs"
    url: /ai-gateway/ai-logs/
  - text: Logging Policies
    url: /ai-gateway/policies/?category=logging
---

Log request and response data over UDP to [Loggly](https://www.loggly.com).

## Process errors

{% include md/ai-gateway/v2/policies/process-errors.md %}

## Log format

{% include md/ai-gateway/v2/policies/log-format.md %}

## Custom fields by Lua

{% include md/ai-gateway/v2/policies/log-custom-fields-by-lua.md slug="loggly" name="Loggly" base_config="key: your-loggly-customer-token" %}
