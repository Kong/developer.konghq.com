---
title: "Last known good configuration in {{site.konnect_short_name}}"
content_type: reference
layout: reference

products:
    - gateway

works_on:
   - konnect

breadcrumbs:
  - /konnect/

tags:
    - control-plane
    - data-plane
    - resilience

description: "The last known good configuration is the last configuration that a Data Plane node of the same {{site.base_gateway}} version accepted. {{site.konnect_short_name}} sends it to a new node that rejects the current configuration."

related_resources:
  - text: Control Plane outage management
    url: /gateway/cp-outage/
  - text: "{{site.konnect_short_name}} Data Plane nodes"
    url: /gateway/data-plane-reference/
  - text: "{{site.base_gateway}} Control Plane and Data Plane communication"
    url: /gateway/cp-dp-communication/
  - text: Incremental Config Sync
    url: /gateway/incremental-config-sync/

faqs:
  - q: Does the fallback replace the configuration on a Data Plane node that is already running?
    a: |
      No. A node that runs a configuration rejects any configuration that it cannot apply, and keeps its current one. That current configuration is already the last known good configuration for the node. {{site.konnect_short_name}} only sends the fallback to a node without a configuration.
  - q: What happens if no accepted configuration exists for my Data Plane version?
    a: |
      {{site.konnect_short_name}} cannot send a fallback. The node stays without configuration until {{site.konnect_short_name}} can deliver a current configuration that the node accepts.
  - q: Does {{site.konnect_short_name}} keep sending the rejected configuration to the node?
    a: |
      No. After the node rejects a configuration, {{site.konnect_short_name}} does not send that configuration to the node again. {{site.konnect_short_name}} also throttles repeated failures for the same node and the same rejected configuration.
  - q: Does the fallback help during a {{site.konnect_short_name}} Control Plane outage?
    a: |
      No. The fallback needs a running Control Plane to send the configuration. If the Control Plane is unreachable, use [Data Plane resilience](/gateway/cp-outage/).
---

{{site.konnect_short_name}} stores the last configuration that each {{site.base_gateway}} version of Data Plane node applied. If a new or reconnecting node rejects the current configuration and does not have a configuration of its own, {{site.konnect_short_name}} sends it the stored configuration. The node then starts to proxy traffic instead of waiting without a configuration.

{{site.konnect_short_name}} turns on this fallback for all Control Planes. You do not need to configure it.

## When the fallback applies

A Data Plane node can reject the current configuration for these reasons:

* A version compatibility transformation fails for the node's {{site.base_gateway}} version.
* The configuration has an entity or plugin shape that the node's version does not support.
* A problem on the Control Plane side stops the node from applying the full configuration.

The fallback applies only if all of these conditions are true:

{% table %}
columns:
  - title: Condition
    key: condition
  - title: Fallback applies
    key: applies
  - title: Fallback does not apply
    key: excluded
rows:
  - condition: Sync method
    applies: Full configuration sync over WebSocket
    excluded: "[Incremental Config Sync](/gateway/incremental-config-sync/)"
  - condition: Node configuration
    applies: The node does not have a configuration yet
    excluded: The node already runs a configuration
  - condition: Stored configuration
    applies: A node of the same {{site.base_gateway}} version applied a configuration before
    excluded: No node of that version ever applied a configuration
  - condition: Control Plane
    applies: The Control Plane is running
    excluded: "The Control Plane is down. Use [Data Plane resilience](/gateway/cp-outage/) instead."
{% endtable %}

## How the fallback works

{% mermaid %}
sequenceDiagram
    autonumber
    participant DP as New Data Plane node<br/>(no configuration)
    participant CP as Konnect Control Plane
    participant Store as Last known good store<br/>(per Gateway version)

    Note over CP,Store: Earlier, a node of this version applied<br/>configuration X. Konnect stored X.
    DP->>CP: Connect over WebSocket
    CP->>DP: Send current configuration Y
    DP->>DP: Validate and apply Y
    alt Node accepts Y
        DP->>CP: Report hash of Y
        CP->>Store: Store Y as last known good
    else Node rejects Y
        DP->>CP: Report error for Y
        CP->>Store: Fetch configuration X
        Store-->>CP: Configuration X
        CP->>DP: Send configuration X
        DP->>DP: Apply X
        DP->>CP: Report hash of X
        Note over DP,CP: The node runs X until<br/>the next configuration change.
    end
{% endmermaid %}

1. The Data Plane node connects to the {{site.konnect_short_name}} Control Plane.
1. {{site.konnect_short_name}} sends the current full configuration.
1. The node validates the configuration and tries to apply it.
1. If the node rejects the configuration and does not have a configuration, it reports the error to {{site.konnect_short_name}}.
1. {{site.konnect_short_name}} gets the last known good configuration for the node's {{site.base_gateway}} version and sends it.
1. The node applies the fallback configuration and reports its new configuration hash on the next heartbeat.

{{site.konnect_short_name}} stores a new last known good configuration each time a node applies a configuration and reports the new hash.

## Nodes on the fallback configuration

A node that uses the fallback runs an older configuration. Changes that you made after that configuration are not on the node.

The fallback cannot make a node run a newer configuration than the other nodes. For example:

1. Node A runs configuration X. You change the configuration, and {{site.konnect_short_name}} builds configuration Y. Node A rejects Y and keeps X.
1. Node B connects without a configuration. It is the first new node to receive Y, and it rejects Y.
1. {{site.konnect_short_name}} sends X to node B.
1. Node C of the same version connects without a configuration. {{site.konnect_short_name}} sends it X directly, and node C never receives Y.

All three nodes now run X. They stay on X until you make another configuration change.

After the first new node of a version rejects a configuration, {{site.konnect_short_name}} sends the fallback directly to the next nodes of that version that connect. This stays true until the next configuration change.

To find out if a node runs on the fallback, get the node from the [Control Plane Config API](/api/konnect/control-planes-config/#/operations/get-nodes-node_id). A node on the fallback reports the resiliency sync state, the time the fallback started, and the errors from the configuration it rejected.

## Recovery time

In most cases, a node gets the fallback configuration a few seconds after it rejects the current configuration. Large configurations take longer for the node to apply.

{{site.konnect_short_name}} allows up to one minute to get and send the fallback after it receives the node's error. This is a limit for one attempt, not a service level agreement.

## Return to the current configuration

A node stays on the fallback configuration until you change the configuration. To move the node to the current configuration:

1. Get the node from the [Control Plane Config API](/api/konnect/control-planes-config/#/operations/get-nodes-node_id) and read the errors from the rejected configuration.
1. Fix the entity or plugin that caused the error, or upgrade the node to a {{site.base_gateway}} version that supports it.
1. Apply the configuration change.

{{site.konnect_short_name}} then sends the new configuration to all connected nodes.

## Last known good configuration and Data Plane resilience

{{site.konnect_short_name}} has a second fallback for new nodes. [Data Plane resilience](/gateway/cp-outage/) configures new nodes from a configuration backup in object storage when the Control Plane is unreachable. The two features cover different failures:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Failure it covers
    key: failure
  - title: Who runs it
    key: owner
  - title: Setup
    key: setup
rows:
  - feature: Last known good configuration
    failure: The Control Plane is running, but the node rejects the current configuration
    owner: "{{site.konnect_short_name}}"
    setup: None
  - feature: "[Data Plane resilience](/gateway/cp-outage/)"
    failure: The Control Plane is unreachable
    owner: You
    setup: A backup node and S3-compatible or Google Cloud storage
{% endtable %}
