---
title: 'Exit Transformer'
name: 'Exit Transformer'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Customize Kong exit responses sent downstream'


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

icon: exit-transformer.png

categories:
  - transformations

tags:
  - transformations

search_aliases:
  - exit-transformer

min_version:
  gateway: '1.3'
---

Transform and customize {{site.base_gateway}} response exit messages using Lua functions.
The plugin's capabilities range from changing messages, status codes, and headers,
to completely transforming the structure of {{site.base_gateway}} responses. 

Responses originating from upstream services can't be intercepted or transformed by this plugin.


{:.info}
> [`untrusted_lua`](/gateway/configuration/#untrusted-lua)
must be set to either `on` or `sandbox` in your `kong.conf` file for this plugin 
to work. The default value is `sandbox`, which means that Lua functions are allowed,
but will be executed in a sandbox which has limited access to the {{site.base_gateway}} global
environment.

## Handling unmatched 400 and 404 responses

You can configure the Exit Transformer plugin to handle `400` and `404` responses by enabling the 
following parameters:

- `handle_unknown`: This parameter allows the plugin to handle `404` responses. It must be used on a globally configured instance of the plugin running in the default Workspace.
- `handle_unexpected`: This parameter allows the plugin to handle `400` responses. It can be enabled on any plugin scope.

## Function syntax

The Exit Transformer plugin expects a configuration function to be Lua code that returns
a function accepting three arguments: status, body, and headers. For example:

```lua
return function(status, body, headers)
 return status, body, headers
end
```

Any {{site.base_gateway}} exit call exposed on the proxy side gets reduced through these
functions.

{:.warning}
> **Caution**: `kong.response.exit()` requires a `status` argument only.
`body` and `headers` may be `nil`.
If you manipulate the body and headers, first check that they exist and
instantiate them if they don't exist.