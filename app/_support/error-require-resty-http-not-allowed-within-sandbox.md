---
title: 'Error: require "resty.http" not allowed within sandbox'
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
    The plugin runs in a sandbox that blocks `require` of certain modules.
    Add the module to `untrusted_lua_sandbox_requires` (preferred), or set `untrusted_lua` to `on` to disable the sandbox entirely (use with caution).
related_resources:
  - text: "untrusted_lua_sandbox_requires"
    url: /gateway/configuration/#untrusted-lua-sandbox-requires
  - text: "untrusted_lua"
    url: /gateway/configuration/#untrusted-lua
---

## Problem

When using plugins that execute arbitrary Lua code, such as serverless plugins or the Exit Transformer plugin, you may encounter the following error in your {{site.base_gateway}} logs:

```json
{"message":"An unexpected error occurred"}
```
{:.no-copy-code}

A review of the Kong error log shows something similar to the below output:

```
2023/02/10 12:49:34 [error] 2107#0: *2582 [kong] init.lua:317 [pre-function] /usr/local/share/lua/5.1/kong/tools/kong-lua-sandbox.lua:171: /usr/local/share/lua/5.1/kong/tools/sandbox.lua:88: require 'resty.http' not allowed within sandbox, client: 192.168.64.1, server: kong, request: "GET /echo HTTP/1.1", host: "localhost:8000"
```
{:.no-copy-code}

## Cause

This error occurs because plugins that execute arbitrary Lua code run in a sandboxed environment with restricted access to the global environment, and they cannot `require` certain modules like `resty.http` by default.

## Solution

To resolve this error, you have two options:

{:.warning}
> **Warning**: Allowing certain modules may create opportunities to escape the sandbox. 
> For example, allowing `os` or `luaposix` may be unsafe. 
> Turning off the sandbox will allow unchecked access that can cause severe damage.
> Proceed with extreme caution and ensure any such changes are thoroughly vetted in lower environments.

1. Allow the module by setting `untrusted_lua_sandbox_requires` to include the allowed modules. This is the preferred option, as it allows you to specify exactly which modules are permitted. For example:

   ```
   untrusted_lua_sandbox_requires = resty.http
   ```

1. Turn off the sandbox by setting `untrusted_lua` to `on`. This will allow all modules to be required, but it can create significant security risks, so it should only be used as a last resort:

   ```
   untrusted_lua = on
   ```
