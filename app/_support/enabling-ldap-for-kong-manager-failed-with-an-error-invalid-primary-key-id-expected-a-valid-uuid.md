---
title: "Enabling LDAP for Kong Manager failed with an error; invalid primary key: '{id=\"expected a valid UUID\"}'"
content_type: support
description: "LDAP authentication for Kong Manager fails with an `invalid primary key` error when the LDAP user falls back to the anonymous consumer, which Kong Manager doesn't permit."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does enabling LDAP for Kong Manager fail with an \"invalid primary key: expected a valid UUID\" error?"
  a: |
    LDAP authentication falls back to the anonymous consumer when it fails, and Kong Manager doesn't allow anonymous access, which surfaces as an `invalid primary key` error. Set `header_type: Basic` in `admin_gui_auth_conf` (LDAP's default `header_type: ldap` triggers this), and confirm the user exists in Kong Admins, `base_dn` is correct, and any LDAP group is mapped to a Kong Role.
related_resources: []
---

## Problem

I am trying to set up LDAP Authentication for Kong Manager. I cannot log in. In the log, I found the following error message;

```

access.lua:288 failed to load consumer[postgres] invalid primary key: '{id="expected a valid UUID"}'
```

What does this mean? How can I fix it?

## Solution

The error message indicated that somehow LDAP authentication failed for a user and fell back to the anonymous user as the plugin's default behavior. As LDAP Authentication for Kong Manager does not allow anonymous user, this always fails.

Note: Kong Manager login now forces `config.consumer_optional=true` for `ldap-auth-advanced`, so on current Kong Gateway versions an unmapped/failed LDAP user returns a clean `401 Unauthorized` response instead of this primary-key crash. The debug/error sequence below reflects older Kong Gateway versions, but the underlying cause and the `header_type` fix are unchanged — if you see a 401 immediately after the `ldap-auth-advanced:access` debug message, the same root cause and fix described here still apply.

If the error message happens right after the `ldap-auth-advanced:access` message as follows, possibly you have set `header_type: ldap` (by default)

```

kong-ee            | 2025/04/15 20:54:45 [debug] 25#0: *164 [lua] init.ljbc:0: calling patched method 'ldap-auth-advanced:access'
kong-ee            | 2025/04/15 20:54:45 [debug] 25#0: *164 [lua] init.ljbc:0: calling patched method 'ldap-auth-advanced:access'
kong-ee            | 2025/04/15 20:54:45 [debug] 25#0: *164 [kong] access.lua:288 failed to load consumer[postgres] invalid primary key: '{id="expected a valid UUID"}'
```

Solution:

Please make sure `header_type: Basic` is set in the `admin_gui_auth_conf` configuration. This is required for LDAP authentication for Kong Manager.

This error message may be caused by a different reason, too. In such a case, potentially there are other error or debug messages before the error.

Also, check the following settings;

1. The user is already in Admins in Kong

2. `base_dn` is not only roodDN unless `base_dn` is pointing to a Global catalog

3. The user is under the `base_dn` sub-directory tree in the LDAP/Active Directory server

4. `kong_admin` does not work unless the `kong_admin` user exists in the LDAP server or is mapped to an LDAP user

5. For Group mapping, you have to map the existing LDAP group to a Kong Role at first. Note that an LDAP user still needs to be created in Kong Admins even an LDAP group mapped to a Kong Role.
