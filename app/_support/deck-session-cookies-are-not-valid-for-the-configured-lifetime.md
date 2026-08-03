---
title: Deck session cookies are not valid for the configured lifetime
content_type: support
description: The session cookie used by `deck ping` expires before the configured `cookie_lifetime`; increasing `cookie_discard` keeps the original cookie valid for its full lifetime.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the session cookie expire before the configured `cookie_lifetime`?
  a: |
    Each `deck ping` call generates a new session cookie on the Kong server, so two valid cookies briefly exist. The original cookie is discarded after `cookie_discard` (default 10 seconds), which is shorter than `cookie_lifetime`, and `deck` has no way to retrieve the updated cookie. Increase `cookie_discard` in `admin_gui_session_conf` to match `cookie_lifetime` so the original cookie stays valid for its full lifetime.
related_resources: []
---

## Problem

The `admin_gui_session_conf` has been set to have a `cookie_lifetime` of 600 seconds:

```bash
admin_gui_session_conf={ "cookie_name": "manager-session", "secret": "this_is_my_other_secret", "storage": "kong", "cookie_secure":true, "cookie_lifetime":600}"
```

An authentication cookie is retrieved:

```bash
curl -k https://api.kong.lan/auth -u "kong_admin:password" -H "kong-admin-user:kong_admin" -c /tmp/cookie
```

and `deck ping` initially works fine using the cookie:

```bash
deck ping --kong-cookie-jar-path /tmp/cookie --tls-skip-verify -w default --kong-addr https://api.kong.lan --headers kong-admin-user:kong_admin --headers "user-agent:curl/7.82.0"
Successfully connected to Kong!
Kong version:  3.14.0.0-enterprise-edition
```

After waiting approximately 10 seconds, the same `deck ping` command fails:

```bash
deck ping --kong-cookie-jar-path /tmp/cookie --tls-skip-verify -w default --kong-addr https://api.kong.lan --headers kong-admin-user:kong_admin --headers "user-agent:curl/7.82.0"
Error: reading Kong version: HTTP status 401 (message: "Unauthorized")
```

The session cookie expires before the configured `cookie_lifetime` of 600 seconds elapses.

## Cause

When the `deck ping` command is run, a new session cookie is generated on the Kong server. This means that there are now two valid cookies. The original, older cookie is discarded after the `cookie_discard` time, which defaults to 10 seconds.

## Solution

Currently, there is no way for `deck` to retrieve the updated session cookie and it will be necessary to increase the `cookie_discard` time to allow the original cookie to be used for the full lifetime. For example, change the `admin_gui_session_conf` as per the example below by adding the `cookie_discard` parameter:

```bash
admin_gui_session_conf={ "cookie_name": "manager-session", "secret": "this_is_my_other_secret", "storage": "kong", "cookie_secure":true, "cookie_lifetime":600, "cookie_discard":600}"
```
