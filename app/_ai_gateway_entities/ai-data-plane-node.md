---
title: AI Data Plane Nodes
content_type: reference
entities:
  - ai-data-plane-node
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-data-plane-node/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: Data Plane nodes that run {{site.ai_gateway}} workloads and connect to the control plane.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayDataPlaneNode
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} entity"
    url: /ai-gateway/entities/ai-gateway/
  - text: Data Plane Certificate entity
    url: /ai-gateway/entities/ai-data-plane-certificate/
faqs:
  - q: How do I register a new Data Plane node?
    a: |
      Data Plane nodes register themselves when they start and establish a connection to the 
      {{site.ai_gateway}} using a client certificate. Once registered, the node appears in 
      the Konnect {{site.ai_gateway}} UI and is accessible via the API.

  - q: What does `config_hash` tell me?
    a: |
      [`config_hash`](#schema-aigateway-data-plane-node-config-version) is a hash of the configuration currently applied by the node. Compare 
      this to the {{site.ai_gateway}}'s `config_hash`. If they match, the node is in sync 
      with the latest control plane configuration. If they differ, the node is running stale 
      configuration.

  - q: What is `last_ping`?
    a: |
      [`last_ping`](#schema-aigateway-data-plane-node-last-ping) is a Unix timestamp indicating the most recent heartbeat from the node. 
      It helps operators identify nodes that are no longer communicating with the control plane.

  - q: What do compatibility issues mean?
    a: |
      Compatibility issues indicate that the node's version or configuration is incompatible 
      with the {{site.ai_gateway}}. The issue detail includes a resolution explaining what 
      must be changed to bring the node into a compatible state.
---

## What is an AI Data Plane Node?

An AI Data Plane Node is a runtime instance that executes {{site.ai_gateway}} traffic and maintains a persistent connection to the {{site.konnect_short_name}} {{site.ai_gateway}} control plane. Nodes self-register when they start with a valid [AI Data Plane Certificate](/ai-gateway/entities/ai-data-plane-certificate/), pull configuration from the control plane, and stream telemetry back (analytics, logs, health). {{site.ai_gateway}} tracks each node's [`config_hash`](#schema-aigateway-data-plane-node-config-version) and [`last_ping`](#schema-aigateway-data-plane-node-last-ping) to verify configuration synchronization and connectivity.

AI Data Plane Nodes are read-only entities in the {{site.ai_gateway}} API. You cannot create or delete nodes through the control plane; instead, manage them by deploying or decommissioning the runtime binaries. Operators monitor and troubleshoot nodes through the {{site.konnect_short_name}} UI and API.

AI Data Plane Nodes can be viewed through the {{site.konnect_short_name}} {{site.ai_gateway}} API:

{% table %}
columns:
  - title: Deployment
    key: deployment
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - deployment: "{{site.konnect_short_name}}"
    cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/nodes
{% endtable %}

## Understanding Node Status

When you list or inspect a node, key fields to monitor are:

* **[`last_ping`](#schema-aigateway-data-plane-node-last-ping)**: The most recent heartbeat timestamp. A stale value indicates the node has lost connectivity or crashed.
* **[`config_hash`](#schema-aigateway-data-plane-node-config-version)**: Compare this to the {{site.ai_gateway}}'s `config_hash`. If they differ, the node is running stale configuration and should be restarted or rolled forward.
* **[`compatibility_status`](#schema-aigateway-data-plane-node-compatibility-status)**: Reports any version or configuration incompatibilities. If issues are present, review the resolution steps provided before routing traffic through the node.

## Monitoring Nodes

Regularly check the list of registered nodes to ensure they are healthy and in sync:

1. **Verify connectivity**: Check [`last_ping`](#schema-aigateway-data-plane-node-last-ping) to confirm the node is actively reporting to the control plane.
1. **Verify configuration sync**: Compare each node's [`config_hash`](#schema-aigateway-data-plane-node-config-version) to the {{site.ai_gateway}}'s `config_hash`. If they differ, the node is running stale configuration and should be restarted or rolled forward.
1. **Resolve compatibility issues**: If a node reports compatibility issues, the [`compatibility_status`](#schema-aigateway-data-plane-node-compatibility-status) field includes resolution steps. Address them before the node begins serving traffic.

## Schema

{% entity_schema %}
