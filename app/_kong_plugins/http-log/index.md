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
---

The HTTP Log plugin lets you send request and response logs to an HTTP server.

It also supports stream data (TCP, TLS, and UDP).

## Queuing

The HTTP Log plugin uses internal queues to decouple the production of log entries from their transmission to the upstream log server. 
You can find the queue parameters under [`config.queue`](./reference/#schema--config-queue) in the plugin configuration. 
For more information about how to use these parameters, see the [plugin queuing reference](/gateway/entities/plugin/#plugin-queuing).

In contrast to other plugins that use queues, all plugin instances that have the same values for the following parameters share one queue:

* [`config.http_endpoint`](./reference/#schema--config-http-endpoint)
* [`config.method`](./reference/#schema--config-method)
* [`config.content_type`](./reference/#schema--config-content-type)
* [`config.timeout`](./reference/#schema--config-timeout)
* [`config.keepalive`](./reference/#schema--config-keepalive)

Queues are not shared between workers and queuing parameters are scoped to one worker. 
For whole-system capacity planning, the number of workers needs to be considered when setting queue parameters.

## Kong process errors

{% include plugins/logging/kong-process-errors.md %}

{:.info}
> **Note:** If the `max_batch_size` argument > 1, a request is logged as an array of JSON objects.

## Log format

{% include /plugins/logging/log-format.md %}

{% include /plugins/logging/json-object-log.md %}

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md %}
