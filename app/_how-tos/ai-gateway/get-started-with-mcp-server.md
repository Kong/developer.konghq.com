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

    This tutorial shows you how to set up an AI MCP Server to expose the [WeatherAPI](https://openweathermap.org/api/one-call-4?collection=one_call_api) in {{site.konnect_product_name}} using the {{site.konnect_product_name}} API and how to proxy your first MCP request.

tools:
  - konnect-api
  # - kongctl # re-enable once kongctl supports tools[].query and tools[].parameters on ai_gateway.mcp_servers

prereqs:
  inline:
    # kongctl prereq disabled: kongctl's ai_gateway.mcp_servers.tools schema doesn't yet support
    # the query/parameters fields this tutorial's tool needs. Re-enable once it does.
    # - title: kongctl
    #   content: |
    #     This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

    #     1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
    #     1. Verify the installation:

    #        ```sh
    #        kongctl version
    #        ```
    #     1. Adopt your {{site.ai_gateway}} into a kongctl namespace so the apply command later in this tutorial can manage it:

    #        ```sh
    #        kongctl adopt ai-gateway "$AI_GATEWAY_ID" \
    #          --namespace weather-mcp \
    #          --pat "$KONNECT_TOKEN"
    #        ```
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

Create an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity that exposes the [WeatherAPI](https://www.weatherapi.com/) through a single MCP tool called `get-current-weather`.

This tool maps to the WeatherAPI `/v1/current.json` endpoint and accepts a location query parameter.

<!--
kongctl apply disabled: ai_gateway.mcp_servers.tools in kongctl's declarative schema
doesn't yet support the query/parameters fields this tool needs. Re-enable once
kongctl adds support (see kongctl explain ai_gateway.mcp_servers -o json).

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: weather-mcp

ai_gateways:
  - ref: weather-ai-gateway
    id: "$AI_GATEWAY_ID"
    mcp_servers:
      - ref: weather-mcp
        type: conversion-listener
        name: weather-mcp
        display_name: "Weather API"
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
            statistics: true
          server:
            timeout: 60000
        tools:
          - name: get-current-weather
            description: Get current weather for a location
            method: GET
            path: /weather
            query:
              key:
                - $WEATHERAPI_API_KEY
            parameters:
              - name: q
                in: query
                required: true
                schema:
                  type: string
                description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
EOF
```
-->

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/mcp-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: "Weather API"
  name: weather-mcp
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
      statistics: true
    server:
      timeout: 60000
  tools:
    - name: get-current-weather
      description: Get current weather for a location
      method: GET
      path: /weather
      query:
        key:
          - $WEATHERAPI_API_KEY
      parameters:
        - name: q
          in: query
          required: true
          schema:
            type: string
          description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the MCP Server with:

* `type: conversion-listener`: Converts the WeatherAPI REST endpoint into an MCP tool that clients can call directly.
* `config.url` and `config.route.paths`: The upstream API endpoint and the path clients use to reach it over MCP.
* `tools`: Maps the WeatherAPI `/v1/current.json` endpoint to the `get-current-weather` tool. The `query.key` parameter injects your WeatherAPI credentials automatically, so clients never handle the API key.
* `access`: Sets ACLs that gate which [AI Consumers](/ai-gateway/entities/ai-consumer/) can access the server and its tools.

## Validate the MCP Server

{{site.ai_gateway}} implements the MCP [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#streamable-http). Before you can call a tool, you need to open a session against the MCP Server's route.

### Open a session

Send an `initialize` request to the route configured on the MCP Server (`/weather`), capturing the `Mcp-Session-Id` response header into an environment variable:

```sh
SESSION_ID=$(curl -s -o /dev/null -D - -X POST http://localhost:8000/weather \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-06-18",
      "capabilities": {},
      "clientInfo": {
        "name": "weather-mcp-test",
        "version": "1.0.0"
      }
    }
  }' | grep -i '^mcp-session-id:' | tr -d '\r' | cut -d' ' -f2)
export SESSION_ID
echo "SESSION_ID=$SESSION_ID"
```

Complete the handshake with a `notifications/initialized` notification, carrying the session ID:

```sh
curl -i -X POST http://localhost:8000/weather \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: $SESSION_ID" \
  --data '{"jsonrpc":"2.0","method":"notifications/initialized"}'
```

A `202 Accepted` response confirms the session is ready. Carry the `Mcp-Session-Id` header on the following requests to match standard MCP client behavior.

### Call the tool

List the available tools to confirm the `get-current-weather` tool and inspect its `inputSchema`:

```sh
curl -X POST http://localhost:8000/weather \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: $SESSION_ID" \
  --data '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
```

The `q` parameter you configured is exposed to MCP clients as `query_q`. For `conversion-listener` and `conversion-only` MCP Servers, the generated `inputSchema` names each converted REST parameter `{in}_{name}`, not the bare configured name. Call the tool with that argument name:

```sh
curl -X POST http://localhost:8000/weather \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: $SESSION_ID" \
  --data '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "get-current-weather",
      "arguments": {
        "query_q": "London"
      }
    }
  }'
```

The response includes the current conditions for London:

```text
event: message
data: {"id":3,"result":{"content":[{"type":"text","text":"{\"location\":{\"name\":\"London\",\"region\":\"City of London, Greater London\",\"country\":\"United Kingdom\",...},\"current\":{...,\"condition\":{\"text\":\"Sunny\",...},\"temp_c\":27.3,\"temp_f\":81.1,...}}"}],"isError":false},"jsonrpc":"2.0"}
```
{:.no-copy-code.wrap}
