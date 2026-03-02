---
title: Define RBAC permissions for workspaces

content_type: support
description: How to create RBAC permissions that apply to all workspaces instead of a single workspace.

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.4'

related_resources:
  - text: RBAC reference
    url: /gateway/kong-enterprise/rbac/
  - text: Admin API reference
    url: /gateway/admin-api/

tldr:
  q: How do I create RBAC permissions that apply to all workspaces instead of a single workspace?
  a: Use the Admin API to create or update endpoint permissions and set the `workspace` key to `'*'` in the JSON payload. This will apply the permissions to all workspaces.


---




## Create or update permissions for all workspaces

When creating or updating RBAC endpoint permissions, the permissions can be set to apply to a single workspace or all workspaces. However, Kong Manager does not include the workspace details in the JSON body of the request when creating or updating endpoint permissions.

The Admin API can be called directly and the permissions can be set to apply to all workspaces:

```
curl -X POST 'https://admin.local.docker:8444/default/rbac/roles/SuperAdmin/endpoints'
-H 'Content-Type: application/json'
-H 'Kong-Admin-Token: admin'
--data-raw '{"endpoint":"*","actions":"create,read,update,delete","negative":false}'
```

To apply to all workspaces, add the workspaces key with a value of '' to the JSON payload:
```
curl -X POST 'https://admin.local.docker:8444/default/rbac/roles/SuperAdmin/endpoints'
-H 'Kong-Admin-Token: admin'
-H 'Content-Type: application/json'
--data-raw '{"endpoint":"","actions":"create,read,update,delete","negative":false,"workspace":"*"}'
```

Regardless of the workspace used in the request URL, the applicable workspace for the permission will be all workspaces '*'.

## Security implications

Setting permissions to apply to all workspaces can have significant security implications if not used carefully. It can grant users access to endpoints across all workspaces, which may not be the intended level of access. For example, the `workspace-read-only` role that is auto-created upon new workspace instantiation, could have its permissions modified in this way so that all admins that previously only had read only access to the single workspace, can now read from all endpoints in all workspaces.
