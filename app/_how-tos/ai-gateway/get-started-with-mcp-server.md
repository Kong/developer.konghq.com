---
title: Map the WeatherAPI to an MCP Server
content_type: how_to
permalink: /ai-gateway/get-started-with-mcp-server/
description: Learn how to create an MCP Server entity in {{site.ai_gateway}} to expose WeatherAPI operations as MCP tools
products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-mcp-server

tags:
  - get-started
  - ai
  - mcp

tldr:
  q: How do I expose REST APIs as MCP tools in {{site.ai_gateway}}?
  a: |
    {{site.ai_gateway}} provides first-class MCP Server entities in {{site.konnect_product_name}} that expose REST APIs as tools for MCP-compatible clients.
    Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity configured as a `conversion-listener` to convert REST endpoints into MCP tools that clients can call directly, without managing API credentials.

    This tutorial shows you how to set up an AI MCP Server to expose the [WeatherAPI](https://openweathermap.org/api/one-call-4?collection=one_call_api) in {{site.konnect_product_name}} using [kongctl](/kongctl/), and how to proxy your first MCP request.

tools:
  - kongctl

prereqs:
  inline:
    - title: WeatherAPI account
      content: |
        1. Go to [WeatherAPI](https://www.weatherapi.com/).
        1. Navigate to [your dashboard](https://www.weatherapi.com/my/) and copy your API key.
        1. Export your API key by running the following command in your terminal:
           ```sh
           export WEATHERAPI_API_KEY='your-weatherapi-api-key'
           ```
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---

## Create an MCP Server entity

Create an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity that exposes the [WeatherAPI](https://www.weatherapi.com/) through a single MCP tool called `get-current-weather`, mapped from the WeatherAPI `/v1/current.json` endpoint. `tools[].query.key` injects your WeatherAPI credentials automatically, so clients never handle the API key:

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: weather-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: weather-mcp
    display_name: "Weather API"
    type: conversion-listener
    enabled: true
    policies: []
    access:
      acl_attribute_type: consumer
      acls:
        allow: []
      default_tool_acls:
        deny: []
    config:
      url: https://api.weatherapi.com/v1/current.json
      route:
        paths:
          - /weather
      logging:
        payloads: false
        audits: true
      server:
        timeout: 60000
    tools:
      - name: get-current-weather
        description: Get current weather for a location
        method: GET
        path: /weather
        query:
          key:
            - !env WEATHERAPI_API_KEY
        parameters:
          - name: q
            in: query
            required: true
            schema:
              type: string
            description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
{% endentity_examples %}

## Validate the MCP Server

{{site.ai_gateway}} implements the MCP [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#streamable-http). Before you can call a tool, you need to open a session against the MCP Server's route.

### Open a session

Send an `initialize` request to the route configured on the MCP Server (`/weather`), capturing the `Mcp-Session-Id` response header into an environment variable:

<!-- vale off -->
{% validation request-check %}
url: /weather/
method: POST
status_code: 200
retry: true
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
display_headers: true
body:
  jsonrpc: '2.0'
  id: 1
  method: initialize
  params:
    protocolVersion: '2025-06-18'
    capabilities: {}
    clientInfo:
      name: weather-mcp-test
      version: '1.0.0'
extract_headers:
    - name: 'mcp-session-id'
      variable: SESSION_ID
capture:
  - variable: SESSION_ID
    command: "grep -i '^mcp-session-id:' | tr -d '\\r' | cut -d' ' -f2"
{% endvalidation %}
<!-- vale on -->

Complete the handshake with a `notifications/initialized` notification, carrying the session ID:

<!-- vale off -->
{% validation request-check %}
url: /weather/
method: POST
display_headers: true
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'Mcp-Session-Id: $SESSION_ID'
body:
  jsonrpc: '2.0'
  method: notifications/initialized
status_code: 202
{% endvalidation %}
<!-- vale on -->

A `202 Accepted` response confirms the session is ready.

### Call the tool

List the available tools to confirm the `get-current-weather` tool exists, and inspect its `inputSchema`. Include the `Mcp-Session-Id` header:

<!-- vale off -->
{% validation request-check %}
url: /weather/
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'Mcp-Session-Id: $SESSION_ID'
body:
  jsonrpc: '2.0'
  id: 2
  method: tools/list
status_code: 200
{% endvalidation %}
<!-- vale on -->

 For `conversion-listener` and `conversion-only` MCP Servers, the generated `inputSchema` names each converted REST parameter `{in}_{name}`, not the bare configured name. Since [you configured](#create-an-mcp-server-entity) the `q` parameter as `name: q` and `in: query`, {{site.ai_gateway}} exposes to MCP clients as `query_q`. Call the tool with that argument name:

<!-- vale off -->
{% validation request-check %}
url: /weather/
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'Mcp-Session-Id: $SESSION_ID'
body:
  jsonrpc: '2.0'
  id: 3
  method: tools/call
  params:
    name: "get-current-weather"
    arguments:
      query_q: "London"
status_code: 200
{% endvalidation %}
<!-- vale on -->

The response includes the current conditions for London:

```text
event: message
data: {"id":3,"result":{"content":[{"type":"text","text":"{\"location\":{\"name\":\"London\",\"region\":\"City of London, Greater London\",\"country\":\"United Kingdom\",...},\"current\":{...,\"condition\":{\"text\":\"Sunny\",...},\"temp_c\":27.3,\"temp_f\":81.1,...}}"}],"isError":false},"jsonrpc":"2.0"}
```
{:.no-copy-code.wrap}
