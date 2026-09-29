---
title: "`plugin is enabled but not installed` error when Kong can't locate the plugin's source code"
content_type: support
description: "How to resolve the `plugin is enabled but not installed` error, which occurs when Kong can't find a plugin's source code because of the wrong image, a missing plugins directory, or an external volume mount."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong log a `<plugin> plugin is enabled but not installed` error?
  a: |
    This error means Kong can't find the plugin's source code, usually expected in `/usr/local/share/lua/5.1/kong/plugins/<plugin-name>`. Common causes are using an OSS image for an Enterprise-only plugin, the plugins directory being deleted, or an external volume mount overriding it. Restore the plugin's directory (or switch to the correct Kong image) and restart Kong.
---

## Problem

See "xxx plugin is enabled but not installed" like below in the Kong error log:

```
no plugin found; on plugin 'response-transformer-advanced': response-transformer-advanced plugin is enabled but not installed;
no plugin found
stack traceback:
	[C]: in function 'assert'
	/usr/local/share/lua/5.1/kong/init.lua:553: in function 'init'
	init_by_lua:3: in main chunk
```

This error means Kong could not find the source code of the `xxx` plugin, where `xxx` is the actual plugin name. The plugin code is usually located in the `/usr/local/share/lua/5.1/kong/plugins/<plugin-name>` directory. Check whether the `xxx` plugin's code is present in the `/usr/local/share/lua/5.1/kong/plugins/xxx` directory.

## Solution

There are three common causes and fixes:

1. You are using the wrong Kong image. Some plugins are only supported by Enterprise Kong images and can't be used with OSS Kong images. Use an Enterprise Kong image in this case.
2. The `/usr/local/share/lua/5.1/kong/plugins/xxx` directory has been deleted. Add the `/usr/local/share/lua/5.1/kong/plugins/xxx` directory back and restart Kong.
3. You mounted the `/usr/local/share/lua/5.1/kong/plugins/xxx` directory to an external volume. Stop mounting the directory and restart Kong.
