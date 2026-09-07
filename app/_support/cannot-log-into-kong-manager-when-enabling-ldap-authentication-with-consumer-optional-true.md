---
title: "Cannot log into Kong Manager when enabling LDAP authentication with `consumer_optional: true`"
content_type: support
description: "On current Kong Gateway, `admin_gui_auth_conf.consumer_optional` has no effect on Kong Manager's `ldap-auth-advanced` login path — Kong now forces `consumer_optional` internally and handles the Admin-to-Consumer mapping itself."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why can't I log into Kong Manager when LDAP authentication is enabled with `consumer_optional: true`?
  a: |
    On current Kong Gateway, Kong Manager's `/auth` route no longer honors `admin_gui_auth_conf.consumer_optional` for `ldap-auth-advanced` — Kong forces `consumer_optional = true` internally and performs the Admin-to-Consumer mapping itself, based on the Consumer already attached to the matching Kong Admin object. If no Kong Admin exists with the LDAP username, the request fails immediately with `Admin not found` before Kong even queries LDAP, so check `GET /admins` for a matching username rather than the `consumer_optional` setting.
related_resources: []
---

## Problem

We are using `ldap-auth-advanced` as the authentication method for the Kong Manager, have set `consumer_optional: true` in our `admin_gui_auth_conf`, and cannot log into the Kong Manager

## Cause

On Kong Gateway (Enterprise) 3.14.0.0, Kong Manager's `/auth` route no longer relies on the `ldap-auth-advanced` plugin's own consumer-mapping logic: for `admin_gui_auth = "ldap-auth-advanced"`, Kong unconditionally forces `consumer_optional = true` on the invoked plugin's config internally (`kong/api/routes/kong.lua`, in the `/auth` route handler), regardless of what is configured in `admin_gui_auth_conf`. After the plugin runs (i.e. after a successful LDAP bind/search), Kong Manager performs the Admin-to-Consumer mapping itself via `auth_plugin_helpers.map_admin_groups_by_idp_claim()` and `auth_plugin_helpers.set_admin_consumer_to_ctx()`, using the Consumer already attached to the matching Kong Admin object — not a value returned by the plugin. As a result:

- Explicitly setting `"consumer_optional":true` (or `false`) in `admin_gui_auth_conf` has no effect on this Kong Manager login path, and is not the actual cause of a login failure.
- Kong Manager's `/auth` route looks up a matching Kong Admin object by username *before* invoking the `ldap-auth-advanced` plugin at all (via `auth_plugin_helpers.validate_admin_and_attach_ctx()`). If no Kong Admin exists with that username, the request fails immediately with `[auth_plugin_helpers] Admin not found` in the error log, and the LDAP server is never even contacted.
- If the LDAP bind/search debug lines shown below do appear in the log (meaning an Admin object was found and the LDAP plugin ran), but login still fails, check for a generic `401 {"message":"Unauthorized"}` response — Kong Manager's OIDC and LDAP login paths both return this generic response on failure.

## Solution

To troubleshoot a current Kong Manager LDAP login issue, set the log level on the node serving Kong Manager to `debug` and check the error log. A successful bind/search still logs lines similar to:

```
2026/08/27 02:51:57 [debug] 23063#0: *60 [kong] access.lua:57 session not present
2026/08/27 02:51:57 [debug] 23063#0: *60 [kong] access.lua:86 binding with cn=admin,dc=example,dc=org and conf.ldap_password
2026/08/27 02:51:57 [debug] 23063#0: *60 [kong] access.lua:95 ldap bind successful, performing search request with base_dn:ou=People,dc=example,dc=org, scope='sub', and filter=uid=kong_admin
```

If these lines appear but the login still fails, confirm that a Kong Admin object exists (`GET /admins`) with a username matching the value returned by the LDAP search, since that mapping — not the `consumer_optional` setting — is what current Kong Manager LDAP login actually depends on.
