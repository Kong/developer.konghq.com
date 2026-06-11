---
title: "Kong Gateway: Install custom lua library manually (not using luarocks)"
content_type: support
description: The custom library would need to be installed on Kong for the plugin to be able to reference the library.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
---

## Problem

We would like to deploy a custom plugin that is utilizing a custom library without installing through a custom image or through luarocks.

We are receiving the error:

```
[error] 1#0: init_by_lua error: /usr/local/share/lua/5.1/kong/tools/utils.lua:706: error loading module ‘kong.plugins.samplePlugin.handler’: ...l/share/lua/5.1/kong/plugins/samplePlugin/handler.lua:2: module ‘custom.lua’ not found:No LuaRocks module found for custom.lua
```

## Solution

The custom library would need to be installed on Kong for the plugin to be able to reference the library.

We can create a volume on our docker compose file to map the library over to the following location:

`/usr/local/share/lua/5.1/`

Docker compose example:

```yaml
volumes:
    - ./sampleLibrary/:/usr/local/share/lua/5.1/sampleLibrary
```

The `custom.lua` file that is being referenced needs to be inside the `/usr/local/share/lua/5.1/sampleLibrary` folder. If it is in a subdirectory it will continue to fail to load.
