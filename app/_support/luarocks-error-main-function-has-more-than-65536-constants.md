---
title: "\"main function has more than 65536 constants\" LuaRocks error when building custom Kong plugins or images"
content_type: support
description: LuaRocks has reached a LuaJIT limit that prevents rocks from being published or installed. This doesn't affect existing production deployments or images, but does impact new custom plugin development or building of new custom images that have dependencies on LuaRocks.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the official luarocks install guide
    url: https://luarocks.org/
tldr:
  q: Why does LuaRocks fail with "main function has more than 65536 constants"?
  a: |
    LuaRocks has hit a LuaJIT bytecode limit that blocks publishing or installing rocks, which affects new custom plugin development and custom image builds (not existing production deployments). Kong has released patched LuaRocks versions; if you can't upgrade yet, install LuaRocks 3.12.0, pin to an older rocks snapshot, or use the pure-Lua LuaRocks workaround described in the article.
---

## Problem

LuaRocks, which is a popular package management system for the Lua ecosystem, has reached a LuaJIT limit which is preventing rocks from being published or installed. The system reports the following error message:

```
Error: main function has more than 65536 constants
```

## Solution

This issue does not affect existing production deployments or images, but does impact new custom plugin development or building of new custom images that have dependencies on LuaRocks.

Kong is actively working on a solution to this problem in coordination with the upstream LuaRocks project. As the solution depends on LuaRocks project approval, we are not able to provide a precise date.

We have issued the following patches that bumped LuaRocks from 3.11.0 to 3.11.1, which addresses the issue.

<!--vale off -->
{% table %}
columns:
  - title: Version
    key: version
  - title: Fix Version
    key: fix_version
rows:
  - version: "3.10.x"
    fix_version: "3.10.0.2"
  - version: "3.9.x"
    fix_version: "3.9.1.2"
  - version: "3.8.x"
    fix_version: "3.8.1.2"
  - version: "3.4.x"
    fix_version: "3.4.3.20"
{% endtable %}
<!--vale on -->

For customers with urgent needs that cannot upgrade to the patches listed, there are a number of workarounds:

Option 1 - Update to Luarocks 3.12.0

Follow the official luarocks install guide to install luarocks 3.12.0.

Option 2 - Use an old snapshot of luarocks

If the customer doesn’t need the latest rocks (uploaded/updated after May 29, 2025), they could use the following command to substitute the `luarocks` command with:

```bash
luarocks --only-server https://raw.githubusercontent.com/rocks-moonscript-org/moonrocks-mirror/daab2726276e3282dc347b89a42a5107c3500567
```

Option 3 - Install a luarocks that runs on pure lua.

1. Install a Lua interpreter from a system package manager (`apt-get install lua5.1`, `yum install lua`, `apk add lua`).
2. Save the below code into a file called `luarocks-system-lua`.
3. Substitute the `luarocks` command with `luarocks luarocks-system-lua`

Script:

```lua
#!/usr/bin/lua
package.loaded["luarocks.core.hardcoded"] = { SYSCONFDIR = [[/usr/local/etc/luarocks]], LUA_VERSION = "5.1" }
package.path=[[/usr/local/share/lua/5.1/?.lua;]] .. package.path
local list = package.searchers or package.loaders; table.insert(list, 1, function(name) if name:match("^luarocks%.") then return loadfile([[/usr/local/share/lua/5.1/]] .. name:gsub([[%.]], [[/]]) .. [[.lua]]) end end)

-- Load cfg first so that the loader knows it is running inside LuaRocks
local cfg = require("luarocks.core.cfg")

local loader = require("luarocks.loader")
local cmd = require("luarocks.cmd")

local description = "LuaRocks main command-line interface"

local commands = {
   init = "luarocks.cmd.init",
   pack = "luarocks.cmd.pack",
   unpack = "luarocks.cmd.unpack",
   build = "luarocks.cmd.build",
   install = "luarocks.cmd.install",
   search = "luarocks.cmd.search",
   list = "luarocks.cmd.list",
   remove = "luarocks.cmd.remove",
   make = "luarocks.cmd.make",
   download = "luarocks.cmd.download",
   path = "luarocks.cmd.path",
   show = "luarocks.cmd.show",
   new_version = "luarocks.cmd.new_version",
   lint = "luarocks.cmd.lint",
   write_rockspec = "luarocks.cmd.write_rockspec",
   purge = "luarocks.cmd.purge",
   doc = "luarocks.cmd.doc",
   upload = "luarocks.cmd.upload",
   config = "luarocks.cmd.config",
   which = "luarocks.cmd.which",
   test = "luarocks.cmd.test",
}

cmd.run_command(description, commands, "luarocks.cmd.external", ...)
```
</content>
