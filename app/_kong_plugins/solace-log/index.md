---
title: 'Solace Log'
name: 'Solace Log'

content_type: plugin

publisher: kong-inc
tier: enterprise
description: 'Publish request and response logs to a Solace endpoint or topic'
premium_partner: true

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

Publish request and response logs in `JSON` format to a [Solace](https://solace.com/) endpoint or topic.
For more information, see [Solace Event Messaging Overview](https://docs.solace.com/Messaging/messaging-overview.htm).

Kong also provides plugins for publishing messages to and consuming messages from Solace:
* [Solace Upstream](/plugins/solace-upstream/)
* [Solace Consume](/plugins/solace-consume/)

## Log format

{% include /plugins/logging/log-format.md %}

### Log format definitions 

{% include /plugins/logging/json-object-log.md %}

## Implementation details

This plugin leverages the [log PDK](/gateway/pdk/reference/kong.log/) to collect and [customize](#custom-fields-by-lua) log fields.

The prepared log message is sent to the Solace broker via the official [Solace C API](https://docs.solace.com/API/Messaging-APIs/C-API/c-api-home.htm). The sending job is executed in a background timer context so that it doesn't block client requests.

If the [custom Lua code](#custom-fields-by-lua) associated with the log fields fails to execute, the relevant fields remain untouched.

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md custom_fields_by_lua='config.message.custom_fields_by_lua' custom_fields_by_lua_slug='config-message-custom-fields-by-lua' name=page.name slug=page.slug %}
