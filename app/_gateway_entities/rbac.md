---
title: RBAC
content_type: reference
products:
  - gateway
tiers: 
  - enterprise
tools:
    - admin-api
    - kic
    - terraform
entities:
  - rbac
description: The RBAC entity is what allows for the RBAC system to be administered.
schema:
    api: gateway/admin-ee
    path: /schemas/rbac

related_resources:
  - text: Gateway Workspace entity
    url: /gateway/entities/workspace/
  - text: Gateway Vault entity
    url: /gateway/entities/vault/
---

## What is RBAC?
RBAC (Role based access control) is a {{site.base_gateway}} entity used to manage administrative and operational features based on [roles and permissions](/gateway/roles-and-permissions). RBAC is built on the following fundemental principle: 

* In {{site.base_gateway}} there are users. 
* Every user has a Role
* Every Role belongs to a Group
* A Group is a collection of permissions. 
Permissions effect {{site.base_gateway}} resources which are the core components of an API. 


## RBAC Entities

{% feature_table %} 
item_title: RBAC Entity
columns:
  - title: Description
    key: description
  - title: Field type
    key: field_type
  - title: Constant type
    key: constant_type
features:
  - title: "`User`"
    description: |
      The entity interacting with the system. Can be associated with zero, one, or more roles.
    field_type: true
    constant_type: true
  - title: "`Role`"
    description: |
      A set of permissions (`role_endpoint` and `role_entity`). Has a name and can be associated with zero, one, or more permissions.
    field_type: true
    constant_type: true
  - title: "`role_source`"
    description: |
      The origin of the RBAC user role. Specifies where the user role is defined, either locally or through an identity provider (IdP).
    field_type: true
    constant_type: false
  - title: "`role_endpoint`"
    description: |
      A set of enabled or disabled actions.
    field_type: true
    constant_type: false
  - title: "`role_entity`"
    description: |
      A set of enabled or disabled actions. For example: The role developer has one `role_entity` attached to a UUID. 
    field_type: true
    constant_type: false
{% endfeature_table %}

{% include entities/permissions-table.md %}


## Enable RBAC
{% navtabs %}
{% navtab "Quickstart" %}

This command sets the Kong super admin password to kong and sets up RBAC and Kong Developer Portal. This command assumes you have a valid license in the environment variable `KONG_LICENSE_DATA`:
```
curl -Ls get.konghq.com/quickstart | bash -s -- -e "KONG_LICENSE_DATA" \
   -e "KONG_ENFORCE_RBAC=on" \
   -e "KONG_ADMIN_GUI_AUTH=basic-auth" \
   -e "KONG_PASSWORD=kong" \
   -e "KONG_PORTAL=on" \
   -e 'KONG_ADMIN_GUI_SESSION_CONF={"secret":"kong", "cookie_lifetime":300000, "cookie_renew":200000, "cookie_name":"kong_cookie", "cookie_secure":false, "cookie_samesite": "off"}'
```
{% endnavtab %}
{% endnavtabs %}
## Kong Mesh

Mesh provides two globally scoped resources to implement RBAC. A globally scoped resouce is not bound to a Mesh.


{% feature_table %} 
item_title: Mesh RBAC Role
columns:
  - title: Description
    key: description
  - title: Scoped Globally
    key: global_scope

features:
  - title: "`AccessRole`"
    description: |
      Specifies the access and resources that are granted.
    global_scope: true
  - title: "`AccessRoleBinding`"
    description: |
      Assigns a set of `AccessRoles` to a set of objects (users and groups). 
    global_scope: true

{% endfeature_table %}

## Schema

{% entity_schema %}

## Set up a Route

{% entity_example %}
type: rbac
data:
  name: my-user
  user_token: exampletoken
{% endentity_example %}
