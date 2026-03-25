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


## DatasourceConfig

Discovers available metrics, dimensions, and filter fields for {{site.konnect_short_name}} analytics datasources. 
Call this tool first before using `query_analytics`, `query_llm_analytics`, `query_mcp_analytics`, or `query_api_requests` to learn what fields are valid for each datasource.

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
  - parameter: "`datasource`"
    type: string
    description: |
      Optional datasource name to filter results: `"api_usage"`, `"llm_usage"`, `"mcp_usage"`, or `"requests"`. Returns all datasources if omitted.
{% endtable %}

<!-- vale on -->

**Returns:** Per datasource: `metrics`, `dimensions`, `filterable_fields` (with value types and supported operators), and the `tool` to use for that datasource. 
Also returns `org_config` with data retention and percentile availability.


## QueryExploreTimeRange

Resolves a time range to effective start/end timestamps and minimum granularity for a {{site.konnect_short_name}} analytics datasource. 
Use this after `datasource_config` and before an explore query when you need to understand the exact resolved time window or choose a valid granularity. 
Use `query_analytics`, `query_llm_analytics`, or `query_mcp_analytics` for aggregate questions before using this tool.

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
  - parameter: "`datasource`"
    type: string
    description: |
      The analytics datasource to query: `"api-usage"`, `"llm-usage"`, or `"mcp-usage"`. Defaults to `"api-usage"`.
  - parameter: "`time_range`"
    type: object
    description: |
      Required. Time range to check. Contains:
      - `type` (required): `"relative"` or `"absolute"`
      - `time_range`: Relative range (for example, `"15m"`, `"1h"`, `"6h"`, `"12h"`, `"24h"`, `"7d"`, `"30d"`, `"current_week"`, `"current_month"`, `"previous_week"`, `"previous_month"`). Required when `type="relative"`
      - `start`: ISO 8601 start time. Required when `type="absolute"`
      - `end`: ISO 8601 end time. Required when `type="absolute"`
      - `tz`: IANA timezone (defaults to `Etc/UTC`)
{% endtable %}

<!-- vale on -->

**Returns:** Resolved `start`, `end`, and `min_granularity_ms` for the selected datasource and time range.


## QueryAnalytics

Queries {{site.konnect_short_name}} analytics data for aggregated API traffic metrics over time. 
Use this to answer questions about API traffic patterns, error rates, latency, and throughput. 
Call `datasource_config` first to discover valid metrics, dimensions, and filter fields for the `api_usage` datasource. 
Use this explore-style query before `query_api_requests` or `get_consumer_requests`.

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
    type: object
    description: |
      Required. 
      Time range for the query. 
      Contains:
      - `type` (required): `"relative"` or `"absolute"`
      - `time_range`: Relative range (for example, `"15m"`, `"1h"`, `"6h"`, `"12h"`, `"24h"`, `"7d"`, `"30d"`, `"current_week"`, `"current_month"`, `"previous_week"`, `"previous_month"`). Required when `type="relative"`
      - `start`: ISO 8601 start time. Required when `type="absolute"`
      - `end`: ISO 8601 end time. Required when `type="absolute"`
      - `tz`: IANA timezone (defaults to `Etc/UTC`)
  - parameter: "`metrics`"
    type: list of strings
    description: |
      Metrics to aggregate. 
      Call `datasource_config` to discover valid metric names. 
      Defaults to `request_count` if omitted.
  - parameter: "`dimensions`"
    type: list of strings
    description: |
      Dimensions to group results by (maximum of two). 
      Call `datasource_config` to discover valid dimension names. 
      Adding dimensions can expand response size.
  - parameter: "`filters`"
    type: list of objects
    description: |
      Filters to narrow results. 
      Each filter contains:
      - `field` (required): Dimension to filter on. Call `datasource_config` to discover valid filter fields
      - `operator` (required): `"in"`, `"not_in"`, `"selector"`, `"empty"`, or `"not_empty"`
      - `value`: Array of values for `in`/`not_in`/`selector`. Omit for `empty`/`not_empty`
  - parameter: "`granularity`"
    type: string
    description: |
      Time bucket size for results: 
      * `"tenSecondly"`
      * `"thirtySecondly"`
      * `"minutely"`
      * `"fiveMinutely"`
      * `"tenMinutely"`
      * `"thirtyMinutely"`
      * `"hourly"`
      * `"twoHourly"`
      * `"twelveHourly"`
      * `"daily"`
      * `"weekly"`
      * `"trend"`
      
      Use `tenSecondly` and `thirtySecondly` only for short windows.
  - parameter: "`limit`"
    type: integer
    description: |
      Maximum number of grouped series to return (1–5000). 
      Limits top groups, not time buckets within each group. 
      Defaults to `10` when dimensions are provided.
  - parameter: "`descending`"
    type: boolean
    description: |
      Sort order for results. Defaults to `true`.
{% endtable %}

<!-- vale on -->

**Returns:** Time-bucketed aggregated metrics with `meta` and `data` arrays. 
Responses exceeding 500 rows are truncated, with `meta.truncated` set to `true` and guidance on how to narrow the query.


## QueryLLMAnalytics

Queries {{site.konnect_short_name}} LLM/AI analytics data for aggregated metrics over time. 
Use this to answer questions about AI/LLM API usage, token consumption, costs, and latency. 
Call `datasource_config` first to discover valid metrics, dimensions, and filter fields for the `llm_usage` datasource. 
For general API traffic metrics, use `query_analytics` instead.

Uses the same parameters as [QueryAnalytics](#queryanalytics).

**Returns:** Time-bucketed aggregated LLM metrics with `meta` and `data` arrays. 
Responses exceeding 500 rows are truncated, with `meta.truncated` set to `true` and guidance on how to narrow the query.


## QueryMCPAnalytics

Queries {{site.konnect_short_name}} MCP (Model Context Protocol) analytics data for aggregated metrics over time. 
Use this to answer questions about MCP server traffic, tool usage, session activity, and errors. 
Call `datasource_config` first to discover valid metrics, dimensions, and filter fields for the `mcp_usage` datasource. 
For general API traffic without MCP dimensions, use `query_analytics` instead.

Uses the same parameters as [QueryAnalytics](#queryanalytics).

**Returns:** Time-bucketed aggregated MCP metrics with `meta` and `data` arrays. 
Responses exceeding 500 rows are truncated, with `meta.truncated` set to `true` and guidance on how to narrow the query.


## QueryAPIRequests

Queries individual API request logs from {{site.konnect_short_name}}. 
Use this only when you need to inspect a narrow set of raw requests, find specific failures, or examine per-request details after aggregate explore queries are no longer sufficient. 
Call `datasource_config` with `datasource="requests"` first to discover valid filter fields. 
Use `query_analytics`, `query_llm_analytics`, or `query_mcp_analytics` first for aggregate questions.

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
    type: object
    description: |
      Required. 
      Time range for the query. 
      Relative ranges use uppercase values. Contains:
      - `type` (required): `"relative"` or `"absolute"`
      - `time_range`: Relative range: `"15M"`, `"1H"`, `"6H"`, `"12H"`, `"24H"`, or `"7D"`. Required when `type="relative"`
      - `start`: ISO 8601 start time. Required when `type="absolute"`
      - `end`: ISO 8601 end time. Required when `type="absolute"`
      - `tz`: IANA timezone (defaults to `Etc/UTC`)
  - parameter: "`filters`"
    type: list of objects
    description: |
      Filters to narrow results. 
      Each filter contains:
      - `field` (required): Field to filter on. Call `datasource_config` with `datasource="requests"` to discover valid fields
      - `operator` (required): `"in"`, `"not_in"`, `"selector"`, `"="`, `"!="`, `"<"`, `">"`, `"<="`, `">="`, `"starts_with"`, `"ends_with"`, `"empty"`, or `"not_empty"`
      - `value`: Array for `in`/`not_in`/`selector`, scalar for equality/comparison. Omit for `empty`/`not_empty`
  - parameter: "`order`"
    type: string
    description: |
      Sort order by timestamp: `"ascending"` or `"descending"`. Defaults to `"descending"`.
  - parameter: "`size`"
    type: integer
    description: |
      Number of request-log rows to return in this response page (1–1000). 
      Keep this small when possible as records are wide and consume context quickly.
  - parameter: "`cursor`"
    type: string
    description: |
      Base64 cursor from a previous response page for pagination.
{% endtable %}

<!-- vale on -->

**Returns:** Paginated request-log rows with metadata, latency breakdowns, and trace identifiers.


## GetConsumerRequests

Gets Consumer-focused request summaries and samples. Use this when asking specifically about one Consumer's request patterns, success/failure mix, latency, or affected services. 
Use `query_analytics` first for high-level traffic or trend questions, and use specific filters to reduce data volume.

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
  - parameter: "`consumer_id`"
    type: string
    description: Required. Consumer UUID to inspect.
  - parameter: "`time_range`"
    type: string
    description: |
      Required. Relative time range for the query: `"15M"`, `"1H"`, `"6H"`, `"12H"`, `"24H"`, or `"7D"`
  - parameter: "`successOnly`"
    type: boolean
    description: |
      If `true`, returns only successful requests (`2xx`). 
      Mutually exclusive with `failureOnly`.
  - parameter: "`failureOnly`"
    type: boolean
    description: |
      If `true`, returns only failed requests (`4xx`/`5xx`). 
      Mutually exclusive with `successOnly`.
  - parameter: "`max_results`"
    type: integer
    description: |
      Maximum number of results to return (1–1000). 
      Keep this small when possible as records are wide and consume context quickly. 
      Defaults to `100`.
{% endtable %}

<!-- vale on -->

**Returns:** Aggregated statistics and per-request details for the specified consumer.


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