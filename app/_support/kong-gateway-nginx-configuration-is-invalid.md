---
title: "\"nginx configuration is invalid\" error when starting Kong with a custom template built for a different Kong version"
content_type: support
description: "The `nginx configuration is invalid` error occurs when starting Kong with a custom Nginx template built from a `nginx_kong.lua` of a different Kong version — keep custom templates in sync with the Kong version you're running."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Custom Nginx templates reference"
    url: "/gateway/nginx-directives/#custom-nginx-templates"
tldr:
  q: Why do I see an "nginx configuration is invalid" error when starting Kong with a custom template?
  a: |
    This happens when a custom Nginx template (or its underlying `nginx_kong.lua`) was built for a different Kong version than the one you're running. Keep custom templates in sync with your Kong version when upgrading or downgrading to avoid this error.
---

## Problem

When attempting to start Kong using a custom template the below error is observed and Kong fails to start.

```
Error: nginx configuration is invalid (exit code 1):
nginx: [emerg] "return" directive is not allowed here in /usr/local/kong/nginx.conf:18
nginx: configuration file /usr/local/kong/nginx.conf test failed
```

These errors can take similar forms, but may include slightly different wording such as:

```
Error: nginx configuration is invalid (exit code 1):
nginx: [emerg] unknown directive "--" in /usr/local/kong/nginx.conf:26
nginx: configuration file /usr/local/kong/nginx.conf test failed
```

## Cause

This issue can be caused by starting Kong with a custom template that is based on a different version of Kong than the one you are running. For example, you are running Kong Gateway 3.14.0.0 and using the `nginx_kong.lua` from a 3.4 install to build your custom template.

## Solution

As there can be changes between releases, it is important when moving between versions that you ensure your custom templates are up to date. For notes on creating a custom template, see the custom Nginx templates reference.
