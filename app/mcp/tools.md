---
title: "{{site.konnect_product_name}} MCP Server tools"
content_type: reference
layout: reference
permalink: /mcp/kong-mcp/tools/
description: This reference provides an overview of tools available in {{site.konnect_product_name}} MCP Server

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

plugins:
  - ai-proxy
  - ai-proxy-advanced

min_version:
  gateway: '3.6'

related_resources:
    - text: "{{site.konnect_product_name}} MCP Server"
      url: 'https://github.com/Kong/mcp-konnect'
    - text: MCP Server on Docker
      url: 'https://hub.docker.com/r/mcp/kong'
      icon: /assets/icons/third-party/docker.svg
    - text: AI Gateway
      url: /ai-gateway/
---

Kong’s MCP Server provides a suite of APIs, called MCP tools, for analytics, configuration queries, and Control Plane management. Clients like Claude connect to these APIs through a conversational interface. Instead of writing raw API calls, you describe what you need—such as “show API request trends for the past 24 hours” or “list services in the US-east Control Plane”—and Claude generates the requests and returns structured results.

These tools support filters, flexible time ranges, and detailed queries, giving you precise control over gateway traffic analysis, configuration inventory, and multi-cluster operations. Using Claude, you can troubleshoot issues, audit deployments, and orchestrate Control Planes by simply describing tasks in natural language. See the [get started with Kong MCP guide](/mcp/kong-mcp/get-started/#analyze-api-traffic-using-claude-and-kong-mcp-server) to learn more.

## Analytics tools

Analytics tools allow you to query and analyze API request data collected from {{site.base_gateway}} deployments connected to MCP. These tools support detailed filtering and flexible time ranges for insight generation.

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
      Analyze API requests made by a specific Consumer, with filters for success/failure and time range.<br/><br/>

      **Inputs**:
      - `consumerId`: Target Consumer
      - `timeRange`: Time window for analysis
      - `successOnly`, `failureOnly`: Optional filters by result type
      - `maxResults`: Result count limit
{% endtable %}
<!--vale on-->

## Configuration tools

Configuration tools provide read-access to the {{site.base_gateway}} resource objects associated with a Control Plane. This allows you to do inventory audits, automation, or UI rendering for dashboards.

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
      Enumerates all Gateway Services within a specific Control Plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`: Target Control Plane ID
      - `size`, `offset`: Pagination controls
  - tool: "List Routes"
    description: |
      Lists all Route configurations deployed within a Control Plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`, `size`, `offset`
  - tool: "List Consumers"
    description: |
      Fetches all Consumer records within a Control Plane.

      **Inputs**:
      - `controlPlaneId`, `size`, `offset`
  - tool: "List Plugins"
    description: |
      Retrieves all plugins configured under the specified Control Plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`, `size`, `offset`
{% endtable %}
<!--vale on-->

## Control Plane tools

These tools help users manage multiple Control Planes and their organizational relationships. This is useful for environments with many clusters and regional deployments.

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
      Lists all Control Planes in the organization, with options to filter and sort.<br/><br/>

      **Inputs**:
      - `pageSize`, `pageNumber`: Pagination
      - `filterName`, `filterClusterType`, `filterCloudGateway`, `labels`, `sort`: Query refinement options
  - tool: "Get Control Plane"
    description: |
      Retrieves detailed metadata about a specific Control Plane.<br/><br/>

      **Inputs**:
      - `controlPlaneId`: Unique ID of the Control Plane
  - tool: "List Control Plane Group Memberships"
    description: |
      Lists all Control Planes that belong to a specified group.<br/><br/>

      **Inputs**:
      - `groupId`, `pageSize`, `pageAfter`
  - tool: "Check Control Plane Group Membership"
    description: |
      Verifies whether a given Control Plane belongs to any group.<br/><br/>

      **Inputs**:
      - `controlPlaneId`: Control Plane to check
{% endtable %}
<!--vale on-->
