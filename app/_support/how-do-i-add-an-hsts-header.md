---
title: Adding an HSTS (HTTP Strict Transport Security) header to Kong Manager
content_type: support
description: How to add an HSTS response header to Kong Manager by adding an `add_header` directive to the `server` block of a custom Nginx template.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I add an HSTS (HTTP Strict Transport Security) header to the Kong GUI?
  a: |
    Add `add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;` to the `server` block of Kong Manager's custom Nginx template — not the outer `http` block, and repeated in any `location` block that sets its own `add_header` directives, since Nginx's `add_header` doesn't inherit into those.
related_resources: []
---

## Overview

Our security team is requiring that our Kong GUI provide an HSTS header. How can I accomplish this?

## Steps

For detailed guidance, refer to the NGINX blog on HTTP Strict Transport Security (HSTS) and NGINX. Please read the entire article, as it includes important testing recommendations and potential issues.

To enable HSTS in Kong Manager, add the following directive inside the Admin GUI (Kong Manager) `server` block of your custom NGINX template — not the outer `http` block, and not nested inside a `location` block (nginx's `add_header` does not inherit into a `location` block that sets its own `add_header` directives, so it must be repeated per-location if you also need it there):

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

More information on custom templating with Kong is available here: Custom NGINX Templates and Embedding Kong
