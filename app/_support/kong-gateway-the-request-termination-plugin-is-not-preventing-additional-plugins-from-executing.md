---
title: "Kong Gateway: The Request Termination plugin is not preventing additional plugins from executing"
content_type: support
description: This occurs as a result of the `kong.response.exit` function which is used by the request termination plugin in the access phase.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do other plugins still run after the Request Termination plugin executes?
  a: |
    The Request Termination plugin calls `kong.response.exit()`, which stops execution of other plugins only in the current phase. Later phases, such as `header_filter`, `body_filter`, and `log`, still run along with their plugins, so custom plugins should be written defensively for requests that Kong terminates itself instead of proxying to the Service.
related_resources: []
---

## Problem

We have noticed that when using the request termination plugin, other plugins are still being executed. The expectation is that this plugin terminates the request entirely. Why do I still see other plugins being run?

## Solution

This occurs as a result of the `kong.response.exit` function which is used by the request termination plugin in the access phase.

As noted in the documentation this function does not prevent additional plugins from being executed, only execution of any other plugin code in the phase this is called from.

```

Calling kong.response.exit() interrupts the execution flow of plugins in the current phase. Subsequent phases will still be invoked. 

For example, if a plugin calls kong.response.exit() in the access phase, no other plugin is executed in that phase, but the header_filter, body_filter, and log phases are still executed, along with their plugins. Plugins should be programmed defensively against cases when a request is not proxied to the Service, but instead is produced by Kong itself.
```
