---
title: 'HTTP Log'
name: 'HTTP Log'

content_type: plugin

publisher: kong-inc
description: 'Send request and response logs to an HTTP server'

products:
    - gateway

works_on:
    - on-prem
    - konnect

tags:
  - logging

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: http-log.png

categories:
  - logging

search_aliases:
  - http-log

related_resources:
  - text: Logging plugins
    url: /plugins/?category=logging
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
  - text: "{{site.konnect_short_name}} logs"
    url: /dedicated-cloud-gateways/konnect-logs/

faqs:
  - q: When does the HTTP Log plugin record log entries in a request/response timeline?
    a: The log is executed after {{site.base_gateway}} sends the last response byte to the client. 
  - q: Can the HTTP Log plugin expose latency metrics for individual phases of the request lifecycle (such as `rewrite`, `access`, `header_filter`, and `body_filter`)?
    a: The HTTP Log plugin doesn't provide latency metrics at this granular level. Instead, use [the Debugger {{site.konnect_short_name}}](/observability/debugger/).

min_version:
  gateway: '1.0'
---

The HTTP Log plugin lets you send request and response logs to an HTTP server.

It also supports stream data (TCP, TLS, and UDP).

## Kong process errors

{% include plugins/logging/kong-process-errors.md %}

{:.info}
> **Note:** If the `max_batch_size` argument > 1, a request is logged as an array of JSON objects.

## Log format

{% include /plugins/logging/log-format.md %}

{% include /plugins/logging/json-object-log.md %}

## Queuing

{% include_cached /plugins/queues.md name=page.name %}

### Shared queues in HTTP Log plugin instances

In contrast to other plugins that use queues, all HTTP Log plugin instances that have the same values for the following parameters share one queue:

* [`config.http_endpoint`](./reference/#schema--config-http-endpoint)
* [`config.method`](./reference/#schema--config-method)
* [`config.content_type`](./reference/#schema--config-content-type)
* [`config.timeout`](./reference/#schema--config-timeout)
* [`config.keepalive`](./reference/#schema--config-keepalive)

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md custom_fields_by_lua='config.custom_fields_by_lua' custom_fields_by_lua_slug='config-custom-fields-by-lua' name=page.name slug=page.slug %}
