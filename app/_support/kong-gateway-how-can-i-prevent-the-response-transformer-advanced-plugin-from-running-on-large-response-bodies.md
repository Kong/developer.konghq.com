---
title: "Kong Gateway: Preventing the Response Transformer Advanced plugin from running on large response bodies"
content_type: support
description: "Kong Gateway supports feature flags to cap the response body size the Response Transformer Advanced plugin will process, avoiding memory pressure on large payloads."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Kong Gateway: How can I prevent the Response Transformer Advanced plugin from running on large response bodies?"
  a: |
    Kong Gateway supports feature flags to cap the size of the response body the plugin will process. Set `response_transformation_enable_limit_body=on` and `response_transformation_limit_body_size=<bytes>` in a feature-flags conf file, point `feature_conf_path` at it in `kong.conf` (or via environment variables), and restart Kong. Requests whose response body exceeds the limit are returned unmodified, and Kong logs a "response body size limit exceeded" message.
related_resources: []
---

## Problem

The documentation for the Response Transformer Advanced plugin notes potential performance issues when large bodies are received. Specifically,

```
Note on transforming bodies: Be aware of the performance of transformations on the response body. In order to parse and modify a JSON body, the plugin needs to retain it in memory, which might cause pressure on the worker's Lua VM when dealing with large bodies (several MBs). Because of Nginx's internals, the Content-Length header will not be set when transforming a response body.
```

We want to prevent the plugin from executing when the response body meets a certain threshold.

## Solution

Kong Gateway supports feature flags that allow for configuring this. To enable this you will need to follow the below:

1. Create a conf file containing these settings (i.e.: `/home/gruber/resp.conf`)

   ```ini
   response_transformation_enable_limit_body=on
   response_transformation_limit_body_size=16384
   ```

   Where the `limit_body_size` is the max response body size you would like to operate on

2. Update your `kong.conf` (or environment variables depending on deployment type)

   ```ini
   feature_conf_path=/home/gruber/resp.conf
   ```

3. If Kong is already running this will require a restart

Once this is in place you can attempt to use the plugin when proxying a request that results in a large payload.

For example, let's set the limit very low for testing purposes:

```ini
response_transformation_limit_body_size=1
```

When we try to proxy a request exceeding this, the original body will be returned along with this error message in the log:

```
2026/08/27 07:09:59 [error] 2914#0: *3224 [lua] limit_body.lua:67: header_filter(): [response-transformer-advanced] { "message": "response body size limit exceeded", "allowed" : 1, "current" : 387 }
```
