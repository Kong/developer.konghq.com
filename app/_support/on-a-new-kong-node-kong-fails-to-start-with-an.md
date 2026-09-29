---
title: "On a new Kong node, Kong fails to start with the error \"<plugin-name> plugin is in use but not enabled\""
content_type: support
description: This error means a plugin is configured on a route, service, or consumer (and recorded in the Kong database) but is not enabled in this node's `plugins` configuration option.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does a new Kong node fail to start with "<plugin-name> plugin is in use but not enabled"?
  a: |
    A plugin is configured on a route, service, or consumer in the shared Kong database, but this node's `plugins` parameter (or `KONG_PLUGINS` env var) doesn't include it, or the plugin's Lua files aren't installed on the node. Add the plugin name to `plugins`, or install the missing plugin files. This can also happen when a previously deprecated plugin has been removed in the version you're upgrading to — remove the plugin from all configurations before upgrading.
---

## Problem

We have brought a new Kong node accessing an existing database, but Kong is not starting, and we are seeing the following error:

```
[error] init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:385: <plugin-name> plugin is in use but not enabled
stack traceback:
	[C]: in function 'assert'
	/usr/local/share/lua/5.1/kong/init.lua:385: in function 'init'
	init_by_lua:3: in main chunk
```

## Cause

This error means that you have configured a plugin on a route/service/consumer and the fact that this plugin is configured is reflected in the Kong database but the custom plugin is not enabled as part of the `plugins` configuration option.

## Solution

There are two possible scenarios where this can happen:

1. You have configured a custom plugin but on the new Kong node the custom plugin was not enabled as part of the `plugins` parameter. In other words, the `plugins` parameter is missing the custom plugin name which can be addressed by changing:

   `plugins = bundled` to `plugins = bundled, <nameofcustomplugin>`

   or setting:

   `KONG_PLUGINS=bundled, <nameofcustomplugin>`

   Note that when you do this, and the Kong node is missing the actual custom plugin lua files, you will get a slightly different error:

   ```
   [error] init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:464: error loading plugin schemas: on plugin '<plugin-name>': <plugin-name> plugin is enabled but not installed;
   kong.plugins.custom-forward-proxy.handler
   stack traceback:
   	[C]: in function 'assert'
   	/usr/local/share/lua/5.1/kong/init.lua:464: in function 'init'
   	init_by_lua:3: in main chunk
   ```

   To address this issue, you need to make sure that the custom plugin files have actually been installed on the Kong node where you see this issue.

2. Albeit very rare, it is possible that this error happens after an upgrade when a Kong plugin had been deprecated before, and has now been removed in the version you are upgrading to. Please make sure to check in the Kong change log if this has happened before upgrading.

   In this case, please make sure you remove the plugin from all routes/services/consumers and global configurations before upgrading to the version of Kong that no longer contains the plugin.
</content>
