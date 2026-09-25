---
title: "Custom plugins not loading with no LuaRocks module found for `kong.plugins.base_plugin`"
content_type: support
description: Custom plugins that extend the removed `kong.plugins.base_plugin` module fail to load on Kong 3.0.0.0 and later with a "No LuaRocks module found" error; update the plugin to the newer handler pattern.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do my custom plugins fail to load with "No LuaRocks module found for kong.plugins.base_plugin"?
  a: |
    The `kong.plugins.base_plugin` module was deprecated in Kong v2.4.x and removed in v3.0.x. A custom plugin whose handler still inherits from `base_plugin` will fail to load with this LuaRocks error on Kong 3.x. Update the plugin to the newer handler pattern that doesn't extend `BasePlugin`.
related_resources:
  - text: Kong Enterprise changelog (deprecated features)
    url: https://legacy-gateway--kongdocs.netlify.app/enterprise/changelog/#deprecated
  - text: Kong custom plugins documentation (handler.lua)
    url: /custom-plugins/handler.lua/
  - text: Migration from BasePlugin
    url: /custom-plugins/handler.lua/#migrating-from-the-baseplugin-module
---

## Problem

When starting a Kong EE 3.x instance, custom plugins are causing the startup to fail. There is an error shown for a missing LuaRocks module `kong.plugins.base_plugin`. For example;

```

2026/08/27 07:18:53 [error] 1#0: init_by_lua error: /usr/local/share/lua/5.1/kong/tools/module.lua:36: error loading module 'kong.plugins.my-custom-plugin.handler':
/usr/local/share/lua/5.1/kong/plugins/my-custom-plugin/handler.lua:1: module 'kong.plugins.base_plugin' not found:No LuaRocks module found for kong.plugins.base_plugin
no field package.preload['kong.plugins.base_plugin']
```

## Cause

The significant message is:

```
module 'kong.plugins.base_plugin' not found:No LuaRocks module found for kong.plugins.base_plugin
no field package.preload['kong.plugins.base_plugin']
```

The code for the custom plugin is inheriting from the `base_plugin` module. This module has been deprecated from 2.4.1.0 and has been removed in 3.0.0.0.

The `BasePlugin` class was deprecated in Kong v2.4.x and will be removed in v3.0.x. Plugins that extend `base_plugin.lua` will continue to work until v3.0.x but should be updated to the newer, simpler pattern.

## Solution

You will need to update your plugin to use the newer code format as per the docs.
