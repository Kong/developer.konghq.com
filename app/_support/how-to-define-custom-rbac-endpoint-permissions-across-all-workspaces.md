---
title: How to define RBAC endpoint permissions across all workspaces
content_type: support
description: Because Kong Manager omits the workspace from RBAC endpoint permission requests, call the Admin API directly with the workspace key set to * to apply a custom endpoint permission across all workspaces.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I apply custom endpoint permissions for roles to all workspaces akin to the bootstrapped default workspace permissions?
  a: |
    Kong Manager does not send the workspace details in the JSON body when creating or updating
    RBAC endpoint permissions, so permissions apply only to the currently selected workspace.
    To apply a permission to all workspaces, call the `admin-api` directly and add a `workspace`
    key with a value of `*` to the JSON payload (for example,
    `{"endpoint":"*","actions":"create,read,update,delete","negative":false,"workspace":"*"}`).
    Regardless of the workspace in the request URL, the permission then applies to all workspaces.
related_resources: []
---

## Overview

This article describes how to apply custom RBAC endpoint permissions for roles across all workspaces.

## Steps

Endpoint permissions can be assigned to a single workspace or all workspaces, however Kong Manager does not send the workspace details in the JSON body of the request to create / update the endpoint permissions.

The effect of this is that permissions that are created using Kong Manager will use the currently selected workspace in Kong Manager, as the workspace to be applied to.

To circumvent the Kong Manager behavior, the `admin-api` can be called directly and the permissions can be set to apply to all workspaces.

Example request to create role permissions using Kong Manager:

```bash
curl -X POST 'https://admin.local.docker:8444/default/rbac/roles/SuperAdmin/endpoints' \
  -H 'Content-Type: application/json' \
  -H 'Kong-Admin-Token: admin' \
  --data-raw '{"endpoint":"*","actions":"create,read,update,delete","negative":false}'
```

To apply to all workspaces, add the `workspace` key with a value of `*` to the JSON payload:

```bash
curl -X POST 'https://admin.local.docker:8444/default/rbac/roles/SuperAdmin/endpoints' \
  -H 'Kong-Admin-Token: admin' \
  -H 'Content-Type: application/json' \
  --data-raw '{"endpoint":"*","actions":"create,read,update,delete","negative":false,"workspace":"*"}'
```

Regardless of the workspace used in the request URL, the applicable workspace for the permission will be all workspaces `*`.

Security Note: This works regardless of which workspace the role was assigned to the user in and therefore could propose a security risk if used incorrectly.

For example, the `workspace-read-only` role that is auto-created upon new workspace instantiation, could have its permissions modified in this way so that all admins that previously only had read only access to the single workspace, can now read from all endpoints in all workspaces.
