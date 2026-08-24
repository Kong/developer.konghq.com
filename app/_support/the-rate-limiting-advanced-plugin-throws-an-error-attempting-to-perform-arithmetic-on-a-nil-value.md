---
title: The Rate Limiting Advanced plugin throws an error attempting to perform arithmetic on a nil value
content_type: support
description: A `nil` value arithmetic crash in the Rate Limiting Advanced plugin under heavy load, caused by evicted counters in an undersized `lua_shared_dict`; fixed as of {{site.base_gateway}} 3.14.0.0, but proper `kong_rate_limiting_counters` sizing is still good practice.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the Rate Limiting Advanced plugin throw an "attempt to perform arithmetic on a nil value" error under heavy load?
  a: |
    Historically, an undersized `lua_shared_dict` (the `kong_rate_limiting_counters` shared dictionary) could evict rate-limiting counters, returning `nil` and crashing the plugin's Lua arithmetic. This is fixed as of Kong Gateway 3.14.0.0 — an undersized dictionary now logs a WARN-level counter reset instead of crashing — but sizing `kong_rate_limiting_counters` appropriately (via a custom nginx template) is still good practice.
---

## Problem

The Rate Limiting Advanced plugin has been added and is working fine. After a period of time, when under a heavy load, errors start to occur that arithmetic is being performed on a nil value. For example;

```

2025/12/05 00:43:42 [error] 2694#0: *156152717 lua coroutine: runtime error: ...l/share/lua/5.1/kong/tools/public/rate-limiting/init.lua:309: attempt to perform arithmetic on local 'cur' (a nil value)
stack traceback:
coroutine 0:
...l/share/lua/5.1/kong/tools/public/rate-limiting/init.lua: in function 'increment'
.../lua/5.1/kong/plugins/rate-limiting-advanced/handler.lua:242: in function <.../lua/5.1/kong/plugins/rate-limiting-advanced/handler.lua:208>
coroutine 1:
[C]: in function 'resume'
coroutine.wrap:21: in function <coroutine.wrap:21>
/usr/local/share/lua/5.1/kong/init.lua:623: in function 'access'
access_by_lua(nginx-kong.conf:85):2: in function <access_by_lua(nginx-kong.conf:85):1>
```

The plugin is using the `config. strategy=cluster` option.

This specific crash no longer reproduces as of {{site.base_gateway}} 3.14.0.0. Historically, the Rate Limiting Advanced plugin used a shared dictionary to store the counters for the rate limits, and if the shared dictionary was too small to hold all the counters, some counters would be evicted, leading to a nil value being returned for the counter and a runtime crash when the plugin tried to perform arithmetic on it.

This has since been fixed: `dict:incr` is now called with an init value and wrapped in an error-catch, so an under-sized shared dictionary now causes a silent, WARN-logged counter reset instead of a Lua runtime crash. The sizing guidance below remains useful as a best practice to avoid unnecessary counter resets, but is no longer required to prevent a crash.

## Solution

The name of the default counter the plugin uses is `kong_rate_limiting_counters`. The size of this counter can be increased by using a custom nginx template. The standard counter is defined as below;

```nginx
lua_shared_dict kong_rate_limiting_counters 12m;
```

The `12m` size is a default value and can be increased as necessary. For a large number of counters, this value can be raised significantly, for example to `128m` (assuming the host has available free memory for the increased size)

```nginx
lua_shared_dict kong_rate_limiting_counters 128m;
```

It is possible to create a new shared dictionary using the direct nginx injection as from Kong EE 0.35

```nginx
nginx_http_lua_shared_dict=my_shared_dict 128m
```

You can then use this shared dictionary by setting the `config.dictionary_name` parameter in the plugin configuration.

From Kong EE 0.36, the `/status` endpoint will show the configured size and allocation of the shared dictionaries. For example;

```bash
# curl -s4 -X GET https://kong:8444/status -H 'Kong-Admin-Token: kong_admin'|jq ".memory.lua_shared_dicts.kong_rate_limiting_counters"
{
"allocated_slabs": "0.08 MiB",
"capacity": "12.00 MiB"
}
```

This will allow you to monitor the use of the shared dictionaries and ensure that they are sized correctly.
