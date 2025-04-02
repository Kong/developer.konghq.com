---
title: 'Kong Functions (Pre-Plugins)'
name: 'Pre-Function'

content_type: plugin

publisher: kong-inc
description: 'Add and manage custom Lua functions to run before other plugins'

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
icon: pre-function.png

categories:
  - serverless

search_aliases:
  - pre-function
  - serverless function
  - serverless functions

tags:
  - serverless

related_resources:
  - text: Apply rate limits based on peak and off-peak time with Pre-Function
    url: /how-to/rate-limit-based-on-peak-time/
  - text: Filter requests based on header names
    url: /how-to/filter-requests-based-on-header-names/
  - text: Post-Function plugin
    url: /plugins/post-function/
---

The Pre-Function plugin (also known as Kong Functions, Pre-Plugin) lets
you dynamically run Lua code from {{site.base_gateway}} before other plugins in each phase.

This plugin is part of a pair of serverless plugins. 
If you need to run Lua code _after_ other plugins in each phase, see the [Post-Function](/plugins/post-function/) plugin.

{:.warning}
> **Warning:** The Pre-function and Post-function serverless plugins allow anyone who can enable the plugin to execute arbitrary code.
If your organization has security concerns about this, [disable the plugins](/gateway/configuration/#untrusted-lua) in your `kong.conf` file.

## Phases

The Pre-Function plugin can run custom Lua code in any of the following [phases](/gateway/entities/plugin/#plugin-contexts) in {{site.base_gateway}}'s lifecycle:
* `access`
* `body_filter`
* `certificate`
* `header_filter`
* `log`
* `rewrite`
* `ws_client_frame`
* `ws_close`
* `ws_handshake`
* `ws_upstream_frame`

To run the Pre-Function plugin in a specific phase, use a `config.{phase_name}` parameter.
For example, to run the plugin in the `header_filter` phase, use `config.header_filter`. 

You can also run the plugin in multiple phases. See [Running Pre-Function in multiple phases](./examples/run-in-multiple-phases/) for an example.

## Passing Lua code to the plugin

{% include_cached /plugins/serverless/passing-lua-code.md name=page.name slug=page.slug %}

## Upvalues

You can return a function to run on each request, allowing for upvalues to keep state in between requests:

```lua
-- this runs once on the first request
local count = 0

return function()
  -- this runs on each request
  count = count + 1
  ngx.log(ngx.ERR, "hello world: ", count)
end
```

## Sandboxing

The provided Lua environment is sandboxed.

{% include_cached /plugins/sandbox.md %}