---
title: ACLs
name: ACLs
content_type: reference
description: Manage access to your virtual cluster resources.
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/EventGatewayACLsPolicy

api_specs:
  - event-gateway/knep

phases:
  - cluster

icon: graph.svg

policy_target: virtual_cluster

related_resources:
  - text: Virtual Cluster
    url: /event-gateway/entities/virtual-clusters/
---

The ACLs (access control lists) policy allows you to manage authorization for your [virtual cluster](/event-gateway/entities/virtual-cluster/). You can define the actions that an authenticated principal can perform on your resources.

By default, when ACLs are enabled on a virtual cluster, no access is granted to the principal. You must define access rules explicitly through ACL policies.

## Use cases

Common use cases for the ACLs policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Allow read-only access to a topic](./examples/read-only-topic/)"
    description: Allow the authenticated principal to consume messages for a specific topic.
  - use_case: "[Allow consumer group management](./examples/manage-consumer-group/)"
    description: Allow the authenticated principal to create and delete consumer groups.

{% endtable %}
<!--vale on-->