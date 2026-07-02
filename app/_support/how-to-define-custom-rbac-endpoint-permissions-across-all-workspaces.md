---
title: How do I define RBAC endpoint permissions across every Workspace?
content_type: support
description: "Because Kong Manager omits the Workspace from RBAC endpoint permission requests, call the Admin API directly with the Workspace key set to * to apply a custom endpoint permission across all Workspaces."
products:
  - gateway
works_on:
  - on-prem
tldr:
  q: How do I apply custom endpoint permissions for roles to every Workspace akin to the bootstrapped default Workspace permissions?
  a: |
    Kong Manager does not send the Workspace details in the JSON body when creating or updating
    RBAC endpoint permissions, so permissions apply only to the currently selected Workspace.
    To apply a permission to all Workspaces, call the Admin API directly and add a `workspace`
    key with a value of `*` to the JSON payload.
related_resources: []
---

Endpoint permissions can be assigned to a single Workspace or all Workspaces, however Kong Manager does not send the Workspace details in the JSON body of the request to create / update the endpoint permissions.

The effect of this is that permissions that are created using Kong Manager will use the currently selected Workspace in Kong Manager, as the Workspace to be applied to.

To circumvent the Kong Manager behavior, the Admin API can be called directly and the permissions can be set to apply to all Workspaces.

## Steps

For example, the `workspace-read-only` role that is auto-created upon new Workspace instantiation, could have its permissions modified in this way so that all admins that previously only had read only access to the single Workspace, can now read from all endpoints in all Workspaces.

To apply a permission to all Workspaces, call the Admin API [`PATCH /{workspace}/rbac/roles/{role}/endpoints` endpoint](/api/gateway/admin-ee/#/operations/update-rbac_role_endpoint-in-workspace) and add a `workspace` key with a value of `*` to the JSON payload.
Replace `WORKSPACE` with the Workspace name in the URL and `ROLE_NAME_OR_ID` with the role's name or ID:

```bash
curl -i -X PATCH http://localhost:8001/WORKSPACE/rbac/roles/ROLE_NAME_OR_ID/endpoints \
  -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"endpoint":"*","actions":["create","read","update","delete"],"negative":false,"workspace":"*"}'
```

Regardless of the Workspace in the request URL, the permission then applies to all Workspaces.