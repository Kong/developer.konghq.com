---
title: "LDAP authentication for Kong Manager failed with \"User not found\" error message"
content_type: support
description: 'LDAP login to Kong Manager fails with a "user not found" error when the LDAP user does not exist or is not under the configured `base_dn` — a different, later-stage error than "Admin not found."'
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does LDAP authentication for Kong Manager fail with a "user not found" error?
  a: |
    Kong Manager's LDAP auth fails with `user not found` when the `kong_admin` (or other) LDAP user doesn't exist, or its DN falls outside the configured `base_dn`. A different, earlier error, `Admin not found`, means the corresponding Admin object was never created in Kong; create that first, then troubleshoot the LDAP-side lookup.
related_resources: []
---

## Problem

When logging in to Kong Manager as an LDAP user, authentication fails with the following error:

```
2025/04/14 20:23:42 [error] 26#0: *68309 [kong] access.lua:183 user not found, client: 172.19.0.1, server: kong_admin, request: "GET /auth HTTP/1.1", host: "localhost:8001", referrer: "http://localhost:8002/"
```

## Cause

An example of the full error messages is as follows;

```
2025/04/14 20:23:42 [debug] 26#0: *68309 [kong] access.lua:130 binding with cn=admin,dc=kong,dc=local and conf.ldap_password
2025/04/14 20:23:42 [debug] 26#0: *68309 [kong] access.lua:140 ldap bind successful, performing search request with base_dn:ou=users,dc=kong,dc=local, scope='sub', and filter=uid=kong_admin
2025/04/14 20:23:42 [debug] 26#0: *68309 [kong] access.lua:165 finding groups with member attribute: memberOf
2025/04/14 20:23:42 [error] 26#0: *68309 [kong] access.lua:183 user not found, client: 172.19.0.1, server: kong_admin, request: "GET /auth HTTP/1.1", host: "localhost:8001", referrer: "http://localhost:8002/"
```

This indicated that `kong_admin` was not found in the LDAP server.

## Solution

Check the following things;

1. Make sure the `kong_admin` user exists in your LDAP directory

2. Make sure the `kong_admin` user's DN is under the sub-directory tree of `base_dn`

Note: there is an earlier prerequisite gate that produces a different symptom. If the username was never provisioned as a Kong Admin object, Kong logs "Admin not found" instead of "User not found" — a distinct, earlier error in the login flow than the one described above. If you see "Admin not found," create the corresponding Admin object in Kong first, before troubleshooting the LDAP-side lookup.
