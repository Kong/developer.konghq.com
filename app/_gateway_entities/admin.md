---
title: Admins
content_type: reference
entities:
  - admin

description: |
  Admins can manage entities inside workspaces, including users and their roles.
  

related_resources:
  - text: RBAC entity
    url: /gateway/entities/rbac/
  - text: Groups entity
    url: /gateway/entities/group/

tier: enterprise

api_specs:
  - gateway/admin-ee

tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform

schema:
  api: gateway/admin-ee
  path: /schemas/Admin

---

@todo

An Admin belongs to a Workspace and should have at least one role with a set of permissions. If an Admin is in a Workspace without a role, they can’t see or interact with anything. Admins can manage entities inside Workspaces, including users and their roles.

