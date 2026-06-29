---
title: "Kong Manager login error: `config.client_secret` length must be at least 1"
content_type: support
description: "Logging into Kong Manager fails with a `config.client_secret` schema violation when the OIDC `client_secret` value is empty."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "When trying to log into Kong Manager, getting the error `config.client_secret: length must be at least 1`"
  a: |
    This error occurs when the value inside `client_secret` is empty, for example if the variable
    was wiped out or contains no data, resulting in a schema violation
    (`config.client_secret: {"length must be at least 1"}`) when using OIDC as the auth method.
    To resolve this, add the correct value to `client_secret` and restart Kong. On the next login,
    you will proceed without issue.
related_resources: []
---

## Problem

When trying to log into Kong Manager, you receive the following error:

```
[error] 2142#0: *3867 [lua] kong.lua:429: fn(): kong[auth][postgres] schema violation (config.client_secret: {"length must be at least 1"}), client: 123.123.123.1, server: kong_admin, request: "GET /auth?Kong-Admin-User=sample@email.com HTTP/1.1", host:"localhost:8001", referrer: "http://localhost:8002/"
```

## Cause

This error will occur when the value inside `client_secret` is empty. If the variable was wiped out or does not contain any data, you will receive the error:

```
schema violation (config.client_secret: {"length must be at least 1"})
```

## Solution

To resolve this, add the correct value to `client_secret` and restart Kong. On the next login, you can proceed without issue.
