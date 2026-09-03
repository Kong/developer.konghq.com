---
title: Renaming a workspace in {{site.base_gateway}}
content_type: support
published: false
description: "Renaming a workspace is not supported at the moment because it is associated with other database entities, such as RBAC roles."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Is it possible to rename a workspace?
  a: |
    No — renaming a workspace isn't supported because the workspace name is referenced by other database entities, such as RBAC roles. To rename one, create a new workspace with the desired name, use decK to migrate the Kong entities into it, and then delete the old workspace.
---

## Renaming a workspace

Can a workspace be renamed?

Renaming a workspace is not supported at the moment because it is associated with other database entities.

One of the entities that are using workspaces entities is RBAC roles. If we check RBAC roles in the database, we can see the workspace's name is associated with it.

```sql
kong=# select * from rbac_roles;
                  id                  |        name         |                                  comment                                  |       created_at       | is_default 
--------------------------------------+---------------------+---------------------------------------------------------------------------+------------------------+------------
 343b0991-0f74-4e6e-8258-4b3efb47499d | default:read-only   | Read access to all endpoints, across all workspaces                       | 2026-06-11 08:59:32+00 | f
 64f4b79e-58bc-4538-bbea-e9b17fb72ab0 | default:admin       | Full access to all endpoints, across all workspaces—except RBAC Admin API | 2026-06-11 08:59:32+00 | f
 9df65539-f068-4c96-a3cf-8f09357cbfa2 | default:super-admin | Full access to all endpoints, across all workspaces                       | 2026-06-11 08:59:32+00 | f
 89dcba7b-e803-462f-b3ff-73f876d3abfa | default:kong_admin  | Default user role generated for kong_admin                                | 2026-06-11 08:59:32+00 | t
```

Our recommendation is to create a new workspace with the new name, migrate the Kong entities to the new workspace and then delete the old workspace.

The best way to perform this migration is to use decK. This will allow you to backup the configuration into declarative config format, edit the config to use the new workspace name, sync the configuration to the new workspace and delete the old workspace.
