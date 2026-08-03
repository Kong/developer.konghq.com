---
title: 413 "Request Entity Too Large" error when proxying a payload or uploading a DB-less config
content_type: support
description: The Gateway returns a 413 error when a proxied request or a DB-less config upload to `/config` exceeds the configured client body size limit.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the Gateway return a "413 Request Entity Too Large" error?
  a: |
    The Gateway returns this error when a proxied request body exceeds the configured `nginx_proxy_client_max_body_size` limit, or when a DB-less config upload to `/config` exceeds `nginx_admin_client_max_body_size`. Increase the relevant setting through Kong configuration (`kong.conf`, Helm values, or environment variables) or a custom Nginx template.
related_resources: []
---

## Problem

The Gateway returns the following error:

```
HTTP/1.1 413 Request Entity Too Large
Date: Mon, 24 Oct 2026 14:15:33 GMT
Content-Type: text/html; charset=UTF-8
Content-Length: 148
Connection: close

<html>
<head><title>413 Request Entity Too Large</title></head>
<body>
<center><h1>413 Request Entity Too Large</h1></center>
</body>
</html>
```

## Cause

This error can occur for a few reasons:

1. You are attempting to proxy a payload through the Gateway that is larger than it is configured to allow.

2. You are attempting to upload a config file in DB-less mode to the `/config` endpoint that exceeds the configured size.

## Solution

To address this you can adjust the payload size by setting the appropriate parameter:

In the case of proxying: `nginx_proxy_client_max_body_size`

In the case of DB-less config: `nginx_admin_client_max_body_size`

This can be changed either through injecting Nginx directives in your Kong configuration (`kong.conf`/values/environment variables) or using a custom Nginx template.

References:

Client Max Body Size : Nginx documentation on client max body size parameter

Directive Injection : Nginx Directive Injection in Kong Gateway

Custom Nginx template : Custom Nginx templates in Kong Gateway
