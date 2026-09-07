---
title: How to log the workspace name using the HTTP or file log plugins
content_type: support
description: "Learn how to include the workspace name in `http-log` and `file-log` output using Kong Gateway's built-in `workspace_name` log field, or a custom `custom_fields_by_lua` field for legacy setups."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: documented here
    url: /gateway/configuration/#untrusted-lua-sandbox-requires
tldr:
  q: How do I log the Kong workspace name using the `http-log` or `file-log` plugins?
  a: |
    Kong Gateway Enterprise already adds a `workspace_name` field to the log-serializer output for `http-log`/`file-log` (and other log plugins), with no configuration needed. If you need the value under a custom key, opt into the legacy `untrusted_lua = sandbox` tier and set `untrusted_lua_sandbox_requires = kong.workspaces` to add a custom `custom_fields_by_lua` field instead.
---

## Overview

How to add the workspace name to the HTTP or file logs.

## Steps

Kong Gateway (Enterprise) already includes a native `workspace_name` field in the log-serializer output for `http-log`/`file-log` (and every other log plugin), e.g. `"workspace_name":"default"`, with zero configuration required. This is the recommended way to get the workspace's name into your logs and requires no custom Lua.

If you need the value under a custom key, or combined with other logic, you can still leverage custom fields by Lua. Note that `untrusted_lua` defaults to `strict`, and under `strict` (or the `lax` tier), `untrusted_lua_sandbox_requires` has no effect at all -- it is only consulted by the legacy `sandbox` tier. To use the recipe below, first explicitly opt into the legacy sandbox tier by setting both

```conf

untrusted_lua = sandbox
untrusted_lua_sandbox_requires = kong.workspaces
```

(`KONG_UNTRUSTED_LUA=sandbox` and `KONG_UNTRUSTED_LUA_SANDBOX_REQUIRES=kong.workspaces` as environment variables), as documented here. With that in place, the following custom field can be configured

```json

 "custom_fields_by_lua": { "ws_name": "local workspaces=require \"kong.workspaces\" local get_ws_id=workspaces.get_workspace_id local fetch_ws=workspaces.select_workspace_by_id_with_cache local ws_id=get_ws_id() local ws=ws_id and fetch_ws(ws_id) local ws_name=ws and ws.name return ws_name" }
```

When setting it up on the manager GUI, it looks like so:

The image above truncates the full line used. Here it is for reference.

```lua

local workspaces=require "kong.workspaces" local get_ws_id=workspaces.get_workspace_id local fetch_ws=workspaces.select_workspace_by_id_with_cache local ws_id=get_ws_id() local ws=ws_id and fetch_ws(ws_id) local ws_name=ws and ws.name return ws_name
```

Here’s a snippet from the resulting log, when using the `file-log` plugin

```

{"upstream_uri":"/anything","workspace":"6044b661-6f96-4e0c-9d31-40027d50ee25","ws_name":"testDK","response":{"size":303,"headers":{"content-type":"application/json; charset=utf-8","content-length":"58","connection":"close","server":"kong/3.14.0.0-enterprise-edition","x-kong-response-latency":"5"} ....
```

Note the added field:

```

"ws_name":"testDK"
```

HTTP log can be used as well to the same effect. If `untrusted_lua` is left at its default (`strict`) and only `untrusted_lua_sandbox_requires` is set, `require("kong.workspaces")` is not allowed and the log plugin fails to add the custom field (though the plugin fails open, so the request itself still succeeds) -- both settings above (`untrusted_lua = sandbox` and `untrusted_lua_sandbox_requires = kong.workspaces`) must be set together for the recipe to work.
