---
title: "Kong Gateway: How to log plugin configs from inside another plugin using the plugin iterator"
content_type: support
published: false
description: It is possible to configure the `pre-function` plugin to grab the plugin configurations using the plugin iterator.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I log another plugin's configuration from inside a plugin using the plugin iterator?
  a: |
    From the `pre-function` plugin's access phase, get the plugin iterator with `require "kong.runloop.handler"` and read the target plugin's config from `plugins_iterator.globals["<plugin-name>"]`, then log it with `kong.log.inspect`.
---

## Logging another plugin's configuration using the plugin iterator

We are looking to utilize the plugin iterator to grab the plugin configurations from another running plugin. Is it possible to do this from another plugin such as the `pre-function` plugin?

It is possible to configure the `pre-function` plugin to grab the plugin configurations using the plugin iterator.

To do this, configure the plugin you'd like the configuration from. I.e. the `key-auth` plugin.

Next, configure the `pre-function` plugin:

`config.access`:

```lua
local runloop_handler = require "kong.runloop.handler"
local plugins_iterator = runloop_handler.get_plugins_iterator()
local global_conf = plugins_iterator.globals["key-auth"]
kong.log.inspect(global_conf)
```

In the logs we can see the plugin config like this:
