---
title: "Kong Gateway: Enabling HSTS headers for Portal"
content_type: support
description: "Enabling HSTS headers for the Dev Portal GUI requires a custom Nginx template, since `NGINX_PROXY_ADD_HEADER` doesn't affect the Portal."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I enable HSTS headers for the Kong Dev Portal GUI?
  a: |
    `NGINX_PROXY_ADD_HEADER` does not apply to the Portal GUI. Instead, add a custom Nginx template with an `add_header Strict-Transport-Security ...;` directive inside the Portal's `location /` block. Note that the Dev Portal is deprecated on Kong Gateway (Enterprise), and on a standard Enterprise license the Portal GUI listener returns a 404 regardless of this header configuration.
related_resources:
  - text: Custom Nginx templates
    url: /gateway/nginx-directives/#custom-nginx-templates
---

## Problem

We would like to enable HSTS (HTTP Strict Transport Security) headers for our Portal GUI. I see headers can be injected using `NGINX_PROXY_ADD_HEADER` however this does not seem to affect the Portal. How can this be achieved?

## Solution

To accomplish this a custom nginx template will be needed. Specifically, this (and other headers) will need to be added to the Portal location block as seen below.

The location block has been shortened for readability.

```nginx
    location / {
        root portal;
        default_type text/html;
        ...
        add_header Strict-Transport-Security 'max-age=320000; includeSubDomains;';
    }
```

The results can be seen when accessing your portal, in the example below the GUI is running on port 48003.

> **Note:** The Dev Portal is deprecated on Kong Gateway (Enterprise). On a standard Enterprise license the Portal GUI listener returns `404 {"message":"Not Found"}` even with `KONG_PORTAL=on` explicitly set, because Portal is now gated behind a separate license entitlement that ordinary Enterprise licenses do not carry. The `location /` block above is still the correct place to add the header for anyone whose license does unlock the Portal, but on a standard license there is no served Portal GUI to add the header to.
