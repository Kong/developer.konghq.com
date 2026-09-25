---
title: How to know the admin username for each Admin API when RBAC and audit log are enabled
content_type: support
description: "Learn how to identify which Kong Gateway admin issued an Admin API request when RBAC and audit logging are enabled, using audit log fields or a direct database query."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I know which Kong admin sent an Admin API request when RBAC and audit log are enabled?
  a: |
    Audit logs record the requesting admin's `rbac_user_id`. Cross-reference `rbac_user_name` and `request_source` in the audit logs, or query the Kong database directly with a `SELECT` that joins the `admins` and `audit_requests` tables on `rbac_user_id`, to resolve the corresponding admin `username`.
---

## Overview

We have enabled RBAC and audit log with Kong. However audit logs only show `rbac_user_id`, how could I know which Kong admin sent this request?

## Steps

Kong Gateway is able to show admin username.

Audit logs include `rbac_user_name` and `request_source`. By combining the data in the `request_source` field with the `path` field, you can determine login and logout events from the logs. See the documentation for more detail on interpreting audit logs.

Alternatively, you can determine the admin username for each Admin API request directly from the database. Log in to the Kong database and execute the following SQL:

```sql

SELECT username, workspace, path, method FROM admins FULL OUTER JOIN audit_requests ON admins.rbac_user_id = audit_requests.rbac_user_id;
```

It will show the admin username for each Admin API as below

```

username | workspace | path | method
kong_admin | 91d4035f-c4ea-474a-b272-f0e165757beb | /userinfo | GET
aaa | 91d4035f-c4ea-474a-b272-f0e165757beb | /default/kong | GET
```
