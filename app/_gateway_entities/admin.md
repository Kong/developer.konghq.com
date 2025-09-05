---
title: Admins
content_type: reference
entities:
  - admin

description: |
  Admins can manage {{site.base_gateway}} entities inside Workspaces, including users and their roles.


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
  - q: What happens when an admin doesn't have a role assigned?
    a: If an admin is in a Workspace without a role, they can’t see or interact with anything. Admins can manage entities inside Workspaces, including users and their roles.
  - q: What is a super admin?
    a: A super admin is a role that has the ability to assign and modify RBAC roles and permissions. A generic admin without this role can't manage RBAC.
  - q: How can I invite and manage admins in Kong Manager?
    a: If you want to manage admins from the Kong Manager UI, go to Teams > Admins. From here, you can invite new admins, manage existing admins, and find invitation links for invited admins.
  - q: Can admins manage multiple Workspaces?
    a: No, each admin is specific to one Workspace.

works_on:
  - on-prem

tags:
  - rbac
---

## What is an admin?
Admins in {{site.base_gateway}} are [RBAC](/gateway/entities/rbac/) entities used to used to manage all administrators for a specific [Workspace](/gateway/entities/workspace/). 
Admins can be managed using the Admin API or Kong Manager and are used in the following operations:

* [Admin registration](/api/gateway/admin-ee/#/operations/create-admins-credentials)
* [Password reset](/api/gateway/admin-ee/#/operations/update-admins-password-resets)
* [Read, update, or delete Admins](/api/gateway/admin-ee/#/operations/patch-admins-name_or_id-generate_register_url)
* [Viewing Roles for specific Admins](/api/gateway/admin-ee/#/operations/get-admins-name_or_id-roles)
* [Creating, updating, and deleting Admin Roles](/api/gateway/admin-ee/#/operations/create-admins-name_or_id-roles)
* [Viewing associated Workspaces](/api/gateway/admin-ee/#/operations/get-admins-name_or_id-workspaces)


Admins can only interact with entities from within their Workspace. Depending on the admin's specific role, they can enforce RBAC roles and permissions across that Workspace, including creating and inviting other admins. 

## Schema

{% entity_schema %}

## Invite an admin

Inviting an admin can only be done if you have [enabled RBAC](/gateway/entities/rbac/#enable-rbac). You can invite an admin by issuing a `POST` request to [`/admins`](/api/gateway/admin-ee/#/operations/post-admins). 

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

If you haven't configured email capabilities your admin won't receive an invite link, but the link will still be created. 
You can copy the generated invite link from the Kong Manager UI and provide it directly to your intended admin.

By default, the invite link expires after 259,200 seconds (3 days). 
You can customize this time frame by adjusting the [`admin_invitation_expiry`](/gateway/configuration/#admin-invitation-expiry) parameter in `kong.conf`.
