---
title: Request Rule Validator
name: Request Rule Validator
content_type: plugin
description: Validate the content of Kafka admin and data requests against a set of rules.
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/RequestRuleValidatorPolicy

api_specs:
  - konnect/event-gateway

phases:
  - cluster

icon: graph.svg

policy_target: virtual_cluster

categories:
  - security

min_version:
  event-gateway: '1.3'

related_resources:
  - text: ACLs policy
    url: /event-gateway/policies/acl/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Expressions reference
    url: /event-gateway/expressions/
---

The Request Rule Validator policy validates the content of Kafka requests against a list of rules you define. 
Use it to enforce conventions that the [ACLs policy](/event-gateway/policies/acl/) can't express, because ACLs decide whether a principal can perform an action, not what values the action carries.

For example, you can use the Request Rule Validator policy to:
* Limit the number of partitions or replicas a topic can have.
* Enforce a naming convention for topics or consumer groups.
* Require producers to acknowledge writes from all in-sync replicas.
* Block changes to broker-level configuration.
* Prevent overly permissive ACL bindings, like granting `ALL` or using a wildcard principal.

Each rule describes the valid state of a request as a [CEL expression](/event-gateway/expressions/). When the expression evaluates to `false`, the rule's configured action runs.

## Use cases

Common use cases for the Request Rule Validator policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Enforce topic naming, sizing, and retention conventions](./examples/enforce-topic-conventions/)"
    description: Require a topic name prefix, cap partitions and enforce a minimum replication factor, and pin retention to a fixed value.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [cluster phase](/event-gateway/entities/policy/#phases), evaluating rules against the content of specific Kafka request types.

1. A Kafka client sends a request, for example to create a topic or produce a message.
1. {{site.event_gateway_short}} evaluates every configured rule for that request type.
    * If a rule's expression evaluates to `true`, the request satisfies that rule.
    * If a rule's expression evaluates to `false`, {{site.event_gateway_short}} runs the rule's configured action.
1. If any rule configured with the `reject` action fails, {{site.event_gateway_short}} responds with the Kafka `POLICY_VIOLATION` error code and doesn't forward the request to the backend cluster.

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant broker as Event broker

  client->>egw: request (e.g. CreateTopics)
  egw->>egw: evaluate rules for the request type

  alt If every reject rule passes

  egw->>broker: forward request

  else If a reject rule fails

  egw-x client: POLICY_VIOLATION
  end

{% endmermaid %}
<!--vale on-->

### Request types and available values

You configure rules per Kafka request type.
Each request type exposes a different set of values to the rule's CEL expression, matching the fields of that request.
All rule expressions also have access to the [authentication fields](/event-gateway/expressions/#available-fields).

See the [policy reference](/event-gateway/policies/request-rule-validator/reference/) for the supported request types and the values available to each one.

### Batched requests

Some request types, like `create_topics`, carry a batch of items in a single request.
{{site.event_gateway_short}} evaluates every rule against each item independently.
When one item in a batch violates a `reject` rule, only that item is rejected with `POLICY_VIOLATION`, while the rest of the batch proceeds normally.

### Actions

Each rule configures one of two actions, which runs when the rule's expression evaluates to `false`:

* `reject`: Fails the request, or the offending item in a batch, with the `POLICY_VIOLATION` error code.
* `passthrough`: Lets the request continue, but records the violation the same way `reject` does (metrics and logs on a debug level).

If a rule's expression can't be evaluated, for example because a value has an unexpected format, {{site.event_gateway_short}} treats the result as `false` and runs the rule's action.

### Multiple rules and policies

You can configure more than one rule per request type, and more than one Request Rule Validator policy on a virtual cluster. Like other cluster policies, they run in the order they're configured.

We recommend placing the Request Rule Validator policy after the [ACLs policy](/event-gateway/policies/acl/), so an unauthorized client learns nothing about your rules before it's rejected on authorization grounds.

## Security considerations

A rule's `description` is included in the error the client sees and in {{site.event_gateway_short}} logs.
Avoid including sensitive details, like internal system names or other rules you enforce, in a rule's `description` if that information shouldn't be visible to the client that triggered the violation.
