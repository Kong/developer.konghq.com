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
  q: How do I expose a REST API as MCP tools in {{site.ai_gateway}}?
  a: Create an MCP Server entity that exposes REST endpoints as MCP tools. Each tool definition includes method, path, and parameter mappings to route requests to the upstream API.

tools:
  - konnect-api

prereqs:
  inline:
    - title: WeatherAPI account
      content: |
        1. Go to [WeatherAPI](https://www.weatherapi.com/).
        1. Navigate to [your dashboard](https://www.weatherapi.com/my/) and copy your API key.
        1. Export your API key by running the following command in your terminal:
           ```sh
           export DECK_WEATHERAPI_API_KEY='your-weatherapi-api-key'
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

Create an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity that exposes the [WeatherAPI](https://www.weatherapi.com/) through a single MCP tool:

- `get-current-weather`

This tool maps to the WeatherAPI `/v1/current.json` endpoint and accepts a location query parameter.

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/mcp-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Weather API
  name: weather-mcp
  type: conversion-listener
  enabled: true
  policies: []
  acl_attribute_type: consumer
  acls:
    allow:
      - __never_match__
  default_tool_acls:
    deny:
      - __never_match__
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
          - $DECK_WEATHERAPI_API_KEY
      parameters:
        - name: q
          in: query
          required: true
          schema:
            type: string
          description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
{% endkonnect_api_request %}
<!-- vale on -->

## Validate the MCP Server

List tools:

```sh
curl -i -X POST http://localhost:8000/weather \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

You should see output similar to:

```text
event: message
data: {"jsonrpc":"2.0","result":{"tools":[{"name":"get-current-weather"}]},"id":1}
```
{:.no-copy-code}

Call `get-current-weather`:

```sh
curl -i -X POST http://localhost:8000/weather \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"get-current-weather",
      "arguments":{
        "query_q":"London"
      }
    }
  }'
```

You should see output similar to:

```text
event: message
data: {"jsonrpc":"2.0","result":{"isError":false,"content":[{"type":"text","text":"{\"location\": {\"name\": \"London\", \"region\": \"City of London\", \"country\": \"United Kingdom\"}, \"current\": {\"temp_c\": 15.2, \"condition\": {\"text\": \"Partly cloudy\"}}}"}]},"id":1}
```
{:.no-copy-code}

You can also validate the routed upstream path directly:

```sh
curl -i "http://localhost:8000/weather?q=London"
```
