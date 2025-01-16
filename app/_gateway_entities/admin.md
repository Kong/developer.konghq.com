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
  - text: Workspace entity
    url: /gateway/entities/workspace/
  - text: Sending Email with Kong Manager
    url: /how-to/configure-kong-manager-email
    
tier: enterprise

api_specs:
  - gateway/admin-ee

tools:
  - admin-api

schema:
  api: gateway/admin-ee
  path: /schemas/Admin
faqs:
  - q: What happens when an Admin doesn't have a role assigned?
    a: If an Admin is in a Workspace without a role, they can’t see or interact with anything. Admins can manage entities inside Workspaces, including users and their roles.
    

---

## What are Admins?
Admins in {{site.base_gateway}} are [RBAC](/gateway/entities/rbac/) entities used to used to manage all administrators for a specific [Workspace](/gateway/entities/workspace/). 
Admins can be managed using the Admin API or Kong Manager and are used in the following operations:

* [Admin registration](/api/gateway/admin-ee/#/operations/post-admins-register)
* [Password reset](/api/gateway/admin-ee/#/operations/get-admins-password_resets)
* [Read, update, or delete Admins](/api/gateway/admin-ee/#/operations/patch-admins-name_or_id-generate_register_url)
* [Viewing Roles for specific Admins](/api/gateway/admin-ee/#/operations/get-admins-name_or_id-roles)
* [Creating, updating, and deleting Admin Roles](/api/gateway/admin-ee/#/operations/post-admins-name_or_id-roles)
* [Viewing associated Workspaces](/api/gateway/admin-ee/#/operations/get-admins-name_or_id-workspaces)


Admins can only interact with entities from within their Workspace. Depending on the Admin's specific role, they can enforce RBAC roles and permissions across that Workspace, including creating and inviting other Admins. 

## Schema

{% entity_schema %}

## Invite an Admin

Inviting an Admin can only be done if you have [enabled RBAC](/gateway/entities/rbac/#enable-rbac). You can invite an Admin by issuing a `POST` request to [`/admins`](/api/gateway/admin-ee/3.9/#/operations/post-admins). 

If you haven't configured [sending email](/how-to/configure-kong-manager-email), your Admin won't receive an invite link, but will still be created.

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