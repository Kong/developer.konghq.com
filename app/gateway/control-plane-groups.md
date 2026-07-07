---
title: "Control plane groups"
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

description: A control plane group is a read-only control plane that combines configuration from its members, which are standard control planes.

faqs:
  - q: How is a control plane group different from a standard control plane?
    a: In a standard control plane, each team manages its own Data Plane nodes. In a control plane group, multiple control planes are combined, and their configurations are merged and applied to shared Data Plane nodes.

  - q: Can teams still manage their own configurations in a control plane group?
    a: Yes. Each team continues to administer its own control plane, but configurations are merged and pushed to shared Data Plane nodes through the control plane group.

  - q: How many control planes can be in a control plane group?
    a: A control plane group can have up to 256 control planes, with a limit of 50 added or removed at a time.

  - q: Can a standard control plane be part of more than one control plane group?
    a: Yes, a standard control plane can belong to up to 5 control plane groups.

  - q: Can members of a control plane group have their own Data Plane nodes?
    a: No. Only the control plane group itself manages Data Plane nodes. Member control planes must not have any connected Data Plane nodes when added.

  - q: What happens if multiple control planes have entities with the same name or ID?
    a: This creates a conflict that must be resolved. All entities in a control plane group must have unique names and IDs.

  - q: Are there any special behaviors for specific entities in a control plane group?
    a: Yes. For example, a Consumer's credentials become valid across the group, and Vaults from one control plane can be accessed by others in the group. Global plugins affect the entire group.

  - q: How do entity associations work in a control plane group?
    a: Associations by ID are constrained to their originating control plane. Associations by string can span multiple member control planes.

  - q: Can a control plane group be configured directly?
    a: No. control plane groups are read-only. Configuration changes must be made through a member control plane. The only exceptions are generating or uploading Data Plane node certificates and connecting Data Plane nodes.
  - q: How do I migrate a control plane configuration into a control plane group?
    a: |
      Using [decK](/deck/), you can export the configuration of the control plane and sync it with the group: 
      1. Export the configuration of the old control plane using `deck gateway dump`:
        ```
         deck gateway dump \
            -o old-group.yaml \
            --konnect-token $KONNECT_TOKEN \
            --konnect-control-plane-name old-group
        ```
      2. Sync the configuration to the control plane group:
        ```
         deck gateway sync old-group.yaml \
            --konnect-token $KONNECT_TOKEN \
            --konnect-control-plane-name CP1
        ```
  - q: Can a control plane group contain another control plane group?
    a: No. A control plane group cannot be a member of another control plane group.

  - q: Can {{site.kic_product_name}} control planes join a control plane group?
    a: No. {{site.kic_product_name}} control planes cannot be part of a control plane group.

  - q: What happens if control plane configurations conflict in a group?
    a: Even if configurations conflict and can’t be merged, the control plane group is still created. Conflict detection only occurs after a Data Plane node is connected.

related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
#  - text: "{{site.base_gateway}} debugging"
#    url: /gateway/debug/
---

## What is a control plane group?

A control plane group is a read-only control plane that combines configuration from
its members, which are standard control planes. All of the standard control planes within a 
control plane group share the same cluster of Data Plane nodes. 


The following diagram illustrates using a control plane group for a federated platform administrator model:
<!--vale off-->
{% mermaid %}
flowchart LR
  A(Team Blue)
  B(Team Green)
  C(Control plane Blue)
  D(Control plane Purple
    global config)
  E(Control plane Green)
  F(Data Plane nodes)
  G(Data Plane nodes)

  A -- deck gateway sync --> C
  B -- deck gateway sync --> E

  subgraph id1 ["`**KONNECT ORG**`"]
    subgraph id2 [<br>control plane group Steel]
    C
    D
    E
    end
  end

  id2 -- Get config from 
  control plane group
  Steel--> F & G

  subgraph id3 [Data centers]
  F
  G
  end
{% endmermaid %}
<!--vale on-->

In this diagram:
* Team Blue configures control plane Blue, which is then combined with the configuration from Team Green.
* The control plane group also contains control plane Purple, which is managed by a central platform team.
* The central platform team manages global plugin configuration in control plane Purple, which is added to any configuration that teams Blue and Green provide.

## How do I create a control plane group?

In {{site.konnect_short_name}}, control plane groups can be created using the [control planes API](/api/konnect/control-planes/).

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

## How do I attach control planes to a control plane group?

Once you have a control plane group, you can add control planes to the Group using the {{site.konnect_short_name}} UI or [API](/api/konnect/control-planes/#/operations/post-control-planes-id-group-memberships-add).
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

There are some special cases and behaviors to note for [Gateway entities](/gateway/entities/) in a control plane group.

All entities in a control plane group must have unique names and IDs. 
For example, if two members of a control plane group both have a Service named `example_service`, 
it will cause a [conflict](/gateway/control-plane-groups/#control-plane-conflicts/) which must be resolved to restore function.

A number of {{site.base_gateway}} entities can be associated with each other.
Based on the type of association, the behavior of these associated entities in a control plane group follows one of these patterns:
* If the entity relationship is referenced by ID, associations remain constrained to the behavior of the individual control plane.
* If the entity relationship is referenced by a string, then associations across one or more member control planes are possible.

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
    associated: Control plane
    type: By control plane
  - entity: Key
    associated: Key set
    type: By ID
  - entity: Vault
    associated: Control plane
    type: By control plane
  - entity: deGraphQL Route
    associated: Service
    type: By ID
  - entity: GraphQL Rate Limiting cost decoration
    associated: Service
    type: By ID
{% endtable %}

The {{site.base_gateway}} resource associated with an entity must be part of the same standard control plane as the entity.

### Entity-specific behavior exceptions

The following are exceptions to the entity behavior:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Behavior in control plane groups
    key: behavior
rows:
  - entity: Consumers
    behavior: >-
      A Consumer from a standard control plane becomes a Consumer of the control plane group once the control plane joins the group.<br><br>
      The Consumer's authentication credentials also become valid for the control plane group.<br><br>
      However, a Consumer ID from one member cannot be used for authorization in another member.
  - entity: Consumer Groups
    behavior: >-
      Only Consumers from the same control plane can be added to a Consumer Group.<br><br>
      In the Rate Limiting Advanced plugin, the configuration field [`config.consumer_groups`](/plugins/rate-limiting-advanced/reference/#schema--config-consumer-groups) can reference Consumer Groups from other control plane group members.
  - entity: Vaults
    behavior: >-
      Vault prefixes must be unique.<br><br>
      When a Vault from a standard control plane joins a control plane group, it becomes available to the whole group.<br><br>
      Entity fields can reference secrets in Vaults from other members of the control plane group.
  - entity: Global plugins
    behavior: |
      A globally scoped plugin in a standard control plane remains globally scoped within the control plane group.<br><br>
      It affects the entire group. For example, you cannot install two instances of the Rate Limiting plugin in the same control plane group.<br><br>
      
      {:.info}
       > **Note:** If you want to limit which users can apply global plugins, add all global plugins into a single control plane, and then grant access to only your limited set of users. If any other member control planes add a global plugin to their configuration, a conflict will result and prevent the changed configuration from being applied.

{% endtable %}

## Limitation

If a Consumer is defined in one member control plane and the request it authorizes hits a Route or Gateway Service defined in a different member control plane of the same control plane group, {{site.observability}} can't resolve the Consumer across control planes. 
In this case, the Consumer displays as `(deleted)` in Requests, Explorer, and Dashboards, even though it exists and successfully authorized the request. 
This happens because {{site.observability}} assumes all the data for a request comes from a single control plane.

To avoid this, use [centrally-managed Consumers](/gateway/entities/consumer/#centrally-managed-consumers) instead of concentrating shared Consumers in one member control plane. 
Currently, centrally-managed Consumers only support Key Auth.

## Control plane conflicts

When combining configurations from individual control planes into a control plane group you may receive conflict errors in {{site.konnect_short_name}}, for example: 

```sh
Conflicts have been detected between these control planes: 
CONTROL-PLANE-EXAMPLE
CONTROL-PLANE-ANOTHER-EXAMPLE
```
{:.no-copy-code}

The control plane won't update a Data Plane configuration until the conflict is resolved. 
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
  - conflict: Duplicate names across control plane group members
    description: Same entity name exists in multiple member control planes.
    action: Remove or rename one of the conflicting entities.
  - conflict: Shared credentials across control plane group members
    description: Credentials from one member can authenticate across the group.
    action: Remove shared credentials if cross-access is not desired.
  - conflict: ACL group names across control plane group members
    description: ACL group names are shared across members.
    action: Remove or rename duplicate ACL groups if isolation is needed.
  - conflict: Consumers across control plane group members
    description: Consumer names are shared across members.
    action: Remove or rename duplicates if isolation is needed.
  - conflict: Consumer groups across control plane group members
    description: Consumer group names are shared across members.
    action: Remove or rename duplicates if isolation is needed.
  - conflict: decK dump with duplicate names found
    description: "`deck gateway dump` fails on duplicate names."
    action: Remove or rename duplicate entities.
  - conflict: Reference by name vs reference by ID
    description: ID-based references don’t work across control planes, string-based ones do.
    action: Use string references, or remove conflicting entities.
  - conflict: Multiple instances of the same global plugin
    description: Only one global plugin instance is allowed in the group.
    action: Remove duplicates or assign unique instance names.
{% endtable %}
