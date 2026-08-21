---
title: Aggregate MCP tools from multiple AI MCP Server entities
content_type: how_to
related_resources:
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: Map a RESTful API to MCP tools
    url: /ai-gateway/map-api-to-mcp-tools/
  - text: Map the WeatherAPI to an MCP Server
    url: /ai-gateway/get-started-with-mcp-server/

description: Aggregate MCP tools from multiple RESTful APIs into a single MCP endpoint using AI MCP Server entities in conversion-only and listener modes

products:
  - ai-gateway

permalink: /ai-gateway/aggregate-mcp-tools/

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-mcp-server

tags:
  - ai
  - mcp

tldr:
  q: How do I aggregate MCP tools from multiple RESTful APIs into one MCP endpoint?
  a: |
    Create one [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity per RESTful API in `conversion-only` mode. Then create a `listener` AI MCP Server and list the mcp servers as sources. It merges every matching source's tools into a single MCP endpoint and routes each tool call to the correct backend.

    This tutorial shows you how to aggregate tools from a mock Petstore API and the Deck of Cards API using kongctl, and validate the aggregated endpoint.

tools:
  - kongctl

prereqs:
  inline:
    - title: Petstore API
      include_content: prereqs/third-party/swagger-petstore

cleanup:
  inline:
    - title: Stop Petstore API
      include_content: cleanup/third-party/swagger-petstore
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

## Convert the Deck of Cards API to MCP tools

Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity in `conversion-only` mode for the [Deck of Cards API](https://deckofcardsapi.com/), which needs no credentials. 

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: cards-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: cards-mcp
    display_name: "Deck of Cards"
    type: conversion-only
    enabled: true
    config:
      url: https://deckofcardsapi.com
      route:
        paths:
          - /api/deck
        strip_path: false
    tools:
      - name: shuffle-cards
        description: Shuffle a new deck of cards. Returns a deck_id to use with draw-cards.
        method: GET
        path: /api/deck/new/shuffle/
        parameters:
          - name: deck_count
            in: query
            required: false
            schema:
              type: integer
              default: 1
            description: Number of decks to use (default 1, blackjack typically uses 6)
      - name: draw-cards
        description: Draw cards from an existing deck. Requires a deck_id from shuffle-cards.
        method: GET
        path: "/api/deck/{deck_id}/draw/"
        parameters:
          - name: deck_id
            in: path
            required: true
            schema:
              type: string
            description: Deck ID returned from shuffle-cards
          - name: count
            in: query
            required: true
            schema:
              type: integer
              default: 1
            description: Number of cards to draw
      - name: new-deck
        description: Create a new deck.
        method: GET
        path: /api/deck/new/
{% endentity_examples %}

## Convert the Petstore API to MCP tools

Create a second AI MCP Server entity in `conversion-only` mode for the mock Petstore API.

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: petstore-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: petstore-mcp
    display_name: "Petstore API"
    type: conversion-only
    enabled: true
    policies: []
    config:
      url: http://host.docker.internal:8080/api/v3
      route:
        paths:
          - /petstore
      logging:
        payloads: false
      server:
        timeout: 60000
    tools:
      - name: get-pets-by-status
        description: Find pets by status
        method: GET
        path: /petstore/pet/findByStatus
        parameters:
          - name: status
            in: query
            required: true
            schema:
              type: string
              enum:
                - available
                - pending
                - sold
            description: Status value to filter pets by
      - name: get-pet-by-id
        description: Get a pet by ID
        method: GET
        path: /petstore/pet/{petId}
        parameters:
          - description: ID of the pet to retrieve
            in: path
            name: petId
            required: true
            schema:
              type: integer
{% endentity_examples %}

## Aggregate the MCP tools

Create a fourth AI MCP Server entity in `listener` mode. Its `sources` contains the list of the mcp servers we want to aggregate, so the listener discovers them, merges their tools into a single list, and exposes them through one MCP endpoint.

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: mcp-aggregation
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: mcp-aggregation
    display_name: "Aggregated MCP tools"
    type: listener
    config:
      route:
        paths:
          - /mcp-aggregation
    sources:
      - cards-mcp
      - petstore-mcp
{% endentity_examples %}

## Verify that the aggregated endpoint has all the tools

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/mcp-aggregation \
    --transport http --method tools/list |  jq -r '.tools[].name'
expected:
  return_code: 0
render_output: false
message: |
  draw-cards
  get-pet-by-id
  get-pets-by-status
  shuffle-and-draw
  shuffle-cards
{% endvalidation %}
<!--vale on-->

You should see the following output:

```text
draw-cards
get-pet-by-id
get-pets-by-status
shuffle-and-draw
shuffle-cards
```
{:.no-copy-code}

## Validate the aggregated tools

You can now test tools from each source through the single aggregated endpoint.

{% navtabs "validate-aggregated-mcp-tools" %}
{% navtab "Petstore tools" %}

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/mcp-aggregation \
    --transport http --method tools/call \
    --tool-name get-pet-by-id \
    --tool-arg path_petId=7 | jq -r '.content[0].text' | jq -c '.'
expected:
  return_code: 0
message: |
  {"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
render_output: false
{% endvalidation %}
<!--vale on-->

You should see the following response:

```text
{"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
```
{:.no-copy-code}

{% endnavtab %}
{% navtab "Deck of Cards tools" %}

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/mcp-aggregation \
    --transport http --method tools/call \
    --tool-name new-deck \
    | jq -c 'with_entries(select(.key == "success"))'
expected:
  return_code: 0
render_output: false
message: |
  {"success":true}
{% endvalidation %}
<!--vale on-->

You should see the following response:

```text
{"success":true}
```
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}
