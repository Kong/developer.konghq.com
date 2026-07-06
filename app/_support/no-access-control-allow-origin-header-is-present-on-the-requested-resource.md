---
title: "Missing Access-Control-Allow-Origin header with CORS plugin"
content_type: support
description: "The CORS plugin omits the Access-Control-Allow-Origin header when config.origins contains an invalid character or when the request origin does not match a configured origin."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why is no Access-Control-Allow-Origin header present on the response even though I configured the CORS plugin?
  a: |
    Check `config.origins` for invalid characters (leading or trailing spaces, quotes, or brackets) and confirm the request's Origin matches one of the configured values.
related_resources: []
---

## Problem

The CORS plugin is configured, but proxy requests are being denied.
The browser developer console shows an error like:

```
Access to XMLHttpRequest at 'https://proxy/echo' from origin 'https://konghq.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

A value has been added to `config.origins` in the CORS plugin, but the `Access-Control-Allow-Origin` header is missing from the response.

## Cause

This can happen for two reasons:

1. `config.origins` contains an invalid character. Common examples are a leading or trailing space, quotes, or brackets.
The field accepts a simple comma-separated list and doesn't require brackets, even though the field type is a string array.
1. Multiple origins are configured, but the request's `Origin` header doesn't match any of them.
The plugin only adds the `Access-Control-Allow-Origin` header when the request origin matches a configured value.
For example, if `config.origins` is set to `https://konghq.com,https://kuma.io`, a request from `https://mockbin.org` returns this error, but a request from `https://kuma.io` succeeds.

## Solution

Review `config.origins` and remove any invalid characters like leading or trailing spaces, quotes, or brackets.
Use a plain comma-separated list of origins.
When multiple origins are configured, confirm that the request's `Origin` header matches one of the configured values.
