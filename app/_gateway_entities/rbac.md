---
title: RBAC
content_type: reference
products:
  - gateway

tools:
    - admin-api
entities:
  - rbac
tags:
  - access-control
  - authorization
  - security
description: RBAC manages {{site.base_gateway}} roles and permissions for Kong Manager and the Admin API.
schema:
    api: gateway/admin-ee
    path: /schemas/RbacUser

related_resources:
  - text: Gateway Workspace entity
    url: /gateway/entities/workspace/
  - text: Gateway Vault entity
    url: /gateway/entities/vault/
  - text: Gateway Group entity
    url: /gateway/entities/group/
  - text: Gateway Admin entity
    url: /gateway/entities/admin/
  - text: Create a Super Admin
    url: /how-to/create-a-super-admin/
  - text: Create an RBAC user with custom permissions
    url: /how-to/configure-rbac-user-in-kong-gateway/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: "{{site.konnect_short_name}} roles and teams"
    url: /konnect-platform/teams-and-roles/

api_specs:
    - gateway/admin-ee

works_on:
  - on-prem

faqs:
  - q: What happens if {{site.base_gateway}} starts with `enforce_rbac=on` but with no password set?
    a: |
      If you start {{site.base_gateway}} with RBAC enabled but with no password set, the super admin user won't be created and you won't have access to the Gateway through the Admin API or Kong Manager.
      Your Gateway will be locked and you'll be unable to configure it.

      If starting {{site.base_gateway}} with `enforce_rbac=on`, you **must** set `KONG_PASSWORD` during startup. Doing so bootstraps a super admin user named `kong_admin`, which you can use to interact with Kong Manager, or you can pass the password as `Kong-Admin-Token` header to the API.

      To fix this issue in an existing Gateway instance, you have to disable RBAC and manually create an admin:
      1. Set `enforce_rbac=off` in your `kong.conf` file or via an environment variable.
      1. Reload your Gateway instance.
      1. Create a [super admin](/how-to/create-a-super-admin/) with a username and password, making sure to give your admin super-admin privileges so that they can create and manage other users.
      1. Set `enforce_rbac=on` in your `kong.conf` file or via an environment variable.
      1. Reload your Gateway instance again.
      
      You can now log in using the admin you created.
---

## What is RBAC?

Roles and permissions are administered using the {{site.base_gateway}} RBAC entity, which stands for Role-Based Access Control. Roles are sets of permissions that can be assigned to admins and users and can be specific to a [Workspace](/gateway/entities/workspace/). Permissions are types of rules that affect {{site.base_gateway}} resources, which are the core components of an API. 

RBAC in {{site.base_gateway}} conforms to the following core principles: 

* In {{site.base_gateway}} there are users
* Every user has a role
* Roles are assigned permissions
* A group is a collection of roles

{{site.base_gateway}} uses a [precedence model](#rbac-precedence-order), from most specificity to least specificity, to determine if a user has access to an endpoint.

## Users, roles, and permissions

Each role may have a number of permissions that determine its ability to interact with a resource. The RBAC system provides a level of granularity that works by assigning actions on a per-resource level using the principle of least privilege. This means that a user can have **read** permissions on `/foo/bar` and **write** permissions on `/foo/bar/far`. 

### User types in {{site.base_gateway}}

{{site.base_gateway}} has the following RBAC user types:

{% table %}
columns:
  - title: User type
    key: user
  - title: Purpose
    key: purpose
  - title: Most useful for
    key: use
  - title: What tools does it have access to?
    key: tools
rows:
  - user: Admin
    purpose: |
      An admin belongs to a Workspace and has at least one role with a set of permissions. If an admin is in a Workspace without a role, they can’t see or interact with anything. <br><br>
      Admins can manage entities inside Workspaces, including users and their roles.
    use: "Personal administrative accounts for {{site.base_gateway}} and Kong Manager"
    tools: |
      * Admin API
      * Kong Manager
      * decK
  - user: Super admin
    purpose: | 
      Specialized admins with the ability to:<br><br>
      * Manage all Workspaces
      * Further customize permissions
      * Create entirely new roles
      * Invite or deactivate admins
      * Assign or revoke admin roles
    use: Managing RBAC
    tools: |
      * Admin API
      * Kong Manager
      * decK
  - user: User
    purpose: |
      RBAC users without administrator permissions. 
      They have access to manage {{site.base_gateway}}, but can’t adjust teams, groups, or user permissions.
    use: "Service accounts for {{site.base_gateway}}, used as part of an automated process"
    tools: |
      * Admin API
      * decK
{% endtable %}

{% include_cached entities/permissions-table.md %}

### Kong Manager authentication

When [Kong Manager authentication is enabled](/gateway/kong-manager/configuration/#enable-authentication), RBAC must be enabled to enforce authorization rules. Otherwise, anyone who can log in
to Kong Manager can perform any operation available on the Admin API.

## RBAC precedence order

{{site.base_gateway}} uses a precedence model when checking if a user has sufficient permissions to access an endpoint, a resource, or a Workspace. This information is collected from the various permissions or applied across the roles and groups assigned to a user. 

For each request, {{site.base_gateway}} checks for an RBAC rule assigned to the requesting user in the following order:

1. Allow or deny permissions against the current endpoint in the current Workspace.
2. Wildcard allow or deny permissions against the current endpoint in any Workspace.
3. Allow or deny permissions against any endpoint (wildcard) in the current Workspace.
4. Wildcard allow or deny permissions against any endpoint in any Workspace. 

If {{site.base_gateway}} finds a matching permission for the current user, endpoint, or Workspace, it allows or denies the request based on it. Once {{site.base_gateway}} finds an applicable rule, the algorithm stops and doesn't check less specific permissions. If no permission is found (approval or denial), the request is denied. 

### Wildcards in endpoint permissions

To create an endpoint permission via `/rbac/roles/:role/endpoints`, 
you must pass the parameters below, all of which can be replaced by a `*` character:

* `endpoint`: `*` matches **any endpoint**
* `workspace`: `*` matches **any workspace**
* `actions`: `*` evaluates to **all actions—read, update, create, delete**

`endpoint`, in addition to a single `*`, also accepts `*`
within the endpoint itself, replacing a URL segment between `/`. For example,
all of the following are valid endpoints:

- `/rbac/*`: where `*` replaces any possible segment, for example `/rbac/users` 
and `/rbac/roles`
- `/services/*/plugins`: `*` matches any service name or ID

{:.info}
> **Note** `*` **is not** a generic, shell-like, glob pattern.
> Therefore, `/rbac/*` or `/workspaces/*` alone don't match all of the RBAC and Workspaces endpoints. 
> <br><br>
> For example, to cover all of the RBAC API, you would have to define permissions for the following endpoints:
>
> - `/rbac/*`
> - `/rbac/*/*`
> - `/rbac/*/*/*`
> - `/rbac/*/*/*/*`
> - `/rbac/*/*/*/*/*`

If `workspace` is omitted, it defaults to the current request's workspace. For
example, a role-endpoint permission created with `/teamA/roles/admin/endpoints`
is scoped to workspace `teamA`.

#### Wildcards in entity permissions

For entity permissions created via `/rbac/roles/:role/entities`,
the following parameter accepts a `*` character:

- `entity_id`: `*` matches **any entity ID**

## Role configuration

This diagram helps explain how individual Workspace roles and cross-Workspace roles interact:

<!--vale off -->

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

<!--vale on -->

## RBAC entities

The following table describes the different RBAC entities:


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

{% navtabs "enable-rbac" %}
{% navtab "Quickstart" %}

This command creates a {{site.base_gateway}} instance, sets the Kong super admin password to `kong`, and sets up RBAC.
This command assumes you have a [valid license in the environment variable `KONG_LICENSE_DATA`](/gateway/entities/license/):
```
curl -Ls get.konghq.com/quickstart | bash -s -- -e "KONG_LICENSE_DATA" \
   -e "KONG_ENFORCE_RBAC=on" \
   -e "KONG_ADMIN_GUI_AUTH=basic-auth" \
   -e "KONG_PASSWORD=kong" \
   -e 'KONG_ADMIN_GUI_SESSION_CONF={"secret":"kong", "cookie_lifetime":300000, "cookie_renew":200000, "cookie_name":"kong_cookie", "cookie_secure":false, "cookie_samesite": "off"}'
```

{% endnavtab %}
{% navtab "Advanced" %}

1. Before enforcing RBAC on your {{site.base_gateway}} instance, create a `super-admin` user: 

    ```sh
    curl -i -X POST http://localhost:8001/rbac/users \
      --data name=super-admin \
      --data user_token=$SUPER_ADMIN_USER_TOKEN
    ```
    Creating the `super-admin` username automatically adds the user to the `super-admin` role.

2. In the location where {{site.base_gateway}} is running, enable RBAC with the auth method of your choice. 

    Set the following parameters in `kong.conf`: 

    * `enforce_rbac`: Set to `on` to enable RBAC.
    * `admin_gui_auth`: Required for Kong Manager. Set this value to the desired authentication, for example `basic-auth`.
    * `admin_gui_session_conf`: Required for Kong Manager. Adds a session secret.

    For example, to set these parameters using environment variables, run:
    ```sh
    export KONG_ENFORCE_RBAC=on && \
    export KONG_ADMIN_GUI_SESSION_CONF='{"secret":"kong", "cookie_lifetime":300000, "cookie_renew":200000, "cookie_name":"kong_cookie", "cookie_secure":false, "cookie_samesite": "off"}' && \
    export KONG_ADMIN_GUI_AUTH=basic-auth
    ```

3. Restart or reload {{site.base_gateway}}.

{% endnavtab %}
{% endnavtabs %}

From here, you can use the `super-admin` user to manage your RBAC hierarchy. For an in-depth walkthrough of how to do this, review the [Enable RBAC with the Admin API](/how-to/enable-rbac-with-admin-api/) documentation.

{:.info}
> The `super-admin` user only has permissions to manage RBAC. You must [create other admins or users](/api/gateway/admin-ee/#/operations/post-rbac-users) to be able to interact with other {{site.base_gateway}} entities, such as Gateway Services and Routes.

## Schema

{% entity_schema %}