---
title: "Error: require 'resty.http' not allowed within sandbox"
content_type: support
description: Plugins that execute arbitrary Lua code run in a sandbox that blocks require of certain modules; allow the module or disable the sandbox to resolve it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why do I get \"require 'resty.http' not allowed within sandbox\" when using a plugin that runs Lua code?"
  a: |
    Plugins that execute arbitrary Lua code (such as serverless plugins or the exit transformer)
    run in a sandbox with restricted access to the global environment, so they cannot `require`
    certain modules like `resty.http`. To resolve it, either set `untrusted_lua_sandbox_requires`
    to include the allowed modules (the preferred option, e.g. `untrusted_lua_sandbox_requires = resty.http`),
    or turn off the sandbox by setting `untrusted_lua` to `on`. Allowing modules or disabling the
    sandbox can create opportunities to escape it, so proceed with caution.
related_resources:
  - text: "`untrusted_lua_sandbox_requires`"
    url: /gateway/configuration/#untrusted-lua-sandbox-requires
  - text: "`untrusted_lua`"
    url: /gateway/configuration/#untrusted-lua
---

## Problem

When attempting to use a plugin that allows execution of arbitrary Lua code (that is, serverless plugins, exit transformer, and so on) you receive the message:

```json
{"message":"An unexpected error occurred"}
```

A review of the Kong error log shows something similar to the below:

```
2023/02/10 12:49:34 [error] 2107#0: *2582 [kong] init.lua:317 [pre-function] /usr/local/share/lua/5.1/kong/tools/kong-lua-sandbox.lua:171: /usr/local/share/lua/5.1/kong/tools/sandbox.lua:88: require 'resty.http' not allowed within sandbox, client: 192.168.64.1, server: kong, request: "GET /echo HTTP/1.1", host: "localhost:8000"
```

## Cause

These types of plugins, by default, operate in a sandboxed environment. The sandbox function has restricted access to the global environment and only has access to standard Lua functions that will generally not cause harm to the {{site.base_gateway}} node. This means you cannot arbitrarily "require" certain modules, in our example here `resty.http`.

## Solution

There are two options to resolve this, however you should be aware of the potential risks.

Warning:

Allowing certain modules may create opportunities to escape the sandbox. For example, allowing `os` or `luaposix` may be unsafe. Turning off the sandbox will allow unchecked access that can cause severe damage. Proceed with extreme caution and ensure any such changes are thoroughly vetted in lower environments.

1. The preferred option is to set the `untrusted_lua_sandbox_requires` parameter to include the modules allowed to be loaded with "require" inside the sandboxed environment. This will give you more control allowing you to explicitly and consciously define a list.

   ```
   untrusted_lua_sandbox_requires = resty.http
   ```

2. Turn off the sandbox environment by setting `untrusted_lua` to on. This allows functions to have unrestricted access to the global environment and can load any Lua modules.
