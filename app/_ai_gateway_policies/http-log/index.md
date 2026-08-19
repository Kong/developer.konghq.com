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
  - text: "{{site.konnect_short_name}} logs"
    url: /dedicated-cloud-gateways/konnect-logs/
faqs:
  - q: When does the HTTP Log Policy record log entries in a request/response timeline?
    a: The log is executed after {{site.ai_gateway}} sends the last response byte to the client.
  - q: Can the HTTP Log Policy expose latency metrics for individual phases of the request lifecycle (such as `rewrite`, `access`, `header_filter`, and `body_filter`)?
    a: The HTTP Log Policy doesn't provide latency metrics at this granular level. Instead, use [{{site.konnect_short_name}} Debugger](/observability/debugger/).
---

The HTTP Log Policy lets you send request and response logs to an HTTP server.

{:.info}
> **Note:** If the `max_batch_size` argument > 1, a request is logged as an array of JSON objects.

## Log format

{% include md/ai-gateway/v2/policies/log-format.md %}

## Queuing

{% include md/ai-gateway/v2/policies/queues.md name="HTTP Log" slug="http-log" %}

### Shared queues in HTTP Log Policy instances

In contrast to other Policies that use queues, all HTTP Log Policy instances that have the same values for the following parameters share one queue:

* [`config.http_endpoint`](/ai-gateway/policies/http-log/reference/#schema--config-http-endpoint)
* [`config.method`](/ai-gateway/policies/http-log/reference/#schema--config-method)
* [`config.content_type`](/ai-gateway/policies/http-log/reference/#schema--config-content-type)
* [`config.timeout`](/ai-gateway/policies/http-log/reference/#schema--config-timeout)
* [`config.keepalive`](/ai-gateway/policies/http-log/reference/#schema--config-keepalive)

## Custom fields by Lua

{% include md/ai-gateway/v2/policies/log-custom-fields-by-lua.md slug="http-log" name="HTTP Log" %}
