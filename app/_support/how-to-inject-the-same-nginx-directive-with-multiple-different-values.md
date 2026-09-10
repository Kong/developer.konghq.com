---
title: How to inject the same nginx directive with multiple different values
content_type: support
description: Kong doesn't support specifying the same NGINX directive multiple times with different values, but you can work around this by defining multiple complete directive values in a single config property.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I set the same NGINX directive multiple times with different values in Kong?
  a: |
    Kong doesn't support repeating the same NGINX directive with different values directly. Work around this by defining multiple complete directive values within a single `nginx_proxy_*` config property (or `KONG_NGINX_PROXY_*` environment variable), separated by semicolons, with the last value not ending in a semicolon.
---

## Overview

I need to use the Nginx directive injection feature documented here but I have multiple values for the same directive, and specifying the directive multiple times or adding multiple values to the same directive doesn't work. How can I overcome this issue?

## Steps

Currently, it is not possible to specify the same directive multiple times with different values but it is possible to work around the issue by adding the multiple complete directive definitions for one variable injection.

For example if you want to add multiple `add_header` nginx directives with different values, you could achieve this by specifying them in the relevant kong property or KONG variable like this, i.e the first value is specified normally, and all other values are added to that value by specifying the whole directive. Please note that the directives need to be separated by a semicolon but that the last directive must NOT end in a semicolon:

```
nginx_proxy_add_header = Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0'; add_header X-Frame-Options 'sameorigin'; add_header X-XSS-Protection '1; mode=block'; add_header X-Content-Type-Options 'nosniff'; add_header X-Permitted-Cross-Domain-Policies 'master-only'; add_header Strict-Transport-Security 'max-age=31536000' always
```

```
KONG_NGINX_PROXY_ADD_HEADER: Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0'; add_header X-Frame-Options 'sameorigin'; add_header X-XSS-Protection '1; mode=block'; add_header X-Content-Type-Options 'nosniff'; add_header X-Permitted-Cross-Domain-Policies 'master-only'; add_header Strict-Transport-Security 'max-age=31536000' always
```
