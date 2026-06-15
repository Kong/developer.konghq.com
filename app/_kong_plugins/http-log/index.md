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
    a: The HTTP Log plugin doesn't provide latency metrics at this granular level. Instead, use [{{site.konnect_short_name}} Debugger](/observability/debugger/).

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

{% include /plugins/logging/log-custom-fields-by-lua.md 
custom_fields_by_lua='config.custom_fields_by_lua' 
custom_fields_by_lua_slug='config-custom-fields-by-lua' 
custom_fields_by_lua_name='custom_fields_by_lua' 
name=page.name 
slug=page.slug %}

## mTLS support {% new_in 3.15 %}

The HTTP Log plugin supports mutual TLS (mTLS) when connecting to a log server.
When mTLS is enabled, {{site.base_gateway}} presents a client certificate to the log server during the TLS handshake,
and the log server presents its certificate to {{site.base_gateway}}.

To use mTLS for HTTP logging:
1. Create a [Certificate](/gateway/entities/certificate/) entity in {{site.base_gateway}} containing the client certificate and private key that {{site.base_gateway}} will present to the log server.
1. Configure the plugin's [`config.client_certificate`](/plugins/http-log/reference/#schema--config-client-certificate) parameter to reference that Certificate entity by ID.
1. Configure {{site.base_gateway}} to trust the CA that signed the log server's certificate by setting `lua_ssl_trusted_certificate` in `kong.conf`, or the `KONG_LUA_SSL_TRUSTED_CERTIFICATE` environment variable.

For more information, see:
* [Basic configuration example](/plugins/http-log/examples/mtls/)
* [How-to: Configure HTTP logging over mTLS](/how-to/configure-mtls-for-http-log/)