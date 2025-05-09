---
title: Admins
content_type: reference
entities:
  - admin

description: |
  Admins can manage {{site.base_gateway}} entities inside Workspaces, including Users and their Roles.


related_resources:
  - text: RBAC entity
    url: /gateway/entities/rbac/
  - text: Groups entity
    url: /gateway/entities/group/
  - text: Workspace entity
    url: /gateway/entities/workspace/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/

api_specs:
  - gateway/admin-ee

tools:
  - admin-api

schema:
  api: gateway/admin-ee
  path: /schemas/Admin
faqs:
  - q: What happens when an Admin doesn't have a Role assigned?
    a: If an Admin is in a Workspace without a Role, they can’t see or interact with anything. Admins can manage entities inside Workspaces, including Users and their Roles.

works_on:
  - on-prem
  - konnect

tags:
  - rbac
---

## What is an Admin?
Admins in {{site.base_gateway}} are [RBAC](/gateway/entities/rbac/) entities used to used to manage all administrators for a specific [Workspace](/gateway/entities/workspace/). 
Admins can be managed using the Admin API or Kong Manager and are used in the following operations:

* [Admin registration](/api/gateway/admin-ee/#/operations/post-admins-register)
* [Password reset](/api/gateway/admin-ee/#/operations/get-admins-password_resets)
* [Read, update, or delete Admins](/api/gateway/admin-ee/#/operations/patch-admins-name_or_id-generate_register_url)
* [Viewing Roles for specific Admins](/api/gateway/admin-ee/#/operations/get-admins-name_or_id-roles)
* [Creating, updating, and deleting Admin Roles](/api/gateway/admin-ee/#/operations/post-admins-name_or_id-roles)
* [Viewing associated Workspaces](/api/gateway/admin-ee/#/operations/get-admins-name_or_id-workspaces)


Admins can only interact with entities from within their Workspace. Depending on the Admin's specific Role, they can enforce RBAC Roles and Permissions across that Workspace, including creating and inviting other Admins. 

## Schema

{% entity_schema %}

## Invite an Admin

Inviting an Admin can only be done if you have [enabled RBAC](/gateway/entities/rbac/#enable-rbac). You can invite an Admin by issuing a `POST` request to [`/admins`](/api/gateway/admin-ee/3.9/#/operations/post-admins). 

If you haven't configured email capabilities your Admin won't receive an invite link, but will still be created.

{% entity_example %}
type: admin
data:
  username: admin
  email: $ADMIN_EMAIL
  rbac_token_enabled: true
headers:
  admin-api:
    - "Kong-Admin-Token: $ADMIN_TOKEN"
{% endentity_example %}