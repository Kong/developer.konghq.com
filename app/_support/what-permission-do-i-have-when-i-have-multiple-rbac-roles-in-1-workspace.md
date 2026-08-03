---
title: How Kong combines permissions across multiple RBAC roles in one workspace
content_type: support
description: Explains how Kong combines permissions from multiple RBAC roles assigned in the same workspace, with negative permissions taking priority over positive ones.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What permission do I have when I have multiple RBAC roles in one workspace?
  a: |
    Kong combines the permissions granted by all RBAC roles assigned to an admin in a workspace. A negative permission on any assigned role always overrides a positive permission on the same endpoint from another role.
related_resources: []
---

## What permission do I have when I have multiple RBAC roles in one workspace

I have multiple RBAC roles in 1 workspace, what permission do I have in that workspace?

As a conclusion, Kong will combine all the permissions from all the RBAC roles you have in 1 workspace,

and negative permissions have higher priority than positive permissions.

For each endpoint, if it has been included in any negative permissions from all the RBAC roles you have in 1 workspace, then you do not have this endpoint's permission.

For each endpoint, if it has been included in any positive permissions from all the RBAC roles you have in 1 workspace, and it has not been included in any negative permissions from all the RBAC roles you have in 1 workspace, then you have this endpoint's permission.

Let's see below examples:

We created w1 workspace in Kong Manager, and we created an admin and its username is 'bob'.

w1 workspace has below 4 default RBAC roles

```
workspace-super-admin role:
positive read/write permissions on all endpoints

workspace-admin role:
positive read/write permissions on all endpoints
negative read/write permission on rbac related endpoints

workspace-read-only role:
positive read permissions on all endpoints

workspace-portal-admin role:
positive read/write permissions on portal related endpoints
negative read/write permission on rbac related endpoints
```

Case1: bob has been assigned the `workspace-super-admin` role and the `workspace-admin` role

bob does not have permissions on rbac related endpoints.

bob has read/write permissions on all other endpoints.

Case2: bob has been assigned the `workspace-admin` role and the `workspace-read-only` role

bob does not have permissions on rbac related endpoints.

bob has read/write permissions on all other endpoints.

Case3: bob has been assigned the `workspace-read-only` role and the `workspace-portal-admin` role

bob does not have permissions on rbac related endpoints.

bob has read permissions on all other endpoints.

bob has read/write permissions on portal related endpoints.

Case4: bob has been assigned the `workspace-super-admin` role and the `workspace-read-only` role

bob has read/write permissions on all endpoints.
