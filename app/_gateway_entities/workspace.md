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
     No, {{site.base_gateway}} Enterprise ships with the `default` Workspace, which contains any global {{site.base_gateway}} configuration. 
  - q: Are there entities that can't exist in a Workspace?
    a: |
      Yes, some entities are global meaning they don't exist in any individual Workspace. For example `ca_certificates`.
  - q: Can I use Workspaces in Konnect?
    a: |
      No. Instead, {{site.konnect_short_name}} offers the more powerful Consumer Groups [/gateway/entities/consumer-group/] to organize and categorize of Consumers (users or applications) within an API ecosystem 

  - q: Can a Workspace share a name with another Workspace?
    a: |
      Yes
  
---


## What is a Workspace?

Workspaces are a way of namespacing {{site.base_gateway}} entities so they can be managed independently. Workspaces maintain a unified routing table on the data plane to support client traffic segmentation.

Workspaces can't share entities, like Services, between them. Only users with the correct Workspace permissions can manage entities in a particular Workspace.

Workspaces support multi-tenancy in that they isolate {{site.base_gateway}} configuration objects and when paired with RBAC,  {{site.base_gateway}} administrators can effectively create tenants within the control plane. The Workspace administrators have segregated and secure access to only their portion of the {{site.base_gateway}} configuration in Kong Manager, the Admin API, and the declarative configuration tool decK.

How you design your Workspaces is largely influenced by your specific requirements and the layout of your organization. You may choose to create Workspaces for teams, business units, environments, projects, or some other aspect of your system.


For more information, see [Multi-tenant architecture ](/gateway/multi-tenancy).
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



### How does {{site.base_gateway}} resolve entity conflicts between Workspaces?

Routing rules are configured at the data plane level. The data plane routes client traffic based on the configuration applied across all Workspaces. Configuring entities related to routing, such as [Gateway Services](/gateway/entities/service/) and [Routes](/gateway/entities/route/), alter the client traffic routing behavior of the data plane, but {{site.base_gateway}} will always attempt to ensure that routing rules don't contain conflicts. 

To route traffic to the appropriate Workspace, {{site.base_gateway}} uses a conflict detection algorithm.

When a Service or Route is **created** or **modified**, the {{site.base_gateway}} Router does the following: 

1. If no matches found: The operation proceeds.
2. If a Service or Route match is found in the Workspace that matches the one listed in the request: The operation proceeds
3. If a Service or Route match is found in a different Workspace: 
  * If the matching Service or Route has no host value: issue a `409 Conflict` error
  * If the host is a wildcard:
        * If it matches, issue a `409 Conflict` error
        * If it doesn't match, the operation proceeds.
  * If the host is an absolute value: Issue a `409 Conflict` error.

## Roles, groups, and permissions

Because Workspaces allow users to control {{site.base_gateway}} entities in isolation, users must have the correct permissions to configure a particular Workspace. Users will require either a Super Admin or Admin role to configure Workspaces. 

The following table details which Workspace permissions each Admin role has:

| Permission | Super Admin | Admin |
|-----------|---------------|-------|
| Manage entities within the specified Workspace |  ✅  |  ✅  |
| Create new Workspaces |  ✅  |  ❌  |
| Assign and revoke roles to admins |  ✅  |  ❌  |
| Manage all Workspaces across the organization |  ✅  |  ❌  | 

For more information, see [Roles and permissions](/gateway/roles-and-permissions).



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
### Deploy Workspace-specific config 

decK configurations must be deployed on a per-Workspace basis, individually. This is achieved using the `--workspace` flag: 

`deck gateway sync default.yaml --workspace default`


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

