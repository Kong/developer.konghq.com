---
title: "Error: attempt to concatenate field 'authority' (a nil value) after upgrading to 3.X"
content_type: support
description: Resolve the "attempt to concatenate field 'authority' (a nil value)" error after upgrading to Kong Gateway 3.X by setting a valid KONG_ADMIN_GUI_URL value.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why do I get \"attempt to concatenate field 'authority' (a nil value)\" after upgrading to Kong Gateway 3.X?"
  a: |
    The `KONG_ADMIN_GUI_URL` parameter holds a value that was valid in 2.X but breaks in 3.X —
    either an asterisk (`KONG_ADMIN_GUI_URL="*"`) or a value missing the protocol
    (`KONG_ADMIN_GUI_URL=127.0.0.1:8002`). Set it to a valid value using the format
    `<scheme>://<IP / HOSTNAME>(:<PORT>)`, for example `KONG_ADMIN_GUI_URL=http://127.0.0.1:8002`.
related_resources:
  - text: Kong Gateway admin_gui_url configuration
    url: /gateway/configuration/#admin-gui-url
---

## Problem

After upgrading to Kong Gateway 3.x, I am getting the following error on start up:

```
Error: attempt to concatenate field 'authority' (a nil value)
```

## Cause

The `KONG_ADMIN_GUI_URL` parameter holds a value that was valid in 2.X but breaks in 3.X — either an asterisk (`KONG_ADMIN_GUI_URL="*"`) or a value missing the protocol (`KONG_ADMIN_GUI_URL=127.0.0.1:8002`).

## Solution

1. Check whether you have an asterisk in your `KONG_ADMIN_GUI_URL` parameter:

   ```bash
   KONG_ADMIN_GUI_URL="*"
   ```

   This value needs to be set with the following format:

   ```
   <scheme>://<IP / HOSTNAME>(:<PORT>)
   ```

   Items within the parenthesis are optional.

2. Check whether you have not written the protocol in your `KONG_ADMIN_GUI_URL` parameter as below:

   ```bash
   KONG_ADMIN_GUI_URL=127.0.0.1:8002
   ```

   Fix it by adding the protocol as below:

   ```bash
   KONG_ADMIN_GUI_URL=http://127.0.0.1:8002
   ```
