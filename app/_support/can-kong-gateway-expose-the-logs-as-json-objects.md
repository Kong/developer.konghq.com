---
title: Configuring Kong Gateway to output logs as JSON objects
content_type: support
description: "Kong doesn't have a built-in JSON `error_log` format, but JSON access logs can be produced using Kong logging plugins (`tcp-log`, `http-log`) or a custom Nginx `log_format`."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Can Kong Gateway expose the logs as JSON objects?
  a: |
    Kong doesn't have a setting to change the Nginx `error_log` format, but you can get JSON access logs using the `tcp-log` or `http-log` plugins, or by defining a custom Nginx `log_format` (e.g. `json_logs`) in a custom Nginx template and setting `proxy_access_log` to use it.
related_resources:
  - text: Nginx logging documentation
    url: https://docs.nginx.com/nginx/admin-guide/monitoring/logging/
  - text: Kong Logging plugins (tcp-log, http-log)
    url: /plugins/?category=logging
  - text: Customize what Kong Gateway logs
    url: /gateway/logs/#customize-what-kong-gateway-logs
---

## Problem

Kong Gateway does not provide a built-in option to output its logs as JSON objects.

## Solution

Kong logs are based on the Nginx logging functionality.

There is no option to change the Nginx `error_log` format.

For `access_log`, there are options to use Kong Logging plugins to send JSON events using the `tcp-log` or `http-log` plugins.

Or using a custom Nginx template (`/usr/local/share/lua/5.1/kong/templates/nginx.lua`).

And using `log_format json_logs` similar to:

```nginx
log_format json_logs escape=json
'{'
'"time_local":"$time_local",'
'"remote_addr":"$remote_addr",'
'"remote_user":"$remote_user",'
'"request":"$request",'
'"status": "$status",'
'"body_bytes_sent":"$body_bytes_sent",'
'"request_time":"$request_time",'
'"http_referrer":"$http_referer",'
'"http_user_agent":"$http_user_agent"'
'}';
```

And then configure:

```nginx
proxy_access_log=logs/access.log json_logs
```
