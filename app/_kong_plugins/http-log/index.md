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

## Queueing

The HTTP Log plugin uses internal queues to decouple the production of
log entries from their transmission to the upstream log server.  In
contrast to other plugins that use queues, it shares one queue
between all plugin instances that use the same log server parameter.
The equivalence of the log server is determined by the parameters
`http_endpoint`, `method`, `content_type`, `timeout`, and `keepalive`.
All plugin instances that have the same values for these parameters
share one queue.

Queues are not shared between workers and queueing parameters are
scoped to one worker.  For whole-system capacity planning, the number
of workers need to be considered when setting queue parameters.

## Kong process errors

{% include /md/plugins-hub/kong-process-errors.md %}

{:.note}
> **Note:** If the `max_batch_size` argument > 1, a request is logged as an array of JSON objects.

## Log format

{% include /md/plugins-hub/log-format.md %}

### JSON object descriptions

{% include /md/plugins-hub/json-object-log.md %}


## Custom headers

The log server that receives these messages might require extra headers, such as for authorization purposes.

```yaml
- name: http-log
  config:
    headers:
      Authorization: "Bearer <token>"
```

## Custom fields by Lua

{% include /md/plugins-hub/log_custom_fields_by_lua.md %}