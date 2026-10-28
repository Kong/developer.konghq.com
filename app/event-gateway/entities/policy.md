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
    - kongctl

tags:
  - policy

works_on:
  - konnect

schema:
    api: konnect/event-gateway
    path: /schemas/EventGatewayPolicy

api_specs:
    - konnect/event-gateway

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

Depending on the type of configuration update, the connection between the Kafka client and the backend can be affected:
* Updates to virtual cluster policies don't cause a connection drop. Policies reload dynamically and take effect on the next request.
* Updates to listener policies cause a connection drop. When the data plane receives configuration updates to a listener policy, it restarts the running proxy services.

If a connection drop occurs, the Kafka client is designed to handle short-lived breaks in connections.

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
        - [Request Rule Validator](/event-gateway/policies/request-rule-validator/)
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
  - title: Can act on non-parsed (serialized) record?
    key: nonparsed
    center: true
  - title: Can act on parsed (deserialized) record?
    key: parsed
    center: true
features:
  - title: "[Kafka ACL](/event-gateway/policies/acl/)"
    nonparsed: No
    parsed: No
  - title: "[Request Rule Validator](/event-gateway/policies/request-rule-validator/)"
    nonparsed: No
    parsed: No
  - title: "[Encrypt](/event-gateway/policies/encrypt/)"
    nonparsed: Yes
    parsed: No
  - title: "[Decrypt](/event-gateway/policies/decrypt/)"
    nonparsed: Yes
    parsed: No
  - title: "[Schema validation](/event-gateway/policies/schema-validation/)"
    nonparsed: Yes
    parsed: No
  - title: "[Modify headers](/event-gateway/policies/modify-headers/)"
    parsed: Yes
    nonparsed: Yes
  - title: "[Skip records](/event-gateway/policies/skip-record/)"
    parsed: Yes
    nonparsed: Yes
  - title: "[Record Transcode Produce](/event-gateway/policies/record-transcode-produce/) and [Record Transcode Consume](/event-gateway/policies/record-transcode-consume/)"
    nonparsed: No
    parsed: Yes
  - title: "[Mask Fields Produce](/event-gateway/policies/mask-fields-produce/) and [Mask Fields Consume](/event-gateway/policies/mask-fields-consume/)"
    nonparsed: No
    parsed: Yes
{% endfeature_table %}
<!-- vale on -->

### Policy nesting

Certain policies can serve as parent policies. You can nest policies within a parent policy to process the record content.

<!--vale off-->
{% table %}
columns:
  - title: Parent policy
    key: parent
  - title: Possible nested child policies
    key: nested
rows:
  - parent: "[Schema Validation produce](/event-gateway/policies/schema-validation-produce/)"
    nested: |
      * [Modify Headers](/event-gateway/policies/modify-headers/)
      * [Encrypt Fields](/event-gateway/policies/encrypt-fields/)
      * [Record Transcode Produce](/event-gateway/policies/record-transcode-produce/)
      * [Mask Fields Produce](/event-gateway/policies/mask-fields-produce/)
  - parent: "[Schema Validation consume](/event-gateway/policies/schema-validation-consume/)"
    nested: |
      * [Modify Headers](/event-gateway/policies/modify-headers/)
      * [Skip Records](/event-gateway/policies/skip-record/)
      * [Decrypt Fields](/event-gateway/policies/decrypt-fields/)
      * [Record Transcode Consume](/event-gateway/policies/record-transcode-consume/)
      * [Mask Fields Consume](/event-gateway/policies/mask-fields-consume/)
    
{% endtable %}
<!--vale on-->

Nested policies are sorted into an index. You can re-order nested policies within the parent policy by adjusting this index.

{% navtabs 'reorder' %}
{% navtab "Konnect API" %}

To re-order policies using the {{site.konnect_short_name}} Control Plane API, use the `/move` endpoint. For example, to move a produce policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/{gatewayId}/virtual-clusters/{virtualClusterId}/produce-policies/{policyID}/move
status_code: 201
method: POST
body:
  index: 2
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Konnect UI" %}

To re-order policies using the {{site.konnect_short_name}} UI:
1. In your {{site.event_gateway_short}}, navigate to **Virtual Clusters** in the sidebar.
1. Select a virtual cluster.
1. Click the **Policies** tab.
1. Click either **Produce** or **Consume** to find a Schema Validation policy with nested policies. You'll see nested policies displayed as children.
1. Click the parent policy.
1. In the list of nested policies, drag and drop the policies to re-order them.

{% endnavtab %}
{% endnavtabs %}

### Set up a virtual cluster policy

{{site.event_gateway}} has a few built-in virtual cluster policies, all of which have their own specific configurations and examples.
See all [{{site.event_gateway_short}} policies](/event-gateway/policies/?policy-target=virtual_cluster) for their individual configurations.

Here's an example configuration for the Modify Headers consume policy:

{% entity_example %}
type: event_gateway_policy
policy_type: modify-headers
phase: consume
name: new-header
data:
  actions:
    - op: set
      key: My-New-Header
      value: header_value
{% endentity_example %}

## Failure modes

Some produce and consume policies have a `failure_mode` setting that controls what happens to a record when the policy fails to process it:

{% table %}
columns:
  - title: Failure mode
    key: failure_mode
  - title: Description
    key: description
  - title: Policy type
    key: policy_type
rows:
  - failure_mode: "`reject`"
    description: "Rejects the record batch that holds the record."
    policy_type: Produce
  - failure_mode: "`error`"
    description: "Doesn't deliver the batch to the client on consume, and rejects the record when the policy fails on produce."
    policy_type: Consume and produce
  - failure_mode: "`skip`"
    description: "Doesn't deliver the record to the client."
    policy_type: Consume
  - failure_mode: "`passthrough`"
    description: "Delivers the record even though policy execution failed."
    policy_type: Consume and produce
  - failure_mode: "`mark`"
    description: "Delivers the record, and {{site.event_gateway_short}} adds a `kong/policy-failure-<id>` header whose value is the reason for the failure (truncated to 512 characters)."
    policy_type: Consume and produce
{% endtable %}

See each policy for the failure modes it supports.

### mark

The `mark` failure mode attaches the policy failure reason to the record in a `kong/policy-failure-<id>` header.

On produce, {{site.event_gateway_short}} stores the header with the record in the backend cluster. 
The header remains on the record, so every consumer of the topic sees it, including systems that never pass through {{site.event_gateway_short}}.

A producer with access to the topic can trigger policy failures on purpose and read the failure reasons to learn about your policy configuration.

{:.warning}
> **Warning**: Failure reasons can contain runtime-specific information, such as schema IDs, registry URLs, field paths, KMS ARNs and key IDs, KMS error text, JWT issuer and audience data, and CEL expression snippets.
> If you use `mark`, configure a [Modify Headers](/event-gateway/policies/modify-headers/) policy that runs after the failing policy to remove the `kong/policy-failure-<id>` header before the record is stored in the backend cluster or delivered to a client.

### error

The `error` failure mode stops the delivery of the whole batch that contains the failing record.
The client receives an error with the policy failure reason.

{:.warning}
> **Warning**: A single record that always fails the policy, for example one written by a producer with access to the topic, blocks every consumer group at that offset, and recovery requires manual operator action.
> Use `error` sparingly, and prefer `skip` when producers you don't trust can write to the topic.
> `skip` stops only the failing record, so consumer groups keep making progress.

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
policy_type: forward-to-virtual-cluster
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

{% raw %}

```json
"condition": "{{context.topic.name.endsWith('my_suffix')}}"
```

{% endraw %}

See the [expressions reference](/event-gateway/expressions/) for more information.

## Schema

{% entity_schema %}
