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

faqs:
  - q: Do I have to enable Workspaces? 
    a: |
      {{site.base_gateway}} ships with Workspaces, the default Workspace is named `default` and contains any global {{site.base_gateway}} configuration. 
  - q: Are there entities that can't exist in a Workspace?
    a: |
      Yes, some entities are global meaning they don't exist in any individual Workspace. For example `ca_certificates`.
  - q: Can I use Workspaces in Konnect?
    a: |
      Konnect offers access to the more power Consumer Groups [/gateway/entities/consumer-group/]

  - q: Can a Workspace share a name with another Workspace?
    a: |
      Individual Workspaces can be managed using [decK](/deck/). However, decK can't manage multiple Workspaces at the same time, or delete Workspaces.
  
---


## What is a Workspace?

Workspaces are a way of namespacing {{site.base_gateway}} entities so they can be managed indepdently. Workspaces maintain a unified routing table on the data plane to support client traffic segmentation.

The data plane routes client traffic based on the configuration applied across all Workspaces. Configuring entities related to routing such as Services and Routes alter the client traffic routing behavior of the data plane but {{site.base_gateway}} will always attempt to ensure that routing rules don't contain conflicts. 

{% mermaid %}
flowchart LR
    subgraph Workspace1 [Workspace-1]
        A(Team A's Service)
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

## Schema

{% entity_schema %}


### Conflict detection algorithm

Routing rules are configured at the data plane level. To ensure that traffic can be routed to the appropriate Workspace, {{site.base_gateway}} uses a conflict detection algorithm. The algorithm can be explained like this: 

When a Service or Route is **created** or **modified**, the {{site.base_gateway}} Router performs the following sequence to check for duplicate or matchine rules: 

1. If no matches found: The operation proceeds.
2. If a match is found in the same Workspace: The operation proceeds
3. If a match is found in a different Workspace: 
  * If the matching Service or Route has no host value: issue a `409 Conflict` error
  * If the host is a wildcard:
        * if it matches issue a `409 Conflict` error
        * If it doesn't match, the operation proceeds.
  * If the host is an absolute value: Issue a `409 Conflict` error.

## Roles, groups, and permissions

Workspaces allow users to control {{site.base_gateway}} entities in isolation. Individual permissions for Workspaces are configured using RBAC. Roles are sets of permissions that can be assigned to admins and users and can be specific to a Workspace. There are two types of Admin roles in {{site.base_gateway}}: **Super Admin** and **Admin**. 

A super admin within the contexts of Workspaces can perform the following actions: 
* Create new Workspaces
* Assign and revoke roles to admins
* Manage all Workspaces across the organization

An admin within the context of Workspaces can only manage entities within the specified Workspace. 

For more information see [Roles and permissions](/gateway/roles-and-permissions)


## Multi-tenant Control Plane and Data Plane

Multi-tenancy is supported with Workspaces. Workspaces provide an isolation of {{site.base_gateway}} configuration objects while maintaining a unified routing table on the data plane to support client traffic. You can create Workspaces for teams, business units, environments, projects or other aspects of your system. 

When pairing Workspaces with RBAC, {{site.base_gateway}} administrators can effectively create tenants within the control plane. The {{site.base_gateway}} administrator creates Workspaces and assigns administrators to them. The Workspace administrators have segregated and secure access to only their portion of the {{site.base_gateway}} configuration in Kong Manager, the Admin API, and the declarative configuration tool decK.


How you design your Workspaces is largely influenced by your specific requirements and the layout of your organization. You may choose to create Workspaces for teams, business units, environments, projects, or some other aspect of your system.


For more information, view [Multi-tenant architecture ](/gateway/multi-tenancy)

### Manage multiple Workspaces with decK 

The following decK flags must be used when interfacing with Workspaces using decK. 

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
### Deploying Workspace-specific config 

Configurations deployed with decK must be deployed on a per-Workspace basis, indvidually. This is achieved using the `--workspace` flag: 

`deck gateway sync default.yaml --workspace default`


### Delete Workspace configuration

decK can't delete Workspaces. However, using `deck gateway reset` in combination with the `--workspace` or `--all-workspaces` flags forces decK to delete the entire configuration inside the Workspace, but not the Workspace itself.


## Configure a Workspace

{% entity_example %}
type: workspace
data:
  name: "my-workspace"
{% endentity_example %}

