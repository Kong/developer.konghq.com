---
title: Removing all query parameters, including the API key, from Kong access logs
content_type: support
description: How to strip all query parameters, including a plaintext API key, from Kong access logs using a custom Nginx log format in the Nginx template.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can you remove all query parameters from access logs (including `APIKey`)?
  a: |
    Use a custom Nginx template to define a log format without the query string (for example based on `combined` but using `$uri` instead of `$request`), and reference that format in the `access_log` directive. This removes all query parameters, including a plaintext API key, from Kong's access logs.
related_resources:
  - text: Custom Nginx templates (embedding Kong) documentation
    url: /gateway/configuration/#custom-nginx-templates--embedding-kong
---

## Overview

When using the API key plugin for any service the access logs are displaying the API Key on the request in plain text. Is it possible to remove this for security purposes? Example:

## Steps

It is possible to remove all query parameters including the `APIKey` from the access logs by using a custom Nginx template, as described in the linked documentation.

After you have set up a working custom Nginx template you can add the following sections to your file:

Under the `http` block:

```nginx

log_format combined_no_query '$remote_addr - $remote_user [$time_local] '
   '"$request_method $uri" $status $body_bytes_sent '
   '"$http_referer" "$http_user_agent"';
```

Under the `server` block:

```nginx

access_log ${{PROXY_ACCESS_LOG}} combined_no_query;
```

Afterwards, restart Kong using the custom template. Afterwards you can run the `APIKey` plugin and add the `APIKey` to the query params and it will be deleted from the access logs.
