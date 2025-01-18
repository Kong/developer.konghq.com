---
title: Workspaces
content_type: reference
entities:
  - workspace

description: Workspaces provide a way to segment {{site.base_gateway}} entities. Entities in a Workspace are isolated from those in other Workspaces.

tools:
    - admin-api
    - kic
    - deck
    - terraform

tier: enterprise
schema:
    api: gateway/admin-ee
    path: /schemas/Workspace
related_resources:
  - text: Gateway RBAC entity
    url: /gateway/entities/rbac/
  - text: Gateway Group entity
    url: /gateway/entities/group/
  - text: Gateway Admin entity
    url: /gateway/entities/admin/
faqs:
  - q: Do I have to enable Workspaces? 
    a: |
     No, {{site.base_gateway}} Enterprise ships with the `default` Workspace. You can create additional workspaces, but the default Workspace will always remain, and can't be deleted.
  - q: Are there entities that can't exist in a Workspace?
    a: |
      No, all entities must exist inside a Workspace.
  - q: Can I use Workspaces in Konnect?
    a: |
      No. Instead, {{site.konnect_short_name}} offers the more powerful Control Planes and Control Plane Groups to manage entities within an API ecosystem.

  - q: Can a Workspace share a name with another Workspace?
    a: |
      Two Workspaces can't share the same name. However, workspace names are case sensitive - for example, “Payments” and “payments” are not equal and would be accepted as two different Workspaces. 
      We recommend giving Workspaces unique names regardless of letter case to prevent confusion.
  
---


## What is a Workspace?

Workspaces are a way of namespacing {{site.base_gateway}} entities so they can be managed independently. Workspaces work in combination with RBAC to create isolated environments for teams to operate independently of each other. Workspaces can't share entities, like Services, between them, and only Workspace Admins with the correct permissions, in the Workspace, can manage them. 

Workspaces support [multi-tenancy](/gateway/multi-tenancy/) by isolating {{site.base_gateway}} configuration objects. When paired with RBAC, {{site.base_gateway}} administrators can effectively create tenants within the control plane. The Workspace administrators have segregated and secure access to only their portion of the {{site.base_gateway}} configuration in Kong Manager, the Admin API, and the declarative configuration tool decK.


{% mermaid %}
flowchart LR
    subgraph Workspace1 [Workspace-1]
        A(Team A's - Service)
        B(Route)
    end 

    subgraph Workspace2 [Workspace-2]
        C(Team B's - Service)
        D(Route)

    end

    subgraph Workspace3 [Workspace-3]
        E(Team C's - Service)
        F(Route)
    end
    subgraph Gatewayorg [Gateway Organization]
    Workspace1
    Workspace2
    Workspace3
    end
 
{% endmermaid %}

### How does {{site.base_gateway}} resolve entity conflicts between Workspaces?

Routing rules are configured at the data plane level. The data plane routes client traffic based on the configuration applied across all Workspaces. Configuring entities related to routing, such as [Gateway Services](/gateway/entities/service/) and [Routes](/gateway/entities/route/), alter the client traffic routing behavior of the data plane, but {{site.base_gateway}} will always attempt to ensure that routing rules don't contain conflicts. 

To route traffic to the appropriate Workspace, {{site.base_gateway}} uses a conflict detection algorithm.

When a Service or Route is **created** or **modified**, the {{site.base_gateway}} Router checks for the existence of that object before allowing the operation to proceed in this order:

1. If the Service or Route created is totally unique and does not match an existing entity, the new entity is created. 
2. If an existing Service or Route object that matches the one being created is found, a `409 Conflict` error is returned. 
3. If an equivalent Service or a Route is found in a different Workspace, the new entity is created.
4. If an equivalent Service or Route is found in a different Workspace, and the host is a wildcard: 
  a. If the host field matches in both workspaces, a `409 Conflict` error is returned.
  b. If the host field does not match, the new entity can be created.
  c. If the host is an absolute value, a `409 Conflict` error is returned.

## Roles, groups, and permissions

Because Workspaces allow users to control {{site.base_gateway}} entities in isolation, users must have the correct permissions to configure a particular Workspace. Users will require either a Super Admin or Admin role to configure Workspaces. 

The following table details which Workspace permissions each Admin role has:
<!-- vale off -->
{% feature_table %}
columns:
  - title: Super Admin
    key: super_admin
  - title: Admin
    key: admin

features:

  - title: Manage entities within the specified Workspace
    super_admin: true
    admin: true
  - title: Create new Workspaces
    super_admin: true
    admin: false
  - title: Assign and revoke roles to admins
    super_admin: true
    admin: false
  - title: Manage all Workspaces across the organization
    super_admin: true
    admin: false

{% endfeature_table %}
<!-- vale on -->
For more information, see [Roles and permissions](/gateway/entities/rbac/).


## Manage Workspaces with decK 

The following decK flag must be used when interfacing with Workspaces using decK. 

### Manage multiple Workspaces

To manage all Workspaces at once, use the `--all-workspaces` flag with decK:

```sh
deck gateway dump --all-workspaces
```
This will dump your configuration into individual yaml files with the specific Workspace name including `default`. 

You can set a Workspace specifically within a decK file like this: 

```
_format_version: "3.0"
_workspace: default
services:
- name: example_service
```
### Deploy Workspace-specific config 

decK configurations must be deployed on a per-Workspace basis, individually. This is achieved using the `--workspace` flag: 

```sh
deck gateway sync default.yaml --workspace default
```

### Delete a Workspace configuration

decK can't delete Workspaces. However, using `deck gateway reset` in combination with the `--workspace` or `--all-workspaces` flags forces decK to delete the entire configuration inside the Workspace, but not the Workspace itself.


## Schema

{% entity_schema %}

## Set up a Workspace

{% entity_example %}
type: workspace
data:
  name: "my-workspace"
{% endentity_example %}

