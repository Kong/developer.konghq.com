---
title: Restrict Admin user from creating a workspace with custom roles
content_type: support
published: false
description: How to prevent a Kong Manager Admin from creating or deleting workspaces while still allowing other administrative tasks, using two custom RBAC roles.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I restrict an Admin user from creating or deleting workspaces in Kong Manager without limiting their other tasks?
  a: |
    Create two custom RBAC roles in Kong Manager: one scoped to the default workspace and one scoped to any additional workspace the Admin should access. Grant a wildcard for other actions on those roles, then narrow the permissions to your specific use case, leaving out workspace create/delete permissions.
---

## Restrict Admin user from creating a workspace with custom roles

We want to take away the ability to create/delete workspaces for specific admins through Kong. We still want these admins to be able to accomplish other tasks within the workspace(s). This would include default workspaces and any other assigned workspaces. Is this something that can be accomplished through a custom role?

One way to accomplish this is by creating 2 custom roles inside Kong Manager.

For simplicity purposes, we will be adding a wild card to allow for all other modifications. This can be narrowed down by use case.

Role 1 should be added to the default workspace:

Role 2 should be added to any workspace you wish this Admin to be involved in:
