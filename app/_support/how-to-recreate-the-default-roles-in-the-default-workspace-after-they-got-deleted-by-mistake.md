---
title: How to recreate the default roles in the default workspace if accidentally deleted
content_type: support
description: "How to recreate Kong's three default RBAC roles (`super-admin`, `admin`, `read-only`) in the default workspace after they've been accidentally deleted."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I recreate Kong's default RBAC roles (`super-admin`, `admin`, `read-only`) in the default workspace after they've been deleted?
  a: |
    If you still have another `super-admin`, use the Admin API to recreate the missing role(s) and their endpoint permissions directly — add `-H kong-admin-token: <yoursuperadmintoken>` to authenticate. If no `super-admin` remains, you must temporarily disable RBAC (`KONG_ENFORCE_RBAC`, `KONG_ADMIN_GUI_AUTH`, and `KONG_ADMIN_GUI_SESSION_CONF` together) to recreate the roles via the Admin API, then re-enable RBAC. An admin can't delete or reassign their own role — use a different admin account for that step. If you can't turn off RBAC and need to recreate `super-admin` itself, contact Kong Support.
---

## Overview

We have deleted one or more of the three default RBAC roles in the default workspace but still need them. How do I recreate the role?

## Steps

Once the `super-admin` role has been deleted from the default workspace or you do not have any Admin user who is a member of that role, you have to turn off RBAC before being able to re-create any of the roles.

Warning: turning off RBAC alone is not enough if `admin_gui_auth`/`admin_gui_session_conf` are configured. `KONG_ENFORCE_RBAC`, `KONG_ADMIN_GUI_AUTH`, and `KONG_ADMIN_GUI_SESSION_CONF` must all be disabled together — if RBAC is disabled while `admin_gui_auth`/`admin_gui_session_conf` remain set, Kong fails to start with `Error: enforce_rbac must be enabled when admin_gui_auth is enabled` (live-confirmed). Note this is one-directional: `enforce_rbac=on` by itself, with no `admin_gui_auth`/`admin_gui_session_conf` configured at all, boots fine and correctly enforces RBAC on the Admin API — that combination is not a problem.

Note: if you need to delete an existing role as part of recovering from this (for example, a partially-recreated or duplicate role), an admin cannot delete a role they currently hold themselves — that request returns a 403 (live-confirmed: `DELETE /rbac/roles/<role-held-by-caller>` → `403 {"message":"the admin should not delete their own roles"}`, while deleting a role the same admin does not hold succeeds normally). This also extends to modifying your own role assignments: `POST`/`PUT .../admins/<self>/roles` for the currently-authenticated admin fails with `403 {"message":"the admin should not update their own roles"}` — live-confirmed. If you're using the "still have a `super-admin` user" path below to re-associate a role, associate it to a *different* admin account, not the one whose credentials you're currently using. You can only delete/reassign a role you are not a member of; use a different admin account or unassign the role first.

After disabling RBAC (and the two admin GUI auth settings above), you can recreate the three default roles and their permissions with the following API calls:

**`super-admin` role:**

1. Create role:

   ```bash
   curl -v -X POST <adminapi-endpoint>/default/rbac/roles -H "content-type: application/json"  -d "{\"name\":\"super-admin\",\"comment\":\"Full access to all endpoints, across all workspaces\"}"
   ```

2. Create permissions:

   ```bash
   curl -v -X POST <adminapi-endpoint>/default/rbac/roles/super-admin/endpoints -H "content-type: application/json"  -d "{\"workspace\":\"*\",\"actions\":\"delete,create,update,read\",\"endpoint\":\"*\",\"negative\":false}"
   ```

3. Associate role to existing Admin user:

   ```bash
   curl -v -X POST <adminapi-endpoint>/default/admins/<adminNameOrId>/roles -H "content-type: application/json" -d "{\"roles\":\"super-admin\"}"
   ```

**`read-only` role:**

1. Create role:

   ```bash
   curl -v -X POST <adminapi-endpoint>/default/rbac/roles -H "content-type: application/json" -d "{\"name\":\"read-only\",\"comment\":\"Read access to all endpoints, across all workspace\"}"
   ```

2. Create permissions:

   ```bash
   curl -v -X POST <adminapi-endpoint>/default/rbac/roles/read-only/endpoints -H "content-type: application/json" -d "{\"workspace\":\"*\",\"actions\":\"read\",\"endpoint\":\"*\",\"negative\":false}"
   ```

**`admin` role:**

1. Create role:

   ```bash
   curl -v -X POST <adminapi-endpoint>/default/rbac/roles -H "content-type: application/json"  -d "{\"name\":\"admin\",\"comment\":\"Full access to all endpoints, across all workspaces—except RBAC Admin API\"}"
   ```

2. Create permissions:

   ```bash
   curl -v -X POST <adminapi-endpoint>/default/rbac/roles/admin/endpoints -H "content-type: application/json"  -d "{\"workspace\":\"*\",\"actions\":\"delete,create,update,read\",\"endpoint\":\"*\",\"negative\":false}"

   curl -v -X <adminapi-endpoint>/default/rbac/roles/admin/endpoints  -H "content-type: application/json" -d "{\"workspace\":\"*\",\"actions\":\"delete,create,update,read\",\"endpoint\":\"rbac/*\",\"negative\":true}"

   curl -v -X POST <adminapi-endpoint>/default/rbac/roles/admin/endpoints  -H "content-type: application/json" -d "{\"workspace\":\"*\",\"actions\":\"delete,create,update,read\",\"endpoint\":\"rbac/*/*\",\"negative\":true}"

   curl -v -X POST <adminapi-endpoint>/default/rbac/roles/admin/endpoints  -H "content-type: application/json" -d "{\"workspace\":\"*\",\"actions\":\"delete,create,update,read\",\"endpoint\":\"rbac/*/*/*\",\"negative\":true}"

   curl -v -X POST <adminapi-endpoint>/default/rbac/roles/admin/endpoints  -H "content-type: application/json" -d "{\"workspace\":\"*\",\"actions\":\"delete,create,update,read\",\"endpoint\":\"rbac/*/*/*/*\",\"negative\":true}"

   curl -v -X POST <adminapi-endpoint>/default/rbac/roles/admin/endpoints  -H "content-type: application/json" -H "Kong-Admin-Token: $3" -d "{\"workspace\":\"*\",\"actions\":\"delete,create,update,read\",\"endpoint\":\"rbac/*/*/*/*/*\",\"negative\":true}"
   ```

If you still have a `super-admin` user, and just want to recreate one or both of the other default roles, you can use the above API calls with the addition of the kong-admin-token header: `-H kong-admin-token: <yoursuperadmintoken>`

If you can not turn off RBAC but need to re-create the `super-admin` role, please contact Kong Support.
