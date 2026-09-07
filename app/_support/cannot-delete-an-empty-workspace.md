---
title: Cannot delete an empty workspace
content_type: support
description: If an Admin API call to delete a workspace fails because it is "not empty", use the `/workspaces/{workspace_name}/meta` endpoint to see exactly which entity types still have a non-zero count in that workspace.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does deleting an empty-looking workspace fail with a "not empty" error?
  a: |
    Kong checks every workspaceable entity type for a non-zero count, not just Routes/Services/Plugins — something like `rbac_roles`, `files`, or `partials` may have been created in the workspace at some point. Query the `/workspaces/{workspace_name}/meta` endpoint to see which entity type(s) have a non-zero count, then delete those specific entities via their normal Admin API routes scoped to the workspace.
related_resources: []
---

## Problem

When trying to delete a workspace, an error is returned that the workspace is not empty and the delete fails. This workspace was created in error and no Kong entities (Routes/Services/Plugins/etc) were deliberately created in it.

## Cause

Workspace deletion in Kong Gateway checks every workspaceable entity type for a non-zero row count in that workspace, not just Routes/Services/Plugins — this includes things a user wouldn't normally think to check directly, such as `rbac_roles`, `rbac_users`, `files`, `partials`, `consumer_groups`, and more.

Note: on Kong Gateway (Enterprise) 3.14.0.0, a workspace created via the Admin API (or Kong Manager, which calls the same API) does **not** automatically get any default RBAC roles or other entities seeded into it — only the original, bootstrap `default` workspace carries the four default roles (`super-admin`, `admin`, `read-only`, and the workspace-scoped default role), which are created once by a database migration when Kong is first installed, not by a per-workspace-creation hook. A workspace you create yourself and never populate will delete cleanly. If you do get a "workspace is not empty" error on a workspace you believe is empty, it means some entity was genuinely created in it at some point (for example, by a script, an integration, or a previous troubleshooting session), and the fix is to find and remove that entity, not to assume default roles were silently added.

## Solution

To find out exactly what is populating the workspace, use the Admin API call to the `/workspaces/{workspace_name}/meta` endpoint, which returns a count per entity type. For example:

```bash

curl -s "http://localhost:8001/workspaces/kb-example/meta" -H "Kong-Admin-Token: password" | jq '.counts | to_entries[] | select(.value > 0)'
{
  "key": "rbac_roles",
  "value": 4
}
```

(Every entity type with a zero count is omitted from the example above for brevity — the real response returns a count for every workspaceable entity type, most of which will be `0`.)

Once you know which entity type(s) have a non-zero count, delete those specific entities via their normal Admin API routes, scoped to the workspace by putting the workspace name as the first path segment (for example, `DELETE /{workspace_name}/rbac/roles/{role_name_or_id}` for `rbac_roles`, not `/workspaces/{workspace_name}/rbac/roles/...`). After every entity type shows a `0` count, the workspace delete will succeed.
