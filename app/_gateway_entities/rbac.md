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
---

## What is RBAC?

Roles and permissions are administered using the {{site.base_gateway}} RBAC entity. Roles are sets of permissions that can be assigned to admins and users and can be specific to a [Workspace](/gateway/entities/workspace). Permissions are types of rules that effect {{site.base_gateway}} resources which are the core components of an API. RBAC and {{site.base_gateway}} follow the following core principle: 

* In {{site.base_gateway}} there are users
* Every user has a Role
* Roles are assigned Permissions
* Every Role belongs to a Group
* A Group is a collection of Roles

{{site.base_gateway}} uses a precedence model, from most specificity to least specificity, to determine if a user has access to an endpoint.


## What are Permissions?

Each role may have a number of permissions that determine its ability to interact with a resource. The RBAC system provides a level of granularity that works by assigning actions on a per-resource level using the principle of least privilege.This means that a user can have **read** permissions on `/foo/bar` and **write** permissions on `/foo/bar/far`. 

{% include entities/permissions-table.md %}

## RBAC precedence order

{{site.base_gateway}} uses a precedence model when checking if a user has sufficient permissions to access an endpoint, a resource, or a Workspace. This information is collected from the various permissions or applied across the roles and groups assigned to a user. 

For each request, {{site.base_gateway}} checks for an RBAC rule assigned to the requesting user in the following order:

1. Allow or deny permissions against the current endpoint in the current Workspace.
2. Wildcard allow or deny permissions against the current endpoint in any Workspace.
3. Allow or deny permissions against any endpoint (wildcard) in the current Workspace.
4. Wildcard allow or deny permissions against any endpoint in any Workspace. 

If {{site.base_gateway}} finds a matching permission for the current user, endpoint or Workspace it allows or denies the request based on it. Once {{site.base_gateway}} finds an applicable rule, the algorithm stops and doesn't check less specific permissions. If no permission is found (approval or denial) the request is denied. 

## Role configuration

This diagram helps explain how individual workspace roles and cross-workspace roles interact. 

{% mermaid %}
flowchart LR
    subgraph team-a-roles [Team A Roles]
        Admin2["Admin"]
        RO2["Read Only"]
        C2["Custom"]
    end 
    subgraph team-b-roles [Team B Roles]
        Admin3["Admin"]
        RO3["Read Only"]
        C3["Custom"]
    end 
    subgraph cross-workspace-roles [Platform Admins]
        SA["Super Admin"]
        Admin["Admin"]
        RO["Read Only"]
        C["Custom"]
    end 

    subgraph defaultWorkspace [Default Workspace]
        routes["Route"]
        service["Service"]
        plugin["Plugin"]
    end

    subgraph teamAworkspace [Team A Workspace]
        routes2["Route"]
        service2["Service"]
        plugin2["Plugin"]
    end
    subgraph teamBworkspace [Team B Workspace]
       routes3["Route"]
        service3["Service"]
        plugin3["Plugin"]
    end

    team-a-roles --> teamAworkspace
    team-b-roles --> teamBworkspace
    cross-workspace-roles --> defaultWorkspace
    cross-workspace-roles --> teamAworkspace
    cross-workspace-roles --> teamBworkspace


{% endmermaid %}


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
      A set of permissions

  - title: "`role_source`"
    description: |
      Specifies where the user role is defined, either locally or through an identity provider (IdP).

  - title: "`role_endpoint`"
    description: |
      The endpoint associated with the RBAC role.

  - title: "`role_entity`"
    description: |
      The ID of the entity associated with the RBAC role. For example: The role developer has one `role_entity` attached to a UUID. 

{% endfeature_table %}



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
  admin-api:
    - "Kong-Admin-Token: $ADMIN_TOKEN"
{% endentity_example %}