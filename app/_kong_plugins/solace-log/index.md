---
title: 'Solace Log'
name: 'Solace Log'

content_type: plugin

publisher: kong-inc
tier: enterprise
description: 'Publish request and response logs to a Solace topic'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - logging
  - events
  - solace

search_aliases:
  - solace-log
  - events
  - event-gateway

icon: solace-log.png

categories:
   - logging

related_resources:
  - text: Solace Upstream plugin
    url: /plugins/solace-upstream/
  - text: Solace Consume plugin
    url: /plugins/solace-consume/
  - text: Event Gateway
    url: /event-gateway/
---

Publish request and response logs to a [Solace](https://solace.com/) topic.
For more information, see [Understanding Solace topics](https://docs.solace.com/Get-Started/what-are-topics.htm).

Kong also provides Solace plugins for request and response transformations:
* [Solace Upstream](/plugins/solace-upstream/)
* [Solace Consume](/plugins/solace-consume/)

## Log format

{% include /plugins/logging/log-format.md %}

## Implementation details

TBA

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md custom_fields_by_lua='config.message.custom_fields_by_lua' custom_fields_by_lua_slug='config-message-custom-fields-by-lua' name=page.name slug=page.slug %}
