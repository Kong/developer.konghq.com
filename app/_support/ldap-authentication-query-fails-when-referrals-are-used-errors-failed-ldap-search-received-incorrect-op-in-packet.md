---
title: "LDAP Authentication query fails when referrals are used. Errors: \"failed ldap search\" & \"received incorrect Op in packet\""
content_type: support
description: As of now, the Kong LDAP Authentication plugin does not support LDAP referrals.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does LDAP Authentication fail with "failed ldap search" and "received incorrect Op in packet" when referrals are used?
  a: |
    The Kong LDAP Authentication plugin doesn't support LDAP referrals, so a query that triggers a referral to another LDAP server fails even though the underlying search succeeded. Work around this by pointing the plugin at a Global Catalog server instead of a single LDAP server.
---

## Problem

We're trying to use the LDAP Authentication plugin with our LDAP server but it appears to be failing. Our environment uses LDAP referrals. Our Kong logs show errors similar to the following when an LDAP query fails:

```
2026/02/06 21:32:35 [error] 22#0: *10808 [lua] access.lua:89: ldap_authenticate(): [ldap-auth-advanced] failed ldap search for cn=sec23206 base_dn=dc=wmservice,dc=corpnet1,dc=com, client: 172.23.0.1, server: kong_admin, request: "GET /userinfo HTTP/1.1", host: "localhost:8001", referrer: "http://localhost:8002/login"
2026/02/06 21:32:35 [error] 22#0: *10808 [lua] responses.lua:121: ldap_authenticate(): Received incorrect Op in packet: 19, expected 5, client: 172.23.0.1, server: kong_admin, request: "GET /userinfo HTTP/1.1", host: "localhost:8001", referrer: "http://localhost:8002/login"
```

## Cause

As of now, the Kong LDAP Authentication plugin does not support LDAP referrals. This limitation is documented in the LDAP Authentication Advanced plugin documentation.

This means that if the queried LDAP server returns a referral asking Kong to query a different LDAP server, Kong cannot follow the referral. In such cases, the LDAP Authentication plugin will return an error, even if the search itself was successful.

## Solution

A feature request to support LDAP referrals has been filed as FTI-582. When discussing this with an Account Executive, please reference this FTI number.

A recommended workaround is to configure the LDAP Authentication plugin to query the Global Catalog server instead of a single LDAP server. For more information, see the following references: Global Catalog overview and Windows 2000 Server documentation.
