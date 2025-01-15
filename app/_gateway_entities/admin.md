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
  - text: Workspace
    url: /gateway/entities/workspace/

tier: enterprise

api_specs:
  - gateway/admin-ee

tools:
  - admin-api

schema:
  api: gateway/admin-ee
  path: /schemas/Admin
faqs:
  - q: What happens when an Admin does not have a role assigned?
    a: If an Admin is in a Workspace without a role, they can’t see or interact with anything. Admins can manage entities inside Workspaces, including users and their roles.
    

---

## What is the Admins entity? 
The Admins entity in {{site.base_gateway}} is an [RBAC](/gateway/entities/rbac) entity used to used to manage all administrators for a specific [Workspace](/gateway/entities/workspace). 
The Admins entity can be managed using the Admin API or Kong Manager and is used in the following operations:

* [Admin registration](/api/gateway/admin-ee/3.9/#/operations/post-admins-register)
* [Password reset](/api/gateway/admin-ee/3.9/#/operations/get-admins-password_resets)
* [Read, Update Delete Admins](/api/gateway/admin-ee/3.9/#/operations/patch-admins-name_or_id-generate_register_url)
* [Viewing roles for specific Admins](/api/gateway/admin-ee/3.9/#/operations/get-admins-name_or_id-roles)
* [Creating, updating and deleting Admin roles](/api/gateway/admin-ee/3.9/#/operations/post-admins-name_or_id-roles)
* [Viewing associated Workspaces](/api/gateway/admin-ee/3.9/#/operations/get-admins-name_or_id-workspaces)


Admins can only interact with entities from within their Workspace, depending on the Admin's specific role they can enforce RBAC roles and permissions across that Workspace, including creating and inviting other Admins. 

## Kong Manager

Kong Manager has the capability to manage the Admin's entity and can handle all operations that can be managed with the Admin API. {{site.base_gateway}} should be configured to have [RBAC enabled](/gateway/entities/rbac/#enable-rbac), as well as configured for [sending email](/how-to/configure-kong-manager-email). To enable RBAC on Kong Manager to be able to configure the Admins entity, set the following: 

* Set `enforce_rbac` to `on`
* Set `admin_gui_auth `to the desired authentication like `basic-auth`
* Add a session secret to `admin_gui_session_conf`

You can do all of this automatically with the 


## Schema

{% entity_schema %}

## Invite an Admin

Inviting an Admin can only be done if you have [Enabled RBAC](/gateway/entities/rbac/#enable-rbac). You can invite an Admin by issuing a `POST` request to [`/admins/`](/api/gateway/admin-ee/3.9/#/operations/post-admins). If you have not configured [sending email](/how-to/configure-kong-manager-email) your Admin will not receive an invite link, but will still be created.

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