---
title: Forward to Virtual Cluster
name: Forward to Virtual Cluster
content_type: reference
description: Forward messages from a Kafka client to a virtual cluster
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/EventGatewayListenerPolicyModify

api_specs:
  - event-gateway/knep

policy_target: listener

icon: graph.svg
---

The Forward to Virtual Cluster policy forwards messages from Kafka clients to virtual clusters configured with port or SNI routing.

The following examples provide some common configurations for the Forward to Virtual Cluster policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Port mapping](/event-gateway/policies/forward-to-virtual-cluster/examples/port-mapping/)"
    description: Forward to virtual clusters using port mapping.
  - use_case: "[SNI routing](/event-gateway/policies/forward-to-virtual-cluster/examples/sni-routing/)"
    description: Forward to virtual clusters using SNI routing.
  - use_case: "[Using conditions](/event-gateway/policies/forward-to-virtual-cluster/examples/conditions/)"
    description: Only forward messages that conform to a specific condition.

{% endtable %}
<!--vale on-->

{:.info}
> Note: When using `port_mapping`, there must be a mapping port for each broker on the backend cluster.

## Configuring multiple policies

Each listener can have multiple Forward to Virtual Cluster policies configured. 
However, there can only be one instance of `port_mapping`.

When multiple Forward to Virtual Cluster policies are configured, the first one that matches the connection is used.
If no policy matches, the connection is rejected.

