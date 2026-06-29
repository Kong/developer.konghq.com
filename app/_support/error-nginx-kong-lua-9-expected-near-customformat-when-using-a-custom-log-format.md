---
title: "Error: `nginx_kong.lua:9: '=' expected near 'customformat'` when using a custom `log_format`"
content_type: support
description: This can occur when attempting to use `log_format` outside the http context.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why do I get `nginx_kong.lua:9: '=' expected near 'customformat'` when using a custom `log_format`?"
  a: |
    This occurs when `log_format` is placed outside the `http` context in a custom nginx template —
    `log_format` can only be used within the `http` context. When using a custom template, properly
    add the contents of `nginx_kong.lua` inside `http {}`, with the `log_format` directive defined
    there.
---

## Problem

When attempting to use a custom `log_format` in an nginx template, for example when using the Correlation ID plugin to log IDs, the following error appears on startup or reload:

```

ERROR: /usr/local/share/lua/5.1/luarocks/loader.lua:104: error loading module 'kong.templates.nginx_kong' from file '/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua':
        /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua:9: '=' expected near 'customformat'
stack traceback:
        /usr/local/share/lua/5.1/luarocks/loader.lua:104: in function </usr/local/share/lua/5.1/luarocks/loader.lua:101>
        [C]: in function 'require'
        /usr/local/share/lua/5.1/kong/cmd/utils/prefix_handler.lua:9: in main chunk
        [C]: in function 'require'
        /usr/local/share/lua/5.1/kong/cmd/reload.lua:8: in main chunk
        [C]: in function 'require'
        /usr/local/share/lua/5.1/kong/cmd/init.lua:71: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:61>
        /usr/local/bin/kong:9: in function 'file_gen'
        init_worker_by_lua:46: in function <init_worker_by_lua:44>
        [C]: in function 'xpcall'
        init_worker_by_lua:53: in function <init_worker_by_lua:51>
```

Where `customformat` is the name you've given to the `log_format`.

## Cause

This can occur when attempting to use `log_format` outside the `http` context. The `log_format` directive can only be used within the `http` context.

## Solution

When using a custom template be sure to follow the instructions as documented, properly adding the contents of the `nginx_kong.lua` within `http {}`, for example:

```bash

worker_processes ${{NGINX_WORKER_PROCESSES}};
daemon ${{NGINX_DAEMON}};       
pid pids/nginx.pid; 

events {
    use epoll;          # a custom setting
    multi_accept on;
}

http {

log_format customformat '$remote_addr - $remote_user [$time_local] '
              '"$request" $status $body_bytes_sent  '
              '"$http_referer" "$http_user_agent" '
              'Kong-Request-ID="$sent_http_Kong_Request_ID"';

  # contents of the nginx_kong.lua template follow:

 access_log ${{PROXY_ACCESS_LOG}} customformat;

  ... # etc
}
```
