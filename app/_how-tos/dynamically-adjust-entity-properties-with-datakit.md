---
title: Adjust Gateway Service and Route configuration using Datakit
content_type: how_to
description: Use the Datakit plugin to dynamically adjust Gateway Service and Route configuration.
products:
    - gateway

works_on:
    - on-prem

plugins:
  - datakit

entities: 
  - service
  - route
  - plugin

tags:
  - get-started
  - transformations

tldr: 
  q: How can I dynamically adjust Gateway Service and Route configuration based on 
  a: |
    Datakit is a {{site.base_gateway}} plugin that allows you to interact with third-party APIs.
    In this guide, learn how to configure the plugin to dynamically adjust Gateway Service and Route configuration, then run the Post-Function plugin in the `header_filter` and `access` phases.
tools:
  - deck

prereqs:
  skip_product: true
  inline:
    - title: "{{site.base_gateway}} license"
      include_content: prereqs/gateway-license
      icon_url: /assets/icons/gateway.svg

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.11'

related_resources:
  - text: Datakit plugin
    url: /plugins/datakit/

faqs:
  - q: How do I run Datakit in {{site.base_gateway}} 3.9 or 3.10?
    a: |
      Prior to 3.11, Datakit ran on the WASM engine. 
      If you are running {{site.base_gateway}} 3.9 or 3.10, set `wasm=on` in `kong.conf`, then reload your {{site.base_gateway}} instance before configuring the plugin.
---

```yaml
services:
- name: demo
  url: http://httpbin.konghq.com
  routes:
  - name: my-route
    paths:
    - /anything
    strip_path: false
    methods:
    - GET
    - POST
    plugins:
    - name: post-function
      config:
        access:
        - |
          local cjson = require("cjson")

          kong.ctx.shared.from_lua = cjson.encode({
            nested = {
              message = "hello from lua land!",
            },
          })
        header_filter:
        - |
          local cjson = require("cjson")
          local ctx = kong.ctx.shared

          local api_response = ctx.api_response or "null"
          local res = cjson.decode(api_response)

          kong.response.set_header("X-Lua-Encoded-Object", api_response)
          kong.response.set_header("X-Lua-Plugin-Country", res.country)
          kong.response.set_header("X-Lua-Plugin-My-String", ctx.my_string)
          kong.response.set_header("X-Lua-Plugin-My-Encoded-String", ctx.my_encoded_string)
    - name: datakit
      config:
        debug: true
        nodes:
        #
        # read "built-in" kong properties
        #
        - name: ROUTE_ID
          type: property
          property: kong.route_id

        - name: SERVICE
          type: property
          property: kong.router.service
          content_type: application/json

        #
        # access values from ctx
        #
        - name: LUA_VALUE_ENCODED
          type: property
          property: kong.ctx.shared.from_lua

        - name: LUA_VALUE_DECODED
          type: property
          property: kong.ctx.shared.from_lua
          content_type: application/json

        #
        # make an external API call and stash the result in kong.ctx.shared
        #
        - name: API
          type: call
          url: https://api.zippopotam.us/br/93000-000

        - name: SET_API_RESPONSE
          type: property
          property: kong.ctx.shared.api_response
          input: API.body

        #
        # fetch a property that we know does not exist
        #
        - name: UNSET_PROP
          type: property
          # should return `null`
          property: kong.ctx.shared.nothing_here

        #
        # emit a JSON-encoded string from jq and store it in kong.ctx.shared
        #
        - name: JSON_ENCODED_STRING
          type: jq
          jq: '"my string"'

        # encode as `my string`
        - name: SET_MY_STRING_PLAIN
          type: property
          input: JSON_ENCODED_STRING
          property: kong.ctx.shared.my_string

        # [JSON-]encode as `"my string"`
        - name: SET_MY_STRING_ENCODED
          type: property
          input: JSON_ENCODED_STRING
          property: kong.ctx.shared.my_encoded_string
          content_type: application/json

        # get `my string`, return `my string`
        - name: GET_PLAIN_STRING
          type: property
          property: kong.ctx.shared.my_string

        # get `"my string"`, return `"my string"`
        - name: GET_JSON_STRING_ENCODED
          type: property
          property: kong.ctx.shared.my_encoded_string

        # get `"my string"`, decode, return `my string`
        - name: GET_JSON_STRING_DECODED
          type: property
          property: kong.ctx.shared.my_encoded_string
          content_type: application/json

        #
        # assemble a response
        #
        - name: BODY
          type: jq
          inputs:
            # value is also fetched after being set
            API_body: API.body
            SERVICE: SERVICE
            ROUTE_ID: ROUTE_ID
            LUA_VALUE_ENCODED: LUA_VALUE_ENCODED
            LUA_VALUE_DECODED: LUA_VALUE_DECODED
            UNSET_PROP: UNSET_PROP
            GET_PLAIN_STRING: GET_PLAIN_STRING
            GET_JSON_STRING_ENCODED: GET_JSON_STRING_ENCODED
            GET_JSON_STRING_DECODED: GET_JSON_STRING_DECODED
          jq: |
            {
              "API.body": $API_body,
              SERVICE: $SERVICE,
              ROUTE_ID: $ROUTE_ID,
              LUA_VALUE_ENCODED: $LUA_VALUE_ENCODED,
              LUA_VALUE_DECODED: $LUA_VALUE_DECODED,
              UNSET_PROP: $UNSET_PROP,
              GET_PLAIN_STRING: $GET_PLAIN_STRING,
              GET_JSON_STRING_ENCODED: $GET_JSON_STRING_ENCODED,
              GET_JSON_STRING_DECODED: $GET_JSON_STRING_DECODED,
            }

        - name: exit
          type: exit
          inputs:
            body: BODY
```