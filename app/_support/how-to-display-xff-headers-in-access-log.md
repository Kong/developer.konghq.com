---
title: How to display XFF headers in Proxy Access Logs
content_type: support
published: false
description: "Steps to configure Kong to log X-Forwarded-For and other `x_forwarded_*` header values in proxy access logs using a custom NGINX log format."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: available NGINX variables
    url: http://nginx.org/en/docs/varindex.html
tldr:
  q: How do I display X-Forwarded-For (XFF) headers in Kong's proxy access logs?
  a: |
    Set `KONG_PROXY_ACCESS_LOG` and `KONG_NGINX_HTTP_LOG_FORMAT` to a custom NGINX log format that includes the `x_forwarded_for`, `x_forwarded_proto`, `x_forwarded_host`, `x_forwarded_port`, `x_forwarded_path`, and `x_forwarded_prefix` variables.
---

## Overview

How to display XFF headers in Proxy Access Logs

## Steps

Assuming you are running Kong by using a container,

below environment parameters need to be added to show `x_forwarded_*` headers.

```bash
KONG_PROXY_ACCESS_LOG=/dev/stdout show_everything
KONG_NGINX_HTTP_LOG_FORMAT=show_everything '<other NGINX variables>, x_forwarded_for:$upstream_x_forwarded_for, x_forwarded_proto:$upstream_x_forwarded_proto, x_forwarded_host:$upstream_x_forwarded_host, x_forwarded_port:$upstream_x_forwarded_port, x_forwarded_path:$upstream_x_forwarded_path, x_forwarded_prefix:$upstream_x_forwarded_prefix'
```

Please find available NGINX variables.
