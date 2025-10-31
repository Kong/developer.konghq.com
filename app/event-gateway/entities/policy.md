---
title: "Policies"
content_type: reference
layout: gateway_entity

description: |
    Policies control how Kafka protocol traffic is modified between the client and the backend cluster.
related_resources:
  - text: "{{site.event_gateway_short}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Virtual clusters"
    url: /event-gateway/entities/virtual-cluster/
  - text: "Backend clusters"
    url: /event-gateway/entities/backend-cluster/
  - text: "Listeners"
    url: /event-gateway/entities/listener/
  - text: "Expressions reference"
    url: /event-gateway/expressions/

tools:
    - konnect-api
    - terraform

tags:
  - policy

works_on:
  - konnect

schema:
    api: event-gateway/knep
    path: /schemas/EventGatewayPolicy

api_specs:
    - event-gateway/knep

products:
    - event-gateway

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## What is an {{site.event_gateway_short}} policy?

Policies control how Kafka protocol traffic is modified between the client and the backend cluster.

There are two main types of policies:
* [Virtual cluster policies](#virtual-cluster-policies): Transformation and validation policies applied to Kafka messages. 
Virtual cluster policies break down further into cluster, consume, and produce policies.
* [Listener policies](#listener-policies): Routing policies that pass traffic to the virtual cluster.

## How do policies work?

Policies execute in chains. The order in which {{site.event_gateway}} applies policies to modify messages depends on the policy type, and whether the message is a request or response.

{% include_cached /knep/entities-diagram.md entity="policy" %}
<!-- Need more info here -->

## Virtual cluster policies 

Virtual cluster policies are applied to Kafka traffic via [virtual clusters](/event-gateway/entities/virtual-cluster/). They let you modify headers, encrypt or decrypt records, validate schemas, and more.

See the {{site.event_gateway}} policy hub for [all available virtual cluster policies](/event-gateway/policies/?policy-target=virtual_cluster).

### Phases

Virtual cluster policies run during specific phases, which represent stages in a record's lifecycle: cluster, consume, and produce.

<!-- vale off -->
{% table %}
columns:
  - title: Phase
    key: phase
  - title: Description
    key: description
  - title: Policies
    key: policies
rows:
  - phase: "`Cluster`"
    description: Cluster policies execute on all Kafka API commands from clients.
    policies: |
        - [ACL](/event-gateway/policies/acl/)
  - phase: "`Produce`"
    description: "Produce policies execute on Kafka `Produce` commands."
    policies: |
        - [Encrypt](/event-gateway/policies/encrypt/)
        - [Schema validation](/event-gateway/policies/schema-validation/)
        - [Modify headers](/event-gateway/policies/modify-headers/)
  - phase: "`Consume`"
    description: "Consume policies execute on Kafka `Fetch` commands."
    policies: |
        - [Decrypt](/event-gateway/policies/decrypt/)
        - [Schema validation](/event-gateway/policies/schema-validation/)
        - [Modify headers](/event-gateway/policies/modify-headers/)
        - [Skip records](/event-gateway/policies/skip-record/)
{% endtable %}
<!-- vale on -->

### Record serialization

Some policies operate on parsed records, while others work with raw serialized data.

* **Parsed records**: Deserialized into a structured format (for example, JSON objects or Avro records).
* **Non-parsed records**: Raw, serialized byte data.

Records are deserialized on produce and re-serialized on consume.

<!-- vale off -->
{% feature_table %}
columns:
  - title: Can act on parsed (deserialized) record?
    key: parsed
    center: true
  - title: Can act on non-parsed (serialized) record?
    key: nonparsed
    center: true
features:
  - title: "[Kafka ACL](/event-gateway/policies/acl/)"
    parsed: No
    nonparsed: Yes
  - title: "[Encrypt](/event-gateway/policies/encrypt/)"
    parsed: No
    nonparsed: Yes
  - title: "[Decrypt](/event-gateway/policies/decrypt/)"
    parsed: No
    nonparsed: Yes
  - title: "[Schema validation](/event-gateway/policies/schema-validation/)"
    parsed: No
    nonparsed: Yes
  - title: "[Modify headers](/event-gateway/policies/modify-headers/)"
    parsed: Yes
    nonparsed: Yes
  - title: "[Skip records](/event-gateway/policies/skip-record/)"
    parsed: Yes
    nonparsed: Yes
{% endfeature_table %}
<!-- vale on -->

### Set up a virtual cluster policy

{{site.event_gateway}} has a few built-in virtual cluster policies, all of which have their own specific configurations and examples.
See all [{{site.event_gateway_short}} policies](/event-gateway/policies/?policy-target=virtual_cluster) for their individual configurations.

Here's an example configuration for the Forward to Modify Headers policy:

{% entity_example %}
type: event_gateway_policy
policy_type: modify_headers
target: virtual_cluster
name: new-header
data:
  actions:
    - op: set
      key: My-New-Header
      value: header_value
{% endentity_example %}

## Listener policies

Listener policies are applied to layer 4 TCP traffic on [listeners](/event-gateway/entities/listener/), 
for example to enforce TLS, select a certificate for the TLS connection, or to route to a specific virtual cluster.

See the {{site.event_gateway}} policy hub for [all available listener policies](/event-gateway/policies/?policy-target=listener).

### Set up a listener policy

{{site.event_gateway}} has a few built-in listener policies, all of which have their own specific configurations and examples. 
See all [{{site.event_gateway_short}} policies](/event-gateway/policies/?policy-target=listener) for their individual configurations.

Here's an example configuration for the Forward to Virtual Cluster policy:

{% entity_example %}
type: event_gateway_policy
policy_type: forward_to_virtual_cluster
target: listener
name: forward
data:
  advertised_host: 0.0.0.0
  bootstrap_port: at_start
  destination:
    name: example-virtual-cluster
  min_broker_id: 1
  type: port_mapping
{% endentity_example %}

## Conditions

Policies have a condition field that determines whether the policy executes or not. 
By writing conditions using expressions, you can access dynamic configuration from the execution context.

For example, you can create a condition that selects all topics that end with the suffix `my_suffix`:

```json
"condition": "context.topic.name.endsWith('my_suffix')"
```

See the [expressions reference](/event-gateway/expressions/) for more information.

## Schema

{% entity_schema %}