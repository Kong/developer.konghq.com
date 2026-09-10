---
title: How to force a login into the IdP after logging out of Kong Manager
content_type: support
description: "Add `authorization_query_args_names` and `authorization_query_args_values` to your `admin_gui_auth_config` (or `KONG_ADMIN_GUI_AUTH_CONF`) to force a login into your IdP after logging out of Kong Manager."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I force a login into my IdP after an Admin logs out of Kong Manager, instead of Kong Manager silently logging them back in?
  a: |
    Add `"authorization_query_args_names": ["prompt"]` and `"authorization_query_args_values": ["login"]` to your `admin_gui_auth_config` (or the `KONG_ADMIN_GUI_AUTH_CONF` environment variable) for the `openid-connect` admin GUI auth method. These fields aren't overridden by Kong Manager, so they force the `prompt=login` parameter on the IdP redirect, requiring the admin to log in again instead of being silently re-authenticated.
---

## Overview

We have enabled Kong Manager with openid-connect authentication. Currently when Admins log out of the Kong Manager, they can log back into the Manager without having to log into our IdP.We would like to make sure that after logging out of the Kong Manager that Admins will have to explicitly log into our IdP when they want to log into the Kong Manager again.

## Steps

This requirement can be achieved by adding two additional properties to the `admin_gui_auth_config` property or `KONG_ADMIN_GUI_AUTH_CONF` environment variable compared to the documented configuration :

`"authorization_query_args_names": ["prompt"]` and `"authorization_query_args_values": ["login"]`

A complete configuration would be similar to this. Note that for `admin_gui_auth=openid-connect`, the `logout_methods`, `logout_query_arg`, and `auth_methods` fields shown below are silently overridden/ignored by Kong (Kong Manager forces its own values for these so the admin login/logout flow works correctly), so they have no effect — they're harmless to leave in but aren't required for this technique. The `authorization_query_args_*` fields are not overridden and are what actually forces `prompt=login`:

```bash

admin_gui_auth_conf={ \
  "issuer": "<ENTER_YOUR_ISSUER_URL>", \
  "client_id": ["<ENTER_YOUR_CLIENT_ID>"], \
  "client_secret": ["<ENTER_YOUR_CLIENT_SECRET_HERE>"], \
  "consumer_by": ["username","custom_id"], \
  "ssl_verify": false, \
  "consumer_claim": ["email"], \
  "leeway": 60, \
  "redirect_uri": ["http://localhost:8002"], \
  "login_redirect_uri": ["http://localhost:8002"], \
  "logout_methods": ["GET", "DELETE"], \
  "logout_query_arg": "logout", \
  "logout_redirect_uri": ["http://localhost:8002"], \
  "scopes": ["openid","profile","email","offline_access"], \
  "auth_methods": ["authorization_code"], \
  "authorization_query_args_names": ["prompt"],
  "authorization_query_args_values": ["login"]
}
```
