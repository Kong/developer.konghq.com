---
title: How to add a Kong Hostname header for identifying which Kong instance processed a request
content_type: support
published: false
description: "Use a `pre-function` plugin to add a `kong-hostname` header globally by using `config.access=kong.service.request.set_header(\"kong-hostname\",kong.node.get_hostname())`."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I add a Kong Hostname header to identify which Kong instance processed a request?
  a: |
    Add a `pre-function` plugin globally with `config.access = kong.service.request.set_header("kong-hostname", kong.node.get_hostname())` so every response carries a `Kong-Hostname` header naming the node that handled it. This makes troubleshooting easier when your environment has multiple Kong instances.
related_resources: []
---

## Overview

How to add a Kong Hostname Header for identifying the request processed by which Kong instance?

## Steps

Use a `pre-function` plugin to add a `kong-hostname` header globally by using `config.access=kong.service.request.set_header("kong-hostname",kong.node.get_hostname())`. It will make the troubleshooting easier if your environment has multiple Kong instances.

Example:

```bash
curl -X POST -H 'kong-admin-token: <your admin token>' http://<kong_adminapi_hostname>:<port>/plugins \
--data 'name=pre-function' \
--data 'config.access=kong.service.request.set_header("kong-hostname",kong.node.get_hostname())'
```

Result:

Assuming we proxy requests to https://httpbin.org/anything by using the `/anything` path via Kong. We can get the below response when accessing the `/anything` path. Then the `Kong-Hostname` header shows the request processed by which Kong instance.

```bash
curl http://<kong_proxy_hostname>:<port>/anything

{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.org", 
    "Kong-Hostname": "kong-kong-7cff685f58-gllp5", 
    "User-Agent": "curl/8.7.1", 
    "X-Forwarded-Host": "localhost", 
    "X-Forwarded-Path": "/anything", 
    "X-Forwarded-Prefix": "/anything",
    "X-Kong-Request-Id": "818e8b17cef350714734ec2c834c7e73"
  }, 
  "json": null, 
  "method": "GET", 
  "origin": "192.168.65.3, 14.199.113.75", 
  "url": "https://localhost/anything"
}
```
