---
title: "MCP servers in {{site.konnect_catalog}}"
content_type: reference
layout: reference

products:
    - catalog
    - ai-gateway

breadcrumbs:
  - /catalog/

works_on:
  - konnect

search_aliases:
  - mcp

description: An MCP server is an interface in {{site.konnect_catalog}} that represents an MCP server your organization builds or consumes. Learn how to create and manage MCP servers.

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "MCP Registries (tech preview)"
    url: /catalog/mcp-registry/
  - text: "AI Models"
    url: /catalog/ai-models/
---

An MCP server is an interface in {{site.konnect_catalog}} that represents an MCP server your organization builds or consumes.

## How it works

As teams build MCP servers for AI agents, those servers are often embedded directly in agent code, defined in local configuration files, or scattered across repositories, with no shared record of what already exists.
{{site.konnect_catalog}} gives you a single place to see every MCP server across your organization, so you don't have to track each one down in a separate tool to know what it does or how to connect to it.

You can create an MCP server in {{site.konnect_catalog}} in a few ways:
* Define it manually, filling out its details yourself.
* Paste an existing server's JSON definition.
* Import it from {{site.ai_gateway}}, by linking an existing {{site.ai_gateway}} MCP server as the source.
* (Coming soon) Connect to a running MCP server, and have {{site.konnect_short_name}} fetch its definition directly.

When an MCP server is linked to {{site.ai_gateway}}, the link is a snapshot, not a live sync.
If you later change the linked server's configuration in {{site.ai_gateway}}, the MCP server in {{site.konnect_catalog}} isn't automatically updated to match.

## Create an MCP server

Send a POST request to the `/mcp-servers` endpoint to create an empty MCP server:
<!--vale off-->
{% konnect_api_request %}
url: /v1/mcp-servers
status_code: 201
method: POST
body:
    name: my-mcp
    display_name: My MCP
    description: Customer support triage MCP server
extract_body:
    - name: 'id'
      variable: MCP_ID
capture:
  - variable: MCP_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Add the MCP server's capabilities and access methods by sending a POST request to the `/mcp-servers/{mcpId}/versions` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v1/mcp-servers/$MCP_ID/versions
status_code: 201
method: POST
body:
    version: 1.0.0
    tools:
      - name: get_forecast
        description: Multi-day forecast for a location.
        input_schema:
            type: object
    resources: null
    prompts: null
    remotes:
      - type: streamable-http
        url: https://mcp.example.com/weather
    packages: null
{% endkonnect_api_request %}
<!--vale on-->

Link the MCP server to a server on {{site.ai_gateway}} by sending a POST request to the `/mcp-servers/{mcpId}/implementations` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v1/mcp-servers/$MCP_ID/implementations
status_code: 201
method: POST
body:
    implementation:
        type: ai-gateway
        config:
            gateway_control_plane_id: $CONTROL_PLANE_ID
            gateway_mcp_server_id: $GATEWAY_MCP_SERVER_ID
{% endkonnect_api_request %}
<!--vale on-->

{% comment %}
## MCP server analytics

When you create an MCP server in {{site.konnect_catalog}}, you can see analytics for that server in addition to the details you configured.
{% endcomment %}
