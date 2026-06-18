---
title: How to define RBAC endpoint permissions across every workspace
content_type: support
description: Because Kong Manager omits the workspace from RBAC endpoint permission requests, call the Admin API directly with the workspace key set to * to apply a custom endpoint permission across all workspaces.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I apply custom endpoint permissions for roles to every workspace akin to the bootstrapped default workspace permissions?
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


Endpoint permissions can be assigned to a single workspace or all workspaces, however Kong Manager does not send the workspace details in the JSON body of the request to create / update the endpoint permissions.

The effect of this is that permissions that are created using Kong Manager will use the currently selected workspace in Kong Manager, as the workspace to be applied to.

To circumvent the Kong Manager behavior, the `admin-api` can be called directly and the permissions can be set to apply to all workspaces.

For example, the `workspace-read-only` role that is auto-created upon new workspace instantiation, could have its permissions modified in this way so that all admins that previously only had read only access to the single workspace, can now read from all endpoints in all workspaces.
