---
title: "Control Plane Groups"
content_type: reference
layout: reference
breadcrumbs: 
  - /konnect/
products:
    - gateway
works_on:
  - konnect
tools:
  - admin-api
  - konnect-api
min_version:
    gateway: '3.5'
tags:
  - control-plane
  - gateway-manager

description: A Control Plane Group is a read-only Control Plane that combines configuration from its members, which are standard Control Planes.

faqs:
  - q: How is a Control Plane Group different from a standard Control Plane?
    a: In a standard Control Plane, each team manages its own Data Plane nodes. In a Control Plane Group, multiple Control Planes are combined, and their configurations are merged and applied to shared Data Plane nodes.

  - q: Can teams still manage their own configurations in a Control Plane Group?
    a: Yes. Each team continues to administer its own Control Plane, but configurations are merged and pushed to shared Data Plane nodes through the Control Plane Group.

  - q: How many Control Planes can be in a Control Plane Group?
    a: A Control Plane Group can have up to 256 Control Planes, with a limit of 50 added or removed at a time.

  - q: Can a standard Control Plane be part of more than one Control Plane Group?
    a: Yes, a standard Control Plane can belong to up to 5 Control Plane Groups.

  - q: Can members of a Control Plane Group have their own Data Plane nodes?
    a: No. Only the Control Plane Group itself manages Data Plane nodes. Member Control Planes must not have any connected Data Plane nodes when added.

  - q: What happens if multiple Control Planes have entities with the same name or ID?
    a: This creates a conflict that must be resolved. All entities in a Control Plane Group must have unique names and IDs.

  - q: Are there any special behaviors for specific entities in a Control Plane Group?
    a: Yes. For example, a Consumer's credentials become valid across the group, and Vaults from one Control Plane can be accessed by others in the group. Global plugins affect the entire group.

  - q: How do entity associations work in a Control Plane Group?
    a: Associations by ID are constrained to their originating Control Plane. Associations by string can span multiple member Control Planes.

  - q: Can a Control Plane Group be configured directly?
    a: No. Control Plane Groups are read-only. Configuration changes must be made through a member Control Plane. The only exceptions are generating or uploading Data Plane node certificates and connecting Data Plane nodes.
  - q: How do I migrate a Control Plane configuration into a Control Plane Group?
    a: |
      Using [decK](/deck/), you can export the configuration of the Control Plane and sync it with the group: 
      1. Export the configuration of the old Control Plane using `deck gateway dump`:
        ```
         deck gateway dump \
            -o old-group.yaml \
            --konnect-token $KONNECT_TOKEN \
            --konnect-control-plane-name old-group
        ```
      2. Sync the configuration to the Control Plane Group:
        ```
         deck gateway sync old-group.yaml \
            --konnect-token $KONNECT_TOKEN \
            --konnect-control-plane-name CP1
        ```
  - q: Can a Control Plane Group contain another Control Plane Group?
    a: No. A Control Plane Group cannot be a member of another Control Plane Group.

  - q: Can {{site.kic_product_name}} Control Planes join a Control Plane Group?
    a: No. {{site.kic_product_name}} Control Planes cannot be part of a Control Plane Group.

  - q: What happens if Control Plane configurations conflict in a group?
    a: Even if configurations conflict and can’t be merged, the Control Plane Group is still created. Conflict detection only occurs after a Data Plane node is connected.

related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
#  - text: "{{site.base_gateway}} debugging"
#    url: /gateway/debug/
---

## What is a Control Plane Group?

A Control Plane Group is a read-only Control Plane that combines configuration from
its members, which are standard Control Planes. All of the standard Control Planes within a 
Control Plane Group share the same cluster of Data Plane nodes. 


The following diagram illustrates using a Control Plane Group for a federated platform administrator model:
<!--vale off-->
{% mermaid %}
flowchart LR
  A(Team Blue)
  B(Team Green)
  C(Control Plane Blue)
  D(Control Plane Purple
    global config)
  E(Control Plane Green)
  F(Data Plane nodes)
  G(Data Plane nodes)

  A -- deck gateway sync --> C
  B -- deck gateway sync --> E

  subgraph id1 ["`**KONNECT ORG**`"]
    subgraph id2 [<br>Control Plane Group Steel]
    C
    D
    E
    end
  end

  id2 -- Get config from 
  Control Plane Group
  Steel--> F & G

  subgraph id3 [Data centers]
  F
  G
  end
{% endmermaid %}
<!--vale on-->

In this diagram:
* Team Blue configures Control Plane Blue, which is then combined with the configuration from Team Green.
* The Control Plane Group also contains Control Plane Purple, which is managed by a central platform team.
* The central platform team manages global plugin configuration in Control Plane Purple, which is added to any configuration that teams Blue and Green provide.

## How do I create a Control Plane Group?

In {{site.konnect_short_name}}, Control Plane Groups can be created using the [Control Planes API](/api/konnect/control-planes/).

<!--vale off-->
{% control_plane_request %}
method: POST
url: /v2/control-planes
status_code: 201
headers:
  - 'Authorization: Bearer $KONNECT_TOKEN'
  - 'Content-Type: application/json'
body:
  name: CPG
  cluster_type: CLUSTER_TYPE_CONTROL_PLANE_GROUP
{% endcontrol_plane_request %}
<!--vale on-->

## How do I attach Control Planes to a Control Plane Group?

Once you have a Control Plane Group, you can add Control Planes to the Group using the {{site.konnect_short_name}} UI or [API](/api/konnect/control-planes/#/operations/post-control-planes-id-group-memberships-add).
<!--vale off-->

{% control_plane_request %}
method: POST
url: /v2/control-planes/$CONTROL_PLANE_GROUP_ID/group-memberships/add
status_code: 200
headers:
  - 'Authorization: Bearer $KONNECT_TOKEN'
  - 'Content-Type: application/json'
body:
  members:
    - id: 062e2f2c-0f42-4938-91b4-f73f399260f5
{% endcontrol_plane_request %}
<!--vale on-->

## Configuring Gateway entities

There are some special cases and behaviors to note for [Gateway entities](/gateway/entities/) in a Control Plane Group.

All entities in a Control Plane Group must have unique names and IDs. 
For example, if two members of a Control Plane Group both have a Service named `example_service`, 
it will cause a [conflict](/gateway/control-plane-groups/#control-plane-conflicts/) which must be resolved to restore function.

A number of {{site.base_gateway}} entities can be associated with each other.
Based on the type of association, the behavior of these associated entities in a Control Plane Group follows one of these patterns:
* If the entity relationship is referenced by ID, associations remain constrained to the behavior of the individual Control Plane.
* If the entity relationship is referenced by a string, then associations across one or more member Control Planes are possible.

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Associated Entity
    key: associated
  - title: Type of Association
    key: type
rows:
  - entity: Service
    associated: Route
    type: By ID
  - entity: Upstream
    associated: Target
    type: By ID
  - entity: Certificate
    associated: SNI
    type: By ID
  - entity: Consumer
    associated: Credential
    type: By ID
  - entity: Consumer
    associated: Consumer Group
    type: By ID
  - entity: Consumer
    associated: ACL group
    type: By string
  - entity: Consumer Groups
    associated: Plugin
    type: By string
  - entity: Plugin (Non-Global)
    associated: Service, Route, Consumer
    type: By ID
  - entity: Global plugin
    associated: Control Plane
    type: By Control Plane
  - entity: Key
    associated: Key set
    type: By ID
  - entity: Vault
    associated: Control plane
    type: By Control Plane
  - entity: deGraphQL Route
    associated: Service
    type: By ID
  - entity: GraphQL Rate Limiting cost decoration
    associated: Service
    type: By ID
{% endtable %}

The {{site.base_gateway}} resource associated with an entity must be part of the same standard Control Plane as the entity.

### Entity-specific behavior exceptions

The following are exceptions to the entity behavior:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Behavior in Control Plane Groups
    key: behavior
rows:
  - entity: Consumers
    behavior: >-
      A Consumer from a standard Control Plane becomes a Consumer of the Control Plane Group once the Control Plane joins the group.<br><br>
      The Consumer's authentication credentials also become valid for the Control Plane Group.<br><br>
      However, a Consumer ID from one member cannot be used for authorization in another member.
  - entity: Consumer Groups
    behavior: >-
      Only Consumers from the same Control Plane can be added to a Consumer Group.<br><br>
      In the Rate Limiting Advanced plugin, the configuration field [`config.consumer_groups`](/plugins/rate-limiting-advanced/reference/#schema--config-consumer-groups) can reference Consumer Groups from other Control Plane Group members.
  - entity: Vaults
    behavior: >-
      Vault prefixes must be unique.<br><br>
      When a Vault from a standard Control Plane joins a Control Plane Group, it becomes available to the whole group.<br><br>
      Entity fields can reference secrets in Vaults from other members of the Control Plane Group.
  - entity: Global plugins
    behavior: |
      A globally scoped plugin in a standard Control Plane remains globally scoped within the Control Plane Group.<br><br>
      It affects the entire group. For example, you cannot install two instances of the Rate Limiting plugin in the same Control Plane Group.<br><br>
      
      {:.info}
       > **Note:** If you want to limit which users can apply global plugins, add all global plugins into a single Control Plane, and then grant access to only your limited set of users. If any other member Control Planes add a global plugin to their configuration, a conflict will result and prevent the changed configuration from being applied.

{% endtable %}

## Control Plane conflicts

When combining configurations from individual Control Planes into a Control Plane Group you may receive conflict errors in {{site.konnect_short_name}}, for example: 

```sh
Conflicts have been detected between these Control Planes: 
CONTROL-PLANE-EXAMPLE
CONTROL-PLANE-ANOTHER-EXAMPLE
```
{:.no-copy-code}

The Control Plane won't update a Data Plane configuration until the conflict is resolved. 
Review the following table of common issues and potential fixes:

{% table %}
columns:
  - title: Conflict
    key: conflict
  - title: Description
    key: description
  - title: Action
    key: action
rows:
  - conflict: Duplicate names across Control Plane Group members
    description: Same entity name exists in multiple member Control Planes.
    action: Remove or rename one of the conflicting entities.
  - conflict: Shared credentials across Control Plane Group members
    description: Credentials from one member can authenticate across the group.
    action: Remove shared credentials if cross-access is not desired.
  - conflict: ACL group names across Control Plane Group members
    description: ACL group names are shared across members.
    action: Remove or rename duplicate ACL groups if isolation is needed.
  - conflict: Consumers across Control Plane Group members
    description: Consumer names are shared across members.
    action: Remove or rename duplicates if isolation is needed.
  - conflict: Consumer groups across Control Plane Group members
    description: Consumer group names are shared across members.
    action: Remove or rename duplicates if isolation is needed.
  - conflict: decK dump with duplicate names found
    description: "`deck gateway dump` fails on duplicate names."
    action: Remove or rename duplicate entities.
  - conflict: Reference by name vs reference by ID
    description: ID-based references don’t work across Control Planes, string-based ones do.
    action: Use string references, or remove conflicting entities.
  - conflict: Multiple instances of the same global plugin
    description: Only one global plugin instance is allowed in the group.
    action: Remove duplicates or assign unique instance names.
{% endtable %}
