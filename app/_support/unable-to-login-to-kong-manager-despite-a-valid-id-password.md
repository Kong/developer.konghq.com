---
title: Unable to login to Kong Manager despite a valid id/password
content_type: support
description: This issue occurs when the URL that is used to access Kong does not match the URL defined in the Kong configuration (`kong.conf`).
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: how CORS works
    url: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
tldr:
  q: Why does login to Kong Manager fail with "Username/Password is invalid" and a CORS error even though the credentials are correct?
  a: |
    The URL used to access Kong Manager doesn't match the `admin_gui_url` value set in `kong.conf`, which triggers a CORS error during login. Make sure `admin_gui_url` matches the actual access URL exactly, including case — it must be all lowercase.
---

## Problem

When attempting to login to Kong Manager you may receive an error "Username/Password is invalid" despite using a valid name and password. A look at the browser development tools will reveal a CORS error.

## Solution

This issue occurs when the URL that is used to access Kong does not match the URL defined in the Kong configuration (`kong.conf`). Specifically, the value of `admin_gui_url`.

For this example, Kong Manager is being accessed at the URL http://localhost:8002/, but the `kong.conf` is set with a value as below;

```conf

admin_gui_url = https://kong:8445
```

Note, this value is case sensitive, so the value of `admin_gui_url` must be all lowercase.

For more information on how CORS works.
