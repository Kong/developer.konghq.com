---
title: RBAC
content_type: reference
products:
  - gateway
tiers: 
  - enterprise
tools:
    - admin-api
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
  - text: Roles and Permissions
    url: /gateway/roles-and-permissions/
---

## What is RBAC?
RBAC (Role based access control) is a {{site.base_gateway}} entity used to manage administrative and operational features based on [roles and permissions](/gateway/roles-and-permissions). RBAC is built on the following fundamental principles: 

* In {{site.base_gateway}} there are users. 
* Every user has a Role
* Every Role belongs to a Group
* A Group is a collection of permissions. 
Permissions effect {{site.base_gateway}} resources which are the core components of an API. 

## RBAC precedence order

{{site.base_gateway}} uses a precedence model when checking if a user has sufficient permissions to access an endpoint, a resource, or a Workspace. This information is collected from the various rules applied across the roles and groups assigned to a user. 

For each request, {{site.base_gateway}} checks for an RBAC rule assigned to the requesting user in the following order:

1. An allow or deny rule against the current endpoint in the current Workspace.
2. A wildcard allow or deny rule against the current endpoint in any Workspace.
3. An allow or deny rule against any endpoint (wildcard) in the current Workspace.
4. A wildcard allow or deny rule against any endpoint in any Workspace. 

If {{site.base_gateway}} finds a matching rule for the current user, endpoint or Workspace it allows or denies the request based on the rule. Once {{site.base_gateway}} finds an applicable rule, the algorithm stops and doesn't check less specific rules. If no rules are found (approval or denial) the request is denied. 


## RBAC Entities



{% feature_table %} 
item_title: RBAC Entity
columns:
  - title: Description
    key: description

features:
  - title: "`User`"
    description: |
      The entity interacting with the system. Can be associated with zero, one, or more roles.

  - title: "`Role`"
    description: |
      A set of permissions (`role_endpoint` and `role_entity`). Has a name and can be associated with zero, one, or more permissions.

  - title: "`role_source`"
    description: |
      Specifies where the user role is defined, either locally or through an identity provider (IdP).

  - title: "`role_endpoint`"
    description: |
      A set of enabled or disabled actions.

  - title: "`role_entity`"
    description: |
      A set of enabled or disabled actions. For example: The role developer has one `role_entity` attached to a UUID. 

{% endfeature_table %}




{% include entities/permissions-table.md %}


## Enable RBAC
{% navtabs %}
{% navtab "Quickstart" %}

This command sets the Kong super admin password to `kong` and sets up RBAC and a Developer Portal. This command assumes you have a [valid license in the environment variable `KONG_LICENSE_DATA`](/gateway/entities/license/):
```
curl -Ls get.konghq.com/quickstart | bash -s -- -e "KONG_LICENSE_DATA" \
   -e "KONG_ENFORCE_RBAC=on" \
   -e "KONG_ADMIN_GUI_AUTH=basic-auth" \
   -e "KONG_PASSWORD=kong" \
   -e "KONG_PORTAL=on" \
   -e 'KONG_ADMIN_GUI_SESSION_CONF={"secret":"kong", "cookie_lifetime":300000, "cookie_renew":200000, "cookie_name":"kong_cookie", "cookie_secure":false, "cookie_samesite": "off"}'
```

{% endnavtab %}
{% navtab "Kong Gateway" %}

1. Before enforcing RBAC on your {{site.base_gateway}} instance, we recommend that you create a `super-admin` user first: 

```sh
 curl -i -X POST http://localhost:8001/rbac/users \
   -H 'Kong-Admin-Token:$YOUR_TOKEN' \
   --data name=super-admin \
   --data user_token=$SUPER_ADMIN_USER_TOKEN
```
Creating the `super-admin` username automatically adds the user to the `super-admin` role.

2. Enforce RBAC and reload {{site.base_gateway}}:
```sh
export KONG_ENFORCE_RBAC=on && kong reload
```

This will enable RBAC. From here, you can use the `super-admin` user to manage your RBAC hierarchy. For an in-depth walkthrough of how to do this, review the [Bootstrapping RBAC](/how-to/bootstrap-rbac/) documentation.

{% endnavtab %}
{% endnavtabs %}

You can automate the creation of Admins. For more information, see [creating Admins using the Admin API](/how-to/programatically-create-rbac-admins)




## {{site.mesh_product_name}}

Kubernetes provides its own RBAC system but it does not allow you to: 

* Restrict access to a resource on a specific Mesh. 
* Restrict access based on the content of the policy.

{{site.mesh_product_name}} RBAC works on top of Kubernetes providing two globally scoped (not bound to {{site.mesh_product_name}}) resources to aid in implementing RBAC.

<!--vale off-->
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
<!--vale on -->

## Schema

{% entity_schema %}

## Create an RBAC user

Creating an RBAC user requires RBAC to be enabled for {{site.base_gateway}}, for instructions on how to do that see [Enable RBAC](#enable-rbac).
{% entity_example %}
type: rbac
data:
  name: my-user
  user_token: exampletoken
headers:
  - "Kong-Admin-Token: kong"
{% endentity_example %}