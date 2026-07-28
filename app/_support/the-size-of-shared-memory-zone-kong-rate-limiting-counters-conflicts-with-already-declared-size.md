---
title: "The size of shared memory zone \"kong_rate_limiting_counters\" conflicts with already declared size errors on startup"
content_type: support
description: Dictionaries whose values are set in `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` are not configurable via the configuration file.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: a custom nginx template
    url: /gateway/configuration/#custom-nginx-templates--embedding-kong
tldr:
  q: Why does Kong fail to start with a "conflicts with already declared size" shared memory zone error?
  a: |
    Shared dictionary sizes defined in `nginx_kong.lua` (such as `kong_rate_limiting_counters`) can't be overridden through `kong.conf` directives like `nginx_http_lua_shared_dict` — doing so conflicts with the size already declared in the generated `nginx-kong.conf`. Use a custom Nginx template instead to change these values.
---

## Problem

When attempting to update the value of a shared dictionary using direct nginx injection, Kong fails to start with an error similar to the below:

```

nginx: [emerg] the size 25165824 of shared memory zone "kong_rate_limiting_counters" conflicts with already declared size 12582912 in /usr/local/kong/nginx-kong.conf:45
```

Note: The size, dictionary name and line number references may vary depending on which value you are updating.

For example, adding the below to your kong configuration will produce this error:

```conf

nginx_http_lua_shared_dict = kong_rate_limiting_counters 128m
```

## Solution

Dictionaries whose values are set in `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` are not configurable via the configuration file. However, these can be configured by using a custom nginx template.
