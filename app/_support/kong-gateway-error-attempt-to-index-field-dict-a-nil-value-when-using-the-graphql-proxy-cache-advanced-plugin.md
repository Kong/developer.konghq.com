---
title: "Kong Gateway: `[error] attempt to index field 'dict' (a nil value)` when using the GraphQL Proxy Cache Advanced plugin"
content_type: support
description: This occurs when providing a custom name for the plugin's shared dictionary (`config.memory.dictionary_name`) without defining it in a custom Nginx template.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: custom nginx templates
    url: /gateway/reference/nginx-directives/#custom-nginx-templates
tldr:
  q: Why do I get `attempt to index field 'dict' (a nil value)` when using the GraphQL Proxy Cache Advanced plugin?
  a: |
    The plugin was configured with a custom `config.memory.dictionary_name`, but that shared dictionary was never defined in a custom Nginx template, so it does not exist at runtime.
    Define the dictionary with `lua_shared_dict <name> <size>;` in a custom Nginx template so it is available to the plugin.
---

## Problem

The below error has been observed in the proxy error log and the Graphql Proxy Cache Advanced plugin is not executing. What is the cause of this error?

```
2025/05/31 17:22:17 [error] 114443#0: *2302 [kong] init.lua:386 [graphql-proxy-cache-advanced] ./graphql-proxy-cache-advanced/strategies/memory.lua:71: attempt to index field 'dict' (a nil value)
```
## Cause

This will occur when providing a custom name for the plugin's shared dictionary (`config.memory.dictionary_name`).

If the name has not been properly defined in a custom nginx template it will not be available to the plugin.

## Solution

For example,

We have configured the plugin with this setting

```bash
setting config.memory.dictionary_name=gruber
```
If we review the Admin API status endpoint we can confirm this dictionary does not yet exist.

```bash
curl https://adminapi/status -H "kong-admin-token: token" -s | jq .memory.lua_shared_dicts.gruber
null
```
To correct this you will need to define it in a custom template as

```nginx
lua_shared_dict gruber                         5m;
```
