---
title: 'UDP Log'
name: 'UDP Log'

content_type: plugin

publisher: kong-inc
description: 'Send request and response logs to a UDP server'

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
icon: udp-log.png

categories:
  - logging

tags:
  - logging

search_aliases:
  - udp-log
  - udp
  - logging
---

Log request and response data to an UDP server.

## Log format

{% include /plugins/logging/log-format.md %}

{% include /plugins/logging/json-object-log.md %}

## Kong process errors

{% include plugins/logging/kong-process-errors.md %}

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md %}
