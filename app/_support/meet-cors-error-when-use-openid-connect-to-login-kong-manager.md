---
title: Meet CORS error when using openid-connect to login Kong Manager
content_type: support
description: "A CORS error appears when logging in to Kong Manager through OpenID Connect because `login_action: redirect` in `KONG_ADMIN_GUI_AUTH_CONF` (or `admin_gui_auth_conf`) makes Kong Manager redirect to itself via the Admin API."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "more detail on the `login_action` config"
    url: "/plugins/openid-connect/reference/#schema--config-login_action"
tldr:
  q: Why do I get a CORS error when logging in to Kong Manager with OpenID Connect?
  a: |
    Kong Manager redirects to itself through the Admin API after the IdP login when `login_action: redirect` is set in `KONG_ADMIN_GUI_AUTH_CONF` (or `admin_gui_auth_conf`), which triggers the CORS error. Remove `login_action: redirect` from that config to fix it.
---

## Problem

My Kong Admin API is running at `http://kong:8001` and Kong Manager is running at `http://kong:8002`

I am using openid-connect to login Kong Manager, but I am not able to login and see below error from browser

```
Access to XMLHttpRequest at 'http://kong:8002/#id_token=xxx' (redirected from 'http://kong:8001/auth?state=yyy&session_state=zzz&code=qqq') from origin 'http://kong:8002' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Cause

This issue will happen when you have set `login_action: redirect` in `KONG_ADMIN_GUI_AUTH_CONF` (or `admin_gui_auth_conf`). After a successful login at the IDP, Kong Manager tries to redirect to itself via the Admin API.

## Solution

To solve this error, please delete `login_action: redirect` from `KONG_ADMIN_GUI_AUTH_CONF` (or `admin_gui_auth_conf`).
