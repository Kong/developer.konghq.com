---
title: "MCP Server Tools"
content_type: reference
layout: reference
permalink: /mcp/tools/
description: This reference provides an overview of tools available in Kong MCP Server

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
  - /mcp/
tags:
  - ai
  - streaming

plugins:
  - ai-proxy
  - ai-proxy-advanced

min_version:
  gateway: '3.6'

related_resources:
    - text: Kong MCP Konnect
      url: 'https://github.com/Kong/mcp-konnect'
    - text: Kong MCP Konnect on Docker
      url: 'https://hub.docker.com/r/mcp/kong'
      icon: /assets/icons/third-party/docker.svg
    - text: AI Gateway
      url: /ai-gateway/
---

Kong’s MCP Server provides a set of API-accessible tools to support analytics, configuration management, and control plane administration. These tools help users monitor traffic, query resource metadata, and manage control plane hierarchies programmatically.

## Analytics tools

Analytics tools allow you to query and analyze API request data collected from Kong Gateway deployments connected to MCP. These tools support detailed filtering and flexible time ranges for insight generation.

<!--vale off-->
{% table %}
columns:
  - title: Tool
    key: tool
  - title: Description
    key: description
rows:
  - tool: "Query API Requests"
    description: |
      Retrieve historical request data across gateways with multiple filters. Analyze trends, diagnose issues, or monitor performance.<br/><br/>

      **Inputs**:
      - `timeRange`: Range of data to query (e.g., 15M, 1H, 24H)
      - `statusCodes`, `excludeStatusCodes`: Filter specific HTTP codes
      - `httpMethods`: Limit to certain methods (e.g., GET, POST)
      - `consumerIds`, `serviceIds`, `routeIds`: Scope data to entities
      - `maxResults`: Cap the number of returned entries
  - tool: "Get Consumer Requests"
    description: |
      Analyze API requests made by a specific consumer, with filters for success/failure and time range.<br/><br/>

      **Inputs**:
      - `consumerId`: Target consumer
      - `timeRange`: Time window for analysis
      - `successOnly`, `failureOnly`: Optional filters by result type
      - `maxResults`: Result count limit
{% endtable %}
<!--vale on-->

## Configuration tools

Configuration tools provide read-access to the Kong resource objects associated with a control plane, enabling inventory audits, automation, or UI rendering for dashboards.

<!--vale off-->
{% table %}
columns:
  - title: Tool
    key: tool
  - title: Description
    key: description
rows:
  - tool: "List Services"
    description: |
      Enumerates all services within a specific control plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`: Target control plane ID
      - `size`, `offset`: Pagination controls
  - tool: "List Routes"
    description: |
      Lists all route configurations deployed within a control plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`, `size`, `offset`
  - tool: "List Consumers"
    description: |
      Fetches all consumer records within a control plane.

      **Inputs**:
      - `controlPlaneId`, `size`, `offset`
  - tool: "List Plugins"
    description: |
      Retrieves all plugins configured under the specified control plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`, `size`, `offset`
{% endtable %}
<!--vale on-->

## Control Plane tools

These tools help users manage multiple control planes and their organizational relationships. Useful for environments with many clusters and regional deployments.

<!--vale off-->
{% table %}
columns:
  - title: Tool
    key: tool
  - title: Description
    key: description
rows:
  - tool: "List Control Planes"
    description: |
      Lists all control planes in the organization, with options to filter and sort.<br/><br/>

      **Inputs**:
      - `pageSize`, `pageNumber`: Pagination
      - `filterName`, `filterClusterType`, `filterCloudGateway`, `labels`, `sort`: Query refinement options
  - tool: "Get Control Plane"
    description: |
      Retrieves detailed metadata about a specific control plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`: Unique ID of the control plane
  - tool: "List Control Plane Group Memberships"
    description: |
      Lists all control planes that belong to a specified group.<br/><br/>

      **Inputs**:
      - `groupId`, `pageSize`, `pageAfter`
  - tool: "Check Control Plane Group Membership"
    description: |
      Verifies whether a given control plane belongs to any group.<br/><br/>

      **Inputs**:
      - `controlPlaneId`: Control plane to check
{% endtable %}
<!--vale on-->
