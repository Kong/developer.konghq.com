---
title: Map the Deck of Cards API to an MCP Server
content_type: how_to
permalink: /ai-gateway/get-started-with-mcp-server/
description: Learn how to create an MCP Server entity in {{site.ai_gateway}} to expose Deck of Cards API operations as MCP tools
products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0.0'

entities:
  - ai-mcp-server

tags:
  - get-started
  - ai
  - mcp

tldr:
  q: How do I expose a REST API as MCP tools in {{site.ai_gateway}}?
  a: Create an MCP Server entity with route-backed tool paths that map REST endpoints to MCP tools.

tools:
  - konnect-api

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/

cleanup:
  inline:
    - title: Clean up {{site.konnect_product_name}} environment
      include_content: md/ai-gateway/v2/cleanup/konnect

---

## Create an MCP Server entity

Create an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity that exposes the [Deck of Cards API](https://deckofcardsapi.com/) through three MCP tools:

- `shuffle-cards`
- `draw-cards`
- `shuffle-and-draw`

This example uses route-backed tool paths. Each tool path includes the public Route prefix `/cards-api`.

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/mcp-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Deck of Cards API
  name: cards-api-mcp
  type: conversion-listener
  enabled: true
  policies: []
  acl_attribute_type: consumer
  acls:
    deny:
      - __never_match__
  default_tool_acls:
    deny:
      - __never_match__
  config:
    url: https://deckofcardsapi.com/api/deck
    route:
      paths:
        - /cards-api
    logging:
      payloads: true
      statistics: true
      audits: true
    max_request_body_size: 16384
  tools:
    - name: shuffle-cards
      description: Shuffle a new deck of cards. Returns a deck_id to use with draw-cards.
      method: GET
      path: /cards-api/new/shuffle/
      parameters:
        - name: deck_count
          in: query
          required: false
          description: Number of decks to use. Default is 1. Blackjack typically uses 6.
          schema:
            type: integer
            default: 1
    - name: draw-cards
      description: Draw cards from an existing deck. Requires a deck_id from shuffle-cards.
      method: GET
      path: /cards-api/{deck_id}/draw/
      parameters:
        - name: deck_id
          in: path
          required: true
          description: Deck ID returned from shuffle-cards.
          schema:
            type: string
        - name: count
          in: query
          required: true
          description: Number of cards to draw.
          schema:
            type: integer
            default: 1
    - name: shuffle-and-draw
      description: Create a new shuffled deck and draw cards in one request.
      method: GET
      path: /cards-api/new/draw/
      parameters:
        - name: count
          in: query
          required: true
          description: Number of cards to draw.
          schema:
            type: integer
            default: 1
{% endkonnect_api_request %}
<!-- vale on -->

## Validate the MCP Server

List tools:

```sh
curl -i -X POST http://localhost:8000/cards-api \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

You should see output similar to:

```text
event: message
data: {"jsonrpc":"2.0","result":{"tools":[{"name":"draw-cards"},{"name":"shuffle-and-draw"},{"name":"shuffle-cards"}]},"id":1}
```
{:.no-copy-code}

Call `shuffle-cards`:

```sh
curl -i -X POST http://localhost:8000/cards-api \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"shuffle-cards",
      "arguments":{
        "query_deck_count":1
      }
    }
  }'
```

You should see output similar to:

```text
event: message
data: {"jsonrpc":"2.0","result":{"isError":false,"content":[{"type":"text","text":"{\"success\": true, \"deck_id\": \"9wnoi6yk00pu\", \"remaining\": 52, \"shuffled\": true}"}]},"id":1}
```
{:.no-copy-code}

Use the returned `deck_id` to call `draw-cards`:

```sh
curl -i -X POST http://localhost:8000/cards-api \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"draw-cards",
      "arguments":{
        "path_deck_id":"9wnoi6yk00pu",
        "query_count":2
      }
    }
  }'
```

You can also validate the routed upstream path directly:

```sh
curl -i http://localhost:8000/cards-api/new/shuffle/
```
