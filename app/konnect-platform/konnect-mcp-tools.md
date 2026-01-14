---
title: "{{site.konnect_product_name}} MCP Server Tools"
description: "Complete reference for all MCP tools available in Kong {{site.konnect_product_name}}. Query gateway entities, debug API performance, analyze traffic, and search documentation."
content_type: reference
layout: reference
products:
  - konnect
tags:
  - ai
  - mcp
works_on:
  - konnect
breadcrumbs:
  - /konnect/
  - /konnect-platform/kai/
  - /konnect-platform/konnect-mcp/
permalink: /konnect-platform/konnect-mcp/tools/

beta: true

related_resources:
  - text: "{{site.konnect_product_name}} MCP Server"
    url: /konnect-platform/konnect-mcp/
  - text: "Install {{site.konnect_product_name}} MCP Server"
    url: /konnect-platform/konnect-mcp/installation/
  - text: "About Kong's AI assistant"
    url: /konnect-platform/kai/
---

The {{site.konnect_product_name}} MCP Server provides tools to query gateway entities, create debug sessions, analyze API traffic, and search Kong documentation. All operations require authentication with a Personal Access Token and respect your user permissions.

The following regional endpoints are supported:

<!-- vale off -->
{% table %}
columns:
  - title: Region
    key: region
  - title: Server URL
    key: url
rows:
  - region: United States (US)
    url: "`https://us.mcp.konghq.com/`"
  - region: Europe (EU)
    url: "`https://eu.mcp.konghq.com/`"
  - region: Australia (AU)
    url: "`https://au.mcp.konghq.com/`"
{% endtable %}
<!-- vale on -->

## GetControlPlane

Retrieves control plane information. List all control planes, get details by UUID or display name, or identify which control plane serves a specific API path. Use this tool to identify which control plane handles a specific API endpoint, list all control planes for configuration audits, or retrieve control plane details before modifying gateway configuration.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`operation`"
    type: string
    description: |
      Operation type: `"list"`, `"get_by_id"`, `"get_by_name"`, or `"get_by_route"`
  - parameter: "`id`"
    type: string
    description: |
      Control plane UUID. Required when `operation="get_by_id"`
  - parameter: "`name`"
    type: string
    description: |
      Control plane display name. Required when `operation="get_by_name"`
  - parameter: "`path`"
    type: string
    description: |
      API route path (e.g., `/api/users`). Required when `operation="get_by_route"`
{% endtable %}

<!-- vale on -->

**Returns:** Control plane objects with `id`, `name`, and `tags`. The `id` field should be extracted as `control_plane_id` for downstream tools.


## GetControlPlaneGroup

Retrieves control planes within a specific control plane group. Use this tool to list all control planes in a specific environment or team group, audit configurations across related control planes, or perform bulk operations on grouped control planes.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_group_id`"
    type: string
    description: UUID of the control plane group
  - parameter: "`operation`"
    type: string
    description: |
      Must be `"list"`
{% endtable %}

<!-- vale on -->

**Returns:** Array of control plane objects with `id`, `name`, and `tags`.


## GetConsumer

Retrieves API consumer information for a control plane. List all consumers, get details by UUID or username, or investigate authentication issues. Use this tool to investigate authentication failures for specific consumers, review consumer configuration and credentials, identify consumers generating high error rates, or audit consumer access patterns.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    description: |
      Operation type: `"list"`, `"get_by_id"`, or `"get_by_name"`
  - parameter: "`consumer_id`"
    type: string
    description: |
      Consumer UUID. Required when `operation="get_by_id"`
  - parameter: "`consumer_name`"
    type: string
    description: |
      Consumer username. Required when `operation="get_by_name"`
{% endtable %}

<!-- vale on -->

**Returns:** Consumer objects with `id`, `username`, `custom_id`, and `tags`. Use `username` for human communication and `id` when calling GetPlugin.


## GetConsumerGroup

Retrieves consumer group information for a control plane. Use this tool to review rate limiting tiers and consumer group assignments, audit consumer group membership, or verify consumer group configuration for different service tiers.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    description: |
      Must be `"list"`
{% endtable %}

<!-- vale on -->

**Returns:** Array of consumer group objects with `id`, `name`, `created_at`, and `tags`.


## GetService

Retrieves upstream service configurations for a control plane. List all services, get details by UUID or name, or troubleshoot connectivity issues. Use this tool to investigate service connectivity issues and timeout errors, review upstream configuration and health check settings, verify service endpoints and retry policies, or audit certificate configurations for secure services.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    description: |
      Operation type: `"list"`, `"get_by_id"`, or `"get_by_name"`
  - parameter: "`service_id`"
    type: string
    description: |
      Service UUID. Required when `operation="get_by_id"`
  - parameter: "`service_name`"
    type: string
    description: |
      Service name. Required when `operation="get_by_name"`
{% endtable %}

<!-- vale on -->

**Returns:** Service objects with upstream configuration (host, port, protocol, timeouts, retries, certificates).


## GetRoute

Retrieves route configurations for a control plane. List all routes, get configuration by UUID or name, or investigate routing issues. Use this tool to debug 404 errors and routing misconfigurations, verify path matching and HTTP method restrictions, review route priority and regex patterns, or identify which service handles specific API endpoints.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    description: |
      Operation type: `"list"`, `"get_by_id"`, or `"get_by_name"`
  - parameter: "`route_id`"
    type: string
    description: |
      Route UUID. Required when `operation="get_by_id"`
  - parameter: "`route_name`"
    type: string
    description: |
      Route display name. Required when `operation="get_by_name"`
{% endtable %}

<!-- vale on -->

**Returns:** Route objects with path mappings, HTTP methods, and service associations.


## GetPlugin

Retrieves plugin configurations for a control plane. List all plugins, get configuration by UUID, or troubleshoot plugin issues. Use this tool to identify which plugins affect a specific route or service, review rate limiting policies and authentication requirements, debug plugin configuration errors, or audit security policies across gateway entities.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    description: |
      Operation type: `"list"` or `"get_by_id"`
  - parameter: "`plugin_id`"
    type: string
    description: |
      Plugin UUID. Required when `operation="get_by_id"`
{% endtable %}

<!-- vale on -->

**Returns:** Plugin objects with `id`, `name`, `enabled` status, configuration, and scope associations (service, route, consumer).


## GetVault

Retrieves vault configurations for secrets management. List all vaults, get details by UUID or name, or troubleshoot credential access. Use this tool to troubleshoot authentication failures due to expired credentials, verify vault configuration and secret rotation policies, audit secrets management across control planes, or identify which vault provider stores specific credentials.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    description: |
      Operation type: `"list"`, `"get_by_id"`, or `"get_by_name"`
  - parameter: "`vault_id`"
    type: string
    description: |
      Vault UUID. Required when `operation="get_by_id"`
  - parameter: "`vault_name`"
    type: string
    description: |
      Vault name. Required when `operation="get_by_name"`
{% endtable %}

<!-- vale on -->

**Returns:** Vault objects with `id`, `name`, `prefix`, `provider`, and configuration details.


## GetAnalytics

Retrieves API request analytics and statistics. Query API requests with filters, analyze traffic patterns, or monitor performance metrics. Use this tool to identify error trends and spikes in failed requests, analyze consumer-specific traffic patterns and usage, investigate performance degradation over time, monitor API health and identify high-latency endpoints, or track rate limiting violations and throttled requests.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`time_range`"
    type: string
    description: |
      Time window: `"15M"`, `"1H"`, `"6H"`, `"12H"`, `"24H"`, or `"7D"`
  - parameter: "`operation`"
    type: string
    description: |
      Operation type: `"query_api_requests"` or `"get_consumer_requests"`
  - parameter: "`status_codes`"
    type: list of integers
    description: |
      HTTP status codes to include (for `query_api_requests`)
  - parameter: "`excluded_status_codes`"
    type: list of integers
    description: |
      HTTP status codes to exclude (for `query_api_requests`)
  - parameter: "`http_methods`"
    type: list of strings
    description: |
      HTTP methods to include (for `query_api_requests`)
  - parameter: "`consumer_ids`"
    type: list of strings
    description: |
      Consumer IDs to filter by (for `query_api_requests`)
  - parameter: "`service_ids`"
    type: list of strings
    description: |
      Service IDs to filter by (for `query_api_requests`)
  - parameter: "`route_ids`"
    type: list of strings
    description: |
      Route IDs to filter by (for `query_api_requests`)
  - parameter: "`consumer_id`"
    type: string
    description: |
      Specific consumer ID. Required when `operation="get_consumer_requests"`
  - parameter: "`successOnly`"
    type: boolean
    description: |
      Return only successful requests (200-299) (for `get_consumer_requests`)
  - parameter: "`failureOnly`"
    type: boolean
    description: |
      Return only failed requests (≥400) (for `get_consumer_requests`)
  - parameter: "`max_results`"
    type: integer
    description: |
      Maximum number of results (default: 100)
{% endtable %}

<!-- vale on -->

**Returns:**
- For `query_api_requests`: Detailed request data with metadata, latency breakdowns, and trace identifiers
- For `get_consumer_requests`: Aggregated statistics and per-request details for a specific consumer


## CreateDebugSession

Creates a targeted tracing session to collect real-time performance data. Requires user confirmation before starting. Use this tool to investigate slow API responses and identify latency bottlenecks, debug intermittent 500 errors in production, analyze plugin execution order and performance impact, trace request flow through multiple services, or capture detailed timing for specific endpoints.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`http_path`"
    type: string
    description: |
      API endpoint path (e.g., `/checkout`, `/api/users`)
  - parameter: "`http_method`"
    type: string
    description: |
      HTTP method: `"GET"`, `"POST"`, `"PUT"`, `"DELETE"`, `"PATCH"`
  - parameter: "`http_status_code`"
    type: string
    description: |
      Status code filter (e.g., `"500"`, `"404"`)
  - parameter: "`http_latency`"
    type: string
    description: |
      Latency threshold in format `">=XYms"` (e.g., `">=1000ms"`)
  - parameter: "`service_id`"
    type: string
    description: Service UUID to filter traces
  - parameter: "`session_duration`"
    type: integer
    description: |
      Duration in seconds (default: 60)
  - parameter: "`max_samples`"
    type: integer
    description: |
      Maximum number of traces to collect (default: 100)
{% endtable %}

<!-- vale on -->

**Returns:** `debug_session_id` for use with ActiveTracingSession tool.

{:.warning}
> Using `CreateDebugSession` requires user confirmation before starting. The session must complete before data can be analyzed.


## ActiveTracingSession

Performs operations on active tracing sessions for debugging and analysis. Use this tool to monitor debug session progress and wait for completion, identify which plugin adds the most latency, analyze request and response flow through gateway, filter traces by specific plugins to isolate issues, or generate performance summary reports.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    description: Control plane UUID
  - parameter: "`debug_session_id`"
    type: string
    description: Debug session UUID from CreateDebugSession
  - parameter: "`operation`"
    type: string
    description: |
      Operation: `"fetch_status"`, `"summarize_session"`, `"compact_traces"`, `"compressed_traces"`, or `"stop_session"`
  - parameter: "`phase_filter`"
    type: string
    description: |
      Plugin UUID to filter traces. Used with `operation="compact_traces"`
  - parameter: "`phase`"
    type: string
    description: |
      Trace phase filter: `"ingress"` or `"egress"`. Used with `operation="compact_traces"`
{% endtable %}

<!-- vale on -->

**Available operations:**

- `fetch_status`: Returns session status (`"in_progress"`, `"completed"`, `"timed_out"`, `"cancelled"`, or `"pending"`)
- `summarize_session`: Returns aggregated span-level metrics, latency analysis, and bottleneck identification
- `compact_traces`: Returns detailed trace data in compacted format with optional filtering
- `compressed_traces`: Returns unique traces in compacted format
- `stop_session`: Stops an active session immediately

{:.info}
> Return value varies by operation.

## KnowledgeBaseSearch

Searches Kong documentation and knowledge base for configuration guidance and best practices. Use this tool to find plugin configuration examples, look up best practices for rate limiting or authentication, search for troubleshooting steps for specific errors, get guidance on gateway deployment patterns, or learn about new features and capabilities.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - parameter: "`query`"
    type: string
    description: Natural language question or search topic
{% endtable %}

<!-- vale on -->

**Returns:** Plain text documentation excerpts with configuration examples and procedures.

## Hierarchical dependencies

Many tools follow a hierarchical dependency pattern where entity identifiers are required to access nested resources:

```
control_plane_id (root level)
├── consumer_id
├── consumer_group_id
├── service_id
├── route_id
├── plugin_id
├── vault_id
└── debug_session_id
```

Start with GetControlPlane to identify the correct control plane, then use the `control_plane_id` for downstream operations.