---
title: 'TCP Log'
name: 'TCP Log'

content_type: plugin

publisher: kong-inc
description: 'Send request and response logs to a TCP server'

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
icon: tcp-log.png

categories:
  - logging

tags:
  - logging

search_aliases:
  - tcp-log
  - tcp
  - logging

min_version:
  gateway: '1.0'
---

Log request and response data to a TCP server.

## Log format

{% include /plugins/logging/log-format.md %}

{% include /plugins/logging/json-object-log.md %}

## Kong process errors

{% include plugins/logging/kong-process-errors.md %}

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md 
custom_fields_by_lua='config.custom_fields_by_lua' 
custom_fields_by_lua_slug='config-custom-fields-by-lua' 
custom_fields_by_lua_name='custom_fields_by_lua' 
name=page.name 
slug=page.slug %}

### Array indices {% new_in 3.15 %}

{% include /plugins/logging/lua-custom-array-indices.md 
custom_fields_by_lua='config.custom_fields_by_lua' 
custom_fields_by_lua_slug='config-custom-fields-by-lua' 
custom_fields_by_lua_name='custom_fields_by_lua' 
name=page.name 
slug=page.slug %}

### Special characters {% new_in 3.10 %}

{% include /plugins/logging/custom-lua-special-characters.md 
custom_fields_by_lua='config.custom_fields_by_lua' 
custom_fields_by_lua_slug='config-custom-fields-by-lua' 
custom_fields_by_lua_name='custom_fields_by_lua' 
name=page.name 
slug=page.slug %}

### Plugin precedence and managing fields

{% include /plugins/logging/custom-lua-plugin-precedence.md 
custom_fields_by_lua='config.custom_fields_by_lua' 
custom_fields_by_lua_slug='config-custom-fields-by-lua' 
custom_fields_by_lua_name='custom_fields_by_lua' 
name=page.name 
slug=page.slug %}

### Limitations

{% include /plugins/logging/custom-lua-limitations.md %}