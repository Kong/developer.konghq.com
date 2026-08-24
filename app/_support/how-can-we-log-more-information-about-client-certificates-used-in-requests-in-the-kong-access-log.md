---
title: Logging client certificate information in the Kong access log
content_type: support
published: false
description: Nginx offers several access log variables, such as `$ssl_client_s_dn` and `$ssl_client_raw_cert`, that can log client certificate information in a custom access log format.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can we log more information about client certificates used in requests in the kong access log?
  a: |
    Nginx exposes client-certificate variables such as `$ssl_client_s_dn` (client DN) and `$ssl_client_raw_cert` (raw cert).
    Add them to a custom log format via `KONG_NGINX_HTTP_LOG_FORMAT` and reference that format in `KONG_PROXY_ACCESS_LOG`.
related_resources: []
---

## Overview

How can we log more information about client certificates used in requests in the kong access log? In particular we are interested in getting the CN and possibly the whole client cert for requests.

## Steps

Nginx offers several variables that can be used to log client certificate information in a custom access log format. In particular, there are `$ssl_client_s_dn`, and a `$ssl_client_raw_cert` variable which may be useful to use either or both to log information about the client certificate. You could modify the standard nginx access log format to return any of the variables. One example which would return both the client DN, and the raw client certificate could be achieved with these kong variables:

```bash
KONG_NGINX_HTTP_LOG_FORMAT: show_client_cert '$$time_iso8601 - $bytes_sent - $$request - $$status - $$remote_addr - $$ssl_client_s_dn - $$ssl_client_raw_cert'
KONG_PROXY_ACCESS_LOG: /dev/stdout show_client_cert
```
