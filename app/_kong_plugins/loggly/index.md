---
title: 'Loggly'
name: 'Loggly'

content_type: plugin

publisher: kong-inc
description: 'Send request and response logs to Loggly'


products:
    - gateway

works_on:
    - on-prem
    - konnect
tags: 
  - logging
search_aliases:
  - logging plugin
topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: loggly.png
related_resources:
  - text: Datadog
    url: /plugins/datadog/

categories:
  - logging

min_version:
  gateway: '1.0'
---

Log request and response data over UDP to [Loggly](https://www.loggly.com).

## Log format

{% include /plugins/logging/log-format.md %}

### Log format definitions 

{% include /plugins/logging/json-object-log.md %}

## Kong process errors

{% include /plugins/logging/kong-process-errors.md %}

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md %}
