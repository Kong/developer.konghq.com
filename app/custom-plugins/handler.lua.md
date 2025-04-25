---
title: handler.lua
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/
  - /custom-plugins/reference/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn how to implement custom plugin logic using handler.lua.

tags:
  - custom-plugins

min_version:
  gateway: '3.4'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: schema.lua reference
    url: /custom-plugins/schema.lua/
---

A {{site.base_gateway}} plugin allows you to inject custom logic in Lua at several
entry-points in the life-cycle of a request/response or a TCP stream
connection as it is proxied by {{site.base_gateway}}. To do so, the file
`kong.plugins.{plugin_name}.handler` must return a table with one or
more functions with predetermined names. Those functions will be
invoked by {{site.base_gateway}} at different phases when it processes traffic.

All functions take `self` as the first parameter. Except for `init_worker` and `configure`, they can also accept a second parameter: a table with the plugin’s configuration. `configure` instead receives an array of all configurations for the plugin.

## Available contexts

{% include plugins/plugin-contexts.md %}

## handler.lua specification

{{site.base_gateway}} processes requests in phases. A plugin is a piece of code that gets
activated by {{site.base_gateway}} as each phase is executed while the request gets proxied.

Phases are limited in what they can do. For example, the `init_worker` phase
doesn't have access to the `config` parameter because that information isn't
available when {{site.base_gateway}} is initializing each worker. On the other hand the `configure` function
is passed with all the active configurations for the plugin (or `nil` if not configured).

A plugin's `handler.lua` must return a table containing the functions it must
execute on each phase.

{{site.base_gateway}} can process HTTP and stream traffic. Some phases are executed
only when processing HTTP traffic, others when processing stream,
and some (like `init_worker` and `log`) are invoked by both kinds of traffic.

In addition to functions, a plugin must define two fields:

* `VERSION` is an informative field, not used by {{site.base_gateway}} directly. It usually
  matches the version defined in a plugin's Rockspec version, when it exists.
* `PRIORITY` is used to sort plugins before executing each of their phases.
  Plugins with a higher priority are executed first. See the
  [plugin execution order](#plugins-execution-order) section
  for more info about this field.

The following example `handler.lua` file defines custom functions for all
the possible phases, in both http and stream traffic. It has no functionality
besides writing a message to the log every time a phase is invoked. 
A plugin doesn't need to provide functions for all phases.

```lua
local CustomHandler = {
  VERSION  = "1.0.0",
  PRIORITY = 10,
}

function CustomHandler:init_worker()
  -- Implement logic for the init_worker phase here (http/stream)
  kong.log("init_worker")
end

function CustomHandler:configure(configs)
  -- Implement logic for the configure phase here
  --(called whenever there is change to any of the plugins)
  kong.log("configure")
end

function CustomHandler:preread(config)
  -- Implement logic for the preread phase here (stream)
  kong.log("preread")
end

function CustomHandler:certificate(config)
  -- Implement logic for the certificate phase here (http/stream)
  kong.log("certificate")
end

function CustomHandler:rewrite(config)
  -- Implement logic for the rewrite phase here (http)
  kong.log("rewrite")
end

function CustomHandler:access(config)
  -- Implement logic for the access phase here (http)
  kong.log("access")
end

function CustomHandler:ws_handshake(config)
  -- Implement logic for the WebSocket handshake here
  kong.log("ws_handshake")
end

function CustomHandler:header_filter(config)
  -- Implement logic for the header_filter phase here (http)
  kong.log("header_filter")
end

function CustomHandler:ws_client_frame(config)
  -- Implement logic for WebSocket client messages here
  kong.log("ws_client_frame")
end

function CustomHandler:ws_upstream_frame(config)
  -- Implement logic for WebSocket upstream messages here
  kong.log("ws_upstream_frame")
end

function CustomHandler:body_filter(config)
  -- Implement logic for the body_filter phase here (http)
  kong.log("body_filter")
end

function CustomHandler:log(config)
  -- Implement logic for the log phase here (http/stream)
  kong.log("log")
end

function CustomHandler:ws_close(config)
  -- Implement logic for WebSocket post-connection here
  kong.log("ws_close")
end

-- return the created table, so that Kong can execute it
return CustomHandler
```

In the example above we are using Lua's `:` shorthand syntax for
functions taking `self` as a first parameter. An equivalent non-shorthand version
of the `access` function would be:

``` lua
function CustomHandler.access(self, config)
  -- Implement logic for the access phase here (http)
  kong.log("access")
end
```

The plugin's logic doesn't need to be all defined inside the `handler.lua` file.
It can be split into several Lua files, also called modules.
The `handler.lua` module can use `require` to include other modules in the plugin.

For example, the following plugin splits the functionality into three files.
`access.lua` and `body_filter.lua` return functions. They are in the same
folder as `handler.lua`, which requires and uses them to build the plugin:

```lua
-- handler.lua
local access = require "kong.plugins.my-custom-plugin.access"
local body_filter = require "kong.plugins.my-custom-plugin.body_filter"

local CustomHandler = {
  VERSION  = "1.0.0",
  PRIORITY = 10
}

CustomHandler.access = access
CustomHandler.body_filter = body_filter

return CustomHandler
```

```lua
-- access.lua
return function(self, config)
  kong.log("access phase")
end
```

```lua
-- body_filter.lua
return function(self, config)
  kong.log("body_filter phase")
end
```

See [the source code of the Key-Auth Plugin](https://github.com/Kong/kong/blob/master/kong/plugins/key-auth/handler.lua)
for an example of a real-life handler code.

### Migrating from the BasePlugin module

The `BasePlugin` module is deprecated and has been removed from
{{site.base_gateway}}. If you have an old plugin that uses this module, replace
the following section:

```lua
--  DEPRECATED --
local BasePlugin = require "kong.plugins.base_plugin"
local CustomHandler = BasePlugin:extend()
CustomHandler.VERSION  = "1.0.0"
CustomHandler.PRIORITY = 10
```

With the current equivalent:
```lua
local CustomHandler = {
  VERSION  = "1.0.0",
  PRIORITY = 10,
}
```

You don't need to add a `:new()` method or call any of the `CustomHandler.super.XXX:(self)`
methods.

## WebSocket Plugin Development

### Handler Functions

Requests to services with the `ws` or `wss` protocol take a different path through
the proxy than regular HTTP requests. Therefore, there are some differences in behavior
that must be accounted for when developing plugins for them.

The following handlers are not executed for WebSocket services:
 - `access`
 - `response`
 - `header_filter`
 - `body_filter`
 - `log`

The following handlers are unique to WebSocket services:
  - `ws_handshake`
  - `ws_client_frame`
  - `ws_upstream_frame`
  - `ws_close`

The following handlers are executed for both WebSocket and non-Websocket services:
  - `init_worker`
  - `configure`
  - `certificate` (TLS/SSL requests only)
  - `rewrite`

Even with these differences, it's possible to develop plugins that support both WebSocket
and non-WebSocket services. 
For example:

```lua
-- handler.lua
--
-- I am a plugin that implements both WebSocket and non-WebSocket handlers.
--
-- I can be enabled for ws/wss services, http/https/grpc/grpcs services, or
-- even as global plugin.
local MultiProtoHandler = {
  VERSION = "0.1.0",
  PRIORITY = 1000,
}

function MultiProtoHandler:access()
  kong.ctx.plugin.request_type = "non-WebSocket"
end

function MultiProtoHandler:ws_handshake()
  kong.ctx.plugin.request_type = "WebSocket"
end


function MultiProtoHandler:log()
  kong.log("finishing ", kong.ctx.plugin.request_type, " request")
end

-- the `ws_close` handler for this plugin does not implement any WebSocket-specific
-- business logic, so it can simply be aliased to the `log` handler
MultiProtoHandler.ws_close = MultiProtoHandler.log

return MultiProtoHandler
```

As seen above, the `log` and `ws_close` handlers are parallel to each other. In
many cases, one can be aliased to the other without having to write any
additional code. The `access` and `ws_handshake` handlers are also very similar in
this regard. The notable difference lies in which PDK functions are available
in each context. For instance, the `kong.request.get_body()` PDK function cannot be
used in an `access` handler because it is fundamentally incompatible with this kind
of request.


### WebSocket requests to non-WebSocket services

When WebSocket traffic is proxied via an HTTP/HTTPS service, it's treated as a
non-WebSocket request. Therefore, the HTTP handlers (`access`, `header_filter`, etc)
will be executed and the WebSocket handlers (`ws_handshake`, `ws_close`, etc) will not.

## Plugin Development Kit

Logic implemented in those phases will most likely have to interact with the
request and response objects or core components (e.g. access the cache, and
database). {{site.base_gateway}} provides a [Plugin Development Kit](/gateway/pdk/reference/) (or "PDK") for such
purposes: a set of Lua functions and variables that can be used by plugins to
execute various gateway operations in a way that is guaranteed to be
forward-compatible with future releases of {{site.base_gateway}}.

When you are trying to implement some logic that needs to interact with {{site.base_gateway}}
(e.g. retrieving request headers, producing a response from a plugin, logging
some error or debug information), you should consult the [Plugin Development Kit reference docs](/gateway/pdk/reference/).

## Plugins execution order

Some plugins might depend on the execution of others to perform some
operations. For example, plugins relying on the identity of the consumer have
to run **after** authentication plugins. Considering this, {{site.base_gateway}} defines
**priorities** between plugins execution to ensure that order is respected.

Your plugin's priority can be configured via a property accepting a number in
the returned handler table:

```lua
CustomHandler.PRIORITY = 10
```

The higher the priority, the sooner your plugin's phases will be executed in
regard to other plugins' phases (such as `:access()`, `:log()`, etc.).

All of the plugins bundled with {{site.base_gateway}} have a static priority.
This can be adjusted dynamically using the `ordering` option. See
[Dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering)
for more information.

The order of execution for the bundled plugins is:

{% plugin_priorities %}
