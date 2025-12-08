---
title: "{{site.konnect_product_name}} MCP Server"
description: "Interact with Kong {{site.konnect_product_name}} through AI clients using MCP tools. Access gateway entities, debug API performance, and search documentation."
content_type: reference
layout: reference
products:
  - konnect
tags:
  - ai
  - mcp
search_aliases:
  - ai assistant
works_on:
  - konnect
breadcrumbs:
  - /konnect/
  - /konnect-platform/kai/
permalink: /konnect-platform/konnect-mcp/

beta: true

related_resources:
  - text: "About Kong's AI assistant"
    url: /konnect-platform/kai/
  - text: "{{site.konnect_short_name}} Platform"
    url: /konnect/

faqs:
  - q: How should I structure my tool workflows?
    a: |
      Start with GetControlPlane to identify the correct control plane before accessing nested resources. For `get_by_name` operations that return no results, fall back to `list` and perform fuzzy matching. Always confirm CreateDebugSession parameters with the user before starting, and check `fetch_status` until the session reaches `"completed"` before analyzing traces.

  - q: What IDs should I extract for downstream tool use?
    a: |
      Extract these IDs as you work through tool chains: `control_plane_id`, `debug_session_id`, `consumer_id`, `service_id`, `route_id`. Use `debug_session_inputs` from FetchAlertingEventDetails directly with CreateDebugSession for optimal alert investigation.

  - q: How can I improve tool performance?
    a: |
      Apply specific filters in GetAnalytics to reduce data volume and improve response times. Check entity `enabled` flags when troubleshooting, as disabled entities can cause failures.

  - q: I'm experiencing authentication errors. What should I check?
    a: |
      Verify PAT validity, check your organization hasn't disabled MCP access, and ensure the token has required permissions.

  - q: I can't connect to the MCP server. What should I do?
    a: |
      Check your internet connection, verify the regional server URL is correct, and ensure your firewall isn't blocking `mcp.konghq.com`.

  - q: A tool doesn't appear in my tool list. Why?
    a: |
      Verify you have the required permissions, check your organization has the necessary entitlements, confirm feature flags are enabled, and restart your MCP client.

  - q: Tools return empty results for resources I know exist. What's wrong?
    a: |
      Verify you're connecting to the correct regional server URL, check which region your resources are deployed in via the {{site.konnect_product_name}} UI, and restart your MCP client after URL changes.

  - q: Tool execution is failing. How do I troubleshoot?
    a: |
      Check parameter correctness, verify you have resource access permissions, wait if you're rate limited, and confirm the resource exists.
---

The {{site.konnect_product_name}} MCP Server enables developers to interact with Kong {{site.konnect_product_name}} through AI assistants and IDE copilots using the Model Context Protocol (MCP). Access gateway entities, debug API performance, and search Kong documentation from your development environment.

Many tools in {{site.konnect_product_name}} MCP Server power [KAi (Kong's AI assistant)](/konnect/kai/), which provides an in-product experience for {{site.konnect_product_name}} Plus and Enterprise accounts.

{:.info}
> {{site.konnect_product_name}} MCP server is in active development. Expect continuous updates and new tools to be added regularly.

## Use cases

The {{site.konnect_product_name}} MCP Server enables several workflows for managing and debugging your API infrastructure:

- **Gateway Entity management** <br> Query control planes, services, routes, consumers, consumer groups, plugins, and vaults. List all resources or look up specific entities by ID or name.

- **API debugging** <br> Create debug sessions with active tracing to investigate performance issues, latency problems, or errors. Analyze collected traces to identify bottlenecks and receive actionable recommendations.

- **Analytics and monitoring**<br> Query API request data with filters for time range, status codes, consumers, services, and routes. Analyze traffic patterns and investigate error trends.

- **Alert-driven investigation**<br> Fetch detailed context from Kong alerting events to understand what triggered an alert. Use pre-configured debug session parameters for immediate investigation.

- **Kong Documentation search**<br> Search Kong's documentation for configuration guidance, troubleshooting steps, and best practices without leaving your development environment.

## Authentication

To use the {{site.konnect_product_name}} MCP Server authentication, you will need a Personal Access Token for authentication: Create a new personal access token by opening the [{{site.konnect_product_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

### Organization settings

{{site.konnect_product_name}} MCP Server access is **enabled by default**. Organization administrators can disable it from Organization Settings. When disabled, authentication attempts return "access denied".

{:.info}
>**KAi Integration**
> Enabling KAi automatically enables MCP server access. Disabling MCP server also disables KAi.


## Regional server endpoints

The MCP server is deployed regionally. Connect to the server in the same region where your x resources are deployed.

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

{:.info}
> The regional endpoint for {{site.konnect_product_name}} MCP Server defaults to US region.
>
> Organizations using multiple {{site.konnect_product_name}} regions need separate MCP server connections for each region. Resources cannot be accessed across regions from a single connection.

## Installation

Configure the MCP client of your choice by adding the {{site.konnect_product_name}} MCP Server with your regional URL and PAT.

{% navtabs "mcp-client-installation" %}
{% navtab "Claude Code CLI" %}

**Using the `claude mcp add` command:**

```bash
claude mcp add --transport http kong-konnect https://us.mcp.konghq.com/ \
  --header "Authorization: Bearer YOUR_KONNECT_PAT"
```

{:.ino}
> Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual Personal Access Token.

You can also configure editing the configuration file directly:**

Claude CLI stores its configuration in `~/.claude.json` (or `.mcp.json` for project scope):

```json
{
  "mcpServers": {
    "kong-konnect": {
      "type": "http",
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

Verify the configuration. List all configured servers:

```bash
claude mcp list
```

Get details for the Kong {{site.konnect_product_name}} server

```bash
claude mcp get kong-konnect
```
{% endnavtab %}
{% navtab "Visual Studio Code" %}

1. Open Visual Studio Code
2. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
3. Type "MCP" and select "MCP: Configure Servers"
4. Add the Kong {{site.konnect_product_name}} server configuration:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

5. Replace `https://us.mcp.konghq.com/` with your regional server URL
6. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
7. Save the configuration file
8. Reload VS Code window (Command Palette > "Developer: Reload Window")
9. Open the AI assistant and verify Kong {{site.konnect_product_name}} tools are available

{% endnavtab %}
{% navtab "Cursor" %}

1. Open your Cursor desktop app
2. Navigate to Settings in the top right corner (gear icon)
3. In the Cursor Settings tab, go to Tools & MCP in the left sidebar
4. In the Installed MCP Servers section, click "New MCP Server"
5. Paste the following JSON configuration into the newly opened `mcp.json` tab:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

6. Replace `https://us.mcp.konghq.com/` with your regional server URL
7. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
8. Save the configuration file
9. Return to the Cursor settings tab. You should now see the `kong-konnect` MCP server with available tools listed
10. To open a new Cursor chat, press `Cmd+L` (Mac) or `Ctrl+L` (Windows/Linux)
11. In the Cursor chat tab, click `@` Add Context and select tools from the Kong {{site.konnect_product_name}} server

{% endnavtab %}
{% navtab "GitHub Copilot - VS Code" %}

1. Open Visual Studio Code
2. Ensure GitHub Copilot extension is installed and configured
3. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
4. Type "MCP" and select "MCP: Configure Servers"
5. Add the Kong {{site.konnect_product_name}} server configuration:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

6. Replace `https://us.mcp.konghq.com/` with your regional server URL
7. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
8. Save the configuration file
9. Reload VS Code window (Command Palette > "Developer: Reload Window")
10. Open GitHub Copilot chat and verify Kong {{site.konnect_product_name}} tools are available

{% endnavtab %}
{% navtab "GitHub Copilot - JetBrains" %}

**For IntelliJ IDEA, PyCharm, WebStorm, and other JetBrains IDEs:**

1. Open your JetBrains IDE
2. Navigate to Settings/Preferences (`Cmd+,` on Mac, `Ctrl+Alt+S` on Windows/Linux)
3. Go to Tools > GitHub Copilot > MCP Servers
4. Click the "+" button to add a new server
5. Enter the server details:
   - **Name**: Kong {{site.konnect_product_name}}
   - **URL**: `https://us.mcp.konghq.com/` (or your regional URL)
   - **Transport**: SSE
   - **Authentication**: Bearer Token
   - **Token**: Your {{site.konnect_product_name}} PAT
6. Click "OK" to save
7. Restart your IDE
8. Invoke GitHub Copilot and verify Kong {{site.konnect_product_name}} tools are available

**Manual Configuration:**

If your JetBrains IDE doesn't provide the UI option, edit the configuration file at:
`~/.config/JetBrains/<IDE>/mcp-servers.json`

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual token, then restart your IDE.

{% endnavtab %}
{% navtab "Manual Configuration" %}

**For Visual Studio:**

1. Open Visual Studio
2. Navigate to Tools > Options
3. Expand GitHub > Copilot
4. Select "MCP Servers"
5. Click "Add"
6. Configure the server:
   - **Name**: Kong {{site.konnect_product_name}}
   - **Server URL**: `https://us.mcp.konghq.com/` (or your regional URL)
   - **Transport Type**: Server-Sent Events
   - **Authentication**: Bearer Token
   - **Token**: Your {{site.konnect_product_name}} PAT
7. Click "OK" to save
8. Restart Visual Studio
9. Open GitHub Copilot chat and verify Kong {{site.konnect_product_name}} tools are available

**Configuration File Location:**
`%LOCALAPPDATA%\Microsoft\VisualStudio\<Version>\Extensions\mcp-config.json`

**For Eclipse and Other IDEs:**

If your IDE doesn't provide a UI for MCP configuration, manually edit the configuration file:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

**Configuration file locations:**
- **Eclipse**: `.metadata/.plugins/org.eclipse.core.runtime/.settings/com.github.copilot.prefs`
- **Other IDEs**: Consult your IDE's GitHub Copilot documentation for the MCP configuration file location

Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual token, then restart your IDE.

{% endnavtab %}
{% endnavtabs %}

## Available tools

The following tools are available in the current release. Tool availability depends on your user permissions and organization entitlements.

### `GetControlPlane`

Retrieves control plane information. List all control planes, get details by UUID or display name, or identify which control plane serves a specific API path.

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation type: "`\"list\"`", `\"get_by_id\"`, `\"get_by_name\"`, or `\"get_by_route\"`
  - parameter: "`id`"
    type: string
    required: Conditional
    description: |
      Control plane UUID. Required when `operation=\"get_by_id\"`
  - parameter: "`name`"
    type: string
    required: Conditional
    description: |
      Control plane display name. Required when `operation=\"get_by_name\"`
  - parameter: "`path`"
    type: string
    required: Conditional
    description: |
      API route path (e.g., `/api/users`). Required when `operation=\"get_by_route\"`
{% endtable %}

<!-- vale on -->

This tool returns Control plane objects with `id`, `name`, and `tags`. The `id` field should be extracted as `control_plane_id` for downstream tools.


### `GetControlPlaneGroup`

Retrieves control planes within a specific control plane group.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_group_id`"
    type: string
    required: Yes
    description: UUID of the control plane group
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Must be `"list"`
{% endtable %}

<!-- vale on -->
This tool returns Array of control plane objects with `id`, `name`, and `tags`.


### `GetConsumer`

Retrieves API consumer information for a control plane. List all consumers, get details by UUID or username, or investigate authentication issues.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation type: "`"list"`", `"get_by_id"`, or `"get_by_name"`
  - parameter: "`consumer_id`"
    type: string
    required: Conditional
    description: |
      Consumer UUID. Required when `operation="get_by_id"`
  - parameter: "`consumer_name`"
    type: string
    required: Conditional
    description: |
      Consumer username. Required when `operation="get_by_name"`
{% endtable %}
<!-- vale on -->

This tool returns Consumer objects with `id`, `username`, `custom_id`, and `tags`. Use `username` for human communication and `id` when calling GetPlugin.


### `GetConsumerGroup`

Retrieves consumer group information for a control plane.

<!-- vale off -->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Must be `"list"`
{% endtable %}
<!-- vale on -->

This tool returns an array of consumer group objects with `id`, `name`, `created_at`, and `tags`.


### `GetService`

Retrieves upstream service configurations for a control plane. List all services, get details by UUID or name, or troubleshoot connectivity issues.

<!-- vale off -->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation type: "`"list"`", `"get_by_id"`, or `"get_by_name"`
  - parameter: "`service_id`"
    type: string
    required: Conditional
    description: |
      Service UUID. Required when `operation="get_by_id"`
  - parameter: "`service_name`"
    type: string
    required: Conditional
    description: |
      Service name. Required when `operation="get_by_name"`
{% endtable %}
<!-- vale on -->

This tool returns Service objects with upstream configuration (host, port, protocol, timeouts, retries, certificates).


### `GetRoute`

Retrieves route configurations for a control plane. List all routes, get configuration by UUID or name, or investigate routing issues.

<!-- vale off -->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation type: "`"list"`", `"get_by_id"`, or `"get_by_name"`
  - parameter: "`route_id`"
    type: string
    required: Conditional
    description: |
      Route UUID. Required when `operation="get_by_id"`
  - parameter: "`route_name`"
    type: string
    required: Conditional
    description: |
      Route display name. Required when `operation="get_by_name"`
{% endtable %}

<!-- vale on -->
This tool returns Route objects with path mappings, HTTP methods, and service associations.


### `GetPlugin`

Retrieves plugin configurations for a control plane. List all plugins, get configuration by UUID, or troubleshoot plugin issues.

<!-- vale off -->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation type: "`"list"`" or `"get_by_id"`
  - parameter: "`plugin_id`"
    type: string
    required: Conditional
    description: |
      Plugin UUID. Required when `operation="get_by_id"`
{% endtable %}
<!-- vale on -->

This tool returns plugin objects with `id`, `name`, `enabled` status, configuration, and scope associations (service, route, consumer).


### `GetVault`

Retrieves vault configurations for secrets management. List all vaults, get details by UUID or name, or troubleshoot credential access.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation type: "`"list"`", `"get_by_id"`, or `"get_by_name"`
  - parameter: "`vault_id`"
    type: string
    required: Conditional
    description: |
      Vault UUID. Required when `operation="get_by_id"`
  - parameter: "`vault_name`"
    type: string
    required: Conditional
    description: |
      Vault name. Required when `operation="get_by_name"`
{% endtable %}

<!-- vale on -->
This tool returns Vault objects with `id`, `name`, `prefix`, `provider`, and configuration details.


### `GetAnalytics`

Retrieves API request analytics and statistics. Query API requests with filters, analyze traffic patterns, or monitor performance metrics.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`time_range`"
    type: string
    required: Yes
    description: |
      Time window: `"15M"`, `"1H"`, `"6H"`, `"12H"`, `"24H"`, or `"7D"`
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation type: "`"query_api_requests"`" or `"get_consumer_requests"`
  - parameter: "`status_codes`"
    type: list of integers
    required: No
    description: |
      HTTP status codes to include (for `query_api_requests`)
  - parameter: "`excluded_status_codes`"
    type: list of integers
    required: No
    description: |
      HTTP status codes to exclude (for `query_api_requests`)
  - parameter: "`http_methods`"
    type: list of strings
    required: No
    description: |
      HTTP methods to include (for `query_api_requests`)
  - parameter: "`consumer_ids`"
    type: list of strings
    required: No
    description: |
      Consumer IDs to filter by (for `query_api_requests`)
  - parameter: "`service_ids`"
    type: list of strings
    required: No
    description: |
      Service IDs to filter by (for `query_api_requests`)
  - parameter: "`route_ids`"
    type: list of strings
    required: No
    description: |
      Route IDs to filter by (for `query_api_requests`)
  - parameter: "`consumer_id`"
    type: string
    required: Conditional
    description: |
      Specific consumer ID. Required when `operation="get_consumer_requests"`
  - parameter: "`successOnly`"
    type: boolean
    required: No
    description: |
      Return only successful requests (200-299) (for `get_consumer_requests`)
  - parameter: "`failureOnly`"
    type: boolean
    required: No
    description: |
      Return only failed requests (≥400) (for `get_consumer_requests`)
  - parameter: "`max_results`"
    type: integer
    required: No
    description: |
      Maximum number of results (default: 100)
{% endtable %}
<!-- vale on -->

This tool returns
- For `query_api_requests`: Detailed request data with metadata, latency breakdowns, and trace identifiers
- For `get_consumer_requests`: Aggregated statistics and per-request details for a specific consumer


### `CreateDebugSession`

Creates a targeted tracing session to collect real-time performance data. Requires user confirmation before starting.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`http_path`"
    type: string
    required: No
    description: |
      API endpoint path (e.g., `/checkout`, `/api/users`)
  - parameter: "`http_method`"
    type: string
    required: No
    description: |
      HTTP method: `"GET"`, `"POST"`, `"PUT"`, `"DELETE"`, `"PATCH"`
  - parameter: "`http_status_code`"
    type: string
    required: No
    description: |
      Status code filter (e.g., `"500"`, `"404"`)
  - parameter: "`http_latency`"
    type: string
    required: No
    description: |
      Latency threshold in format `">=XYms"` (e.g., `">=1000ms"`)
  - parameter: "`service_id`"
    type: string
    required: No
    description: Service UUID to filter traces
  - parameter: "`session_duration`"
    type: integer
    required: No
    description: |
      Duration in seconds (default: 60)
  - parameter: "`max_samples`"
    type: integer
    required: No
    description: |
      Maximum number of traces to collect (default: 100)
{% endtable %}

<!-- vale on -->
This tool returns `debug_session_id` for use with ActiveTracingSession tool.

{:.warning}
> Using `CreateDebugSession` requires user confirmation before starting. The session must complete before data can be analyzed.


### `ActiveTracingSession`

Performs operations on active tracing sessions for debugging and analysis.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`control_plane_id`"
    type: string
    required: Yes
    description: Control plane UUID
  - parameter: "`debug_session_id`"
    type: string
    required: Yes
    description: Debug session UUID from CreateDebugSession
  - parameter: "`operation`"
    type: string
    required: Yes
    description: |
      Operation: `"fetch_status"`, `"summarize_session"`, `"compact_traces"`, `"compressed_traces"`, or `"stop_session"`
  - parameter: "`plugin_filter`"
    type: string
    required: No
    description: |
      Plugin UUID to filter traces. Used with `operation="compact_traces"`
  - parameter: "`phase`"
    type: string
    required: No
    description: |
      Trace phase filter: `"ingress"` or `"egress"`. Used with `operation="compact_traces"`
{% endtable %}

<!-- vale on -->

Available operations:

- `fetch_status`: Returns session status (`"in_progress"`, `"completed"`, `"timed_out"`, `"cancelled"`, or `"pending"`)
- `summarize_session`: Returns aggregated span-level metrics, latency analysis, and bottleneck identification
- `compact_traces`: Returns detailed trace data in compacted format with optional filtering
- `compressed_traces`: Returns unique traces in compacted format
- `stop_session`: Stops an active session immediately

{:.info}
> Return value varies by operation.

### `FetchAlertingEventDetails`

Retrieves detailed context for Kong alerting events for root cause analysis.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`alert_event_id`"
    type: string
    required: Yes
    description: Alert event UUID from notification
{% endtable %}

<!-- vale on -->
This tool returns AlertEvent object with:
- Affected entity details (`control_plane_id`, `entity_id`, `entity_type`)
- Optional `debug_session_inputs` with pre-configured parameters for CreateDebugSession


### `KnowledgeBaseSearch`

Searches Kong documentation and knowledge base for configuration guidance and best practices.

<!-- vale off -->

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Type
    key: type
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - parameter: "`query`"
    type: string
    required: Yes
    description: Natural language question or search topic
{% endtable %}

<!-- vale on -->
This tool returns plain text documentation excerpts with configuration examples and procedures.

## Hierarchical dependencies between tools

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