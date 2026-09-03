---
title: How to recreate `kong_admin` user
content_type: support
description: "How to recreate a deleted `kong_admin` super admin user, either through another existing super admin or by temporarily disabling RBAC."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I recreate the `kong_admin` user after it's been accidentally deleted?
  a: |
    If another admin already has the default workspace's super admin role, use it to invite a new `kong_admin` and generate a fresh token — no downtime required. If no other super admin exists, temporarily disable RBAC (`KONG_ENFORCE_RBAC`, `KONG_ADMIN_GUI_AUTH`, and `KONG_ADMIN_GUI_SESSION_CONF` must all be unset together) to access Kong manager without authentication, recreate `kong_admin` with the super admin role, then re-enable RBAC.
---

## Overview

The default workspace super admin `kong_admin` might be accidentally deleted. This article tells how to recreate the `kong_admin` user.

## Steps

If you have another admin user with the default workspace’s super admin role, you can re-create the super admin by the below method.

1. Login to Kong manager using another admin user name with the super admin role.
2. Invite admin and grant the super admin role to the user.
3. Login to Kong manager as the new admin user.
4. Re-generate the token and use the new token.

If you don't have another admin user with the default workspace’s super admin role, please follow the below steps.

1. Disable RBAC by commenting out the below configurations, and restart Kong.

   Example

   ```bash

   # - KONG_ENFORCE_RBAC=on
   # - KONG_ADMIN_GUI_AUTH=basic-auth
   # - KONG_ADMIN_GUI_SESSION_CONF={"secret":"secret","storage":"kong","cookie_secure":false}
   ```

   Warning: if `KONG_ADMIN_GUI_AUTH` or `KONG_ADMIN_GUI_SESSION_CONF` are left set while `KONG_ENFORCE_RBAC` is disabled, Kong will fail to start with the explicit error `Error: enforce_rbac must be enabled when admin_gui_auth is enabled` — so all three must be disabled together. (The reverse is not a problem: `KONG_ENFORCE_RBAC=on` by itself, with no `admin_gui_auth`/`admin_gui_session_conf` set, is a normal, valid configuration and starts fine — RBAC-protecting the Admin API doesn't require Kong Manager GUI auth to also be configured.)

2. Open Kong manager -> invite admin-> to make the user name as `kong_admin`, fill in the email and grant the default workspace’s super admin role to the user.

   If you have an SMTP server configured, you will receive a registration email. Please skip to step 6.

   If there is no SMTP server configured, please continue to do steps 3 and 5. But step 4 is still necessary.

3. Click the `kong_admin` in the "invited" list -> click 'generate registration URL', and note this URL.
4. Enable RBAC by commenting in the configurations in step 1, and restart Kong.
5. Access the `<your kong url>/<registration path in step 3>`.
6. Reset password.
7. Login Kong manager as `kong_admin`.
8. Reset token and use the new token.
