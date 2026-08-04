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
    Create one [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity per RESTful API in `conversion-only` mode, and give each the same `labels.ai-gateway-mcp-aggregation` value. Then create a `listener` AI MCP Server carrying the same label. It merges every matching source's tools into a single MCP endpoint and routes each tool call to the correct backend.

    This tutorial shows you how to aggregate tools from a mock marketplace API, WeatherAPI, and the Deck of Cards API using kongctl, and validate the aggregated endpoint with ChatWise.

tools:
  - kongctl

prereqs:
  inline:
    - title: Mock marketplace API
      include_content: md/ai-gateway/v2/prereqs/marketplace-mock-api
    - title: WeatherAPI account
      include_content: md/ai-gateway/v2/prereqs/weather-api
    - title: OpenAI API key
      content: |
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
      icon_url: /assets/icons/openai.svg
    - title: ChatWise desktop application
      content: |
        Download and install [ChatWise](https://chatwise.app/) for your OS.

        After installation:
        1. Launch the app.
        1. Navigate to the app's settings.
        1. Click **Providers** in the sidebar.
        1. In the Providers sidebar, click **OpenAI**.
        1. In the **API Key** field, enter your OpenAI API key.

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---

## Convert the Deck of Cards API to MCP tools

Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity in `conversion-only` mode for the [Deck of Cards API](https://deckofcardsapi.com/), which needs no credentials. Set `labels.ai-gateway-mcp-aggregation` so the listener you create later can discover it.

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: cards-mcp
    ai_gateway: !lookup name:ai-quickstart
    name: cards-mcp
    display_name: "Deck of Cards"
    type: conversion-only
    enabled: true
    labels:
      ai-gateway-mcp-aggregation: payments
    config:
      url: https://deckofcardsapi.com
      route:
        paths:
          - /cards-api-mcp
    tools:
      - name: shuffle-cards
        description: Shuffle a new deck of cards. Returns a deck_id to use with draw-cards.
        method: GET
        path: api/deck/new/shuffle/
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
        path: "api/deck/{deck_id}/draw/"
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
      - name: shuffle-and-draw
        description: Create a new shuffled deck and draw cards in one request.
        method: GET
        path: api/deck/new/draw/
        parameters:
          - name: count
            in: query
            required: true
            schema:
              type: integer
              default: 1
            description: Number of cards to draw
{% endentity_examples %}

## Convert the marketplace API to MCP tools

Create a second AI MCP Server entity in `conversion-only` mode for the mock marketplace API, tagged with the same `labels.ai-gateway-mcp-aggregation` value.

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: marketplace-mcp
    ai_gateway: !lookup name:ai-quickstart
    name: marketplace-mcp
    display_name: "Marketplace API"
    type: conversion-only
    enabled: true
    labels:
      ai-gateway-mcp-aggregation: payments
    config:
      url: http://host.docker.internal:3000
      route:
        paths:
          - /marketplace
      logging:
        audits: true
    tools:
      - name: get-users
        description: Get users
        method: GET
        path: /marketplace/users
        parameters:
          - name: id
            in: query
            required: false
            schema:
              type: string
            description: Optional user ID
      - name: get-orders-for-user
        description: Get orders for a user
        method: GET
        path: /marketplace/orders
        parameters:
          - name: userid
            in: query
            required: true
            schema:
              type: string
            description: User ID to filter orders
{% endentity_examples %}

## Convert WeatherAPI to MCP tools

Create a third AI MCP Server entity in `conversion-only` mode for [WeatherAPI](https://www.weatherapi.com/), tagged with the same `labels.ai-gateway-mcp-aggregation` value.

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: weather-mcp
    ai_gateway: !lookup name:ai-quickstart
    name: weather-mcp
    display_name: "Weather API"
    type: conversion-only
    enabled: true
    labels:
      ai-gateway-mcp-aggregation: payments
    config:
      url: https://api.weatherapi.com/v1/current.json
      route:
        paths:
          - /weather-internet-mcp
    tools:
      - name: weather-internet
        description: Get current weather for a location
        method: GET
        query:
          key:
            - !env WEATHERAPI_API_KEY
        parameters:
          - name: q
            in: query
            required: true
            schema:
              type: string
              default: London
            description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
{% endentity_examples %}

## Aggregate the MCP tools

Create a fourth AI MCP Server entity in `listener` mode. Its `config.server.label` points at the same `ai-gateway-mcp-aggregation: payments` label used on the three `conversion-only` entities, so the listener discovers them, merges their tools into a single list, and exposes them through one MCP endpoint.

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: mcp-aggregation
    ai_gateway: !lookup name:ai-quickstart
    name: mcp-aggregation
    display_name: "Aggregated MCP tools"
    type: listener
    config:
      route:
        paths:
          - /mcp-aggregation
      server:
        label:
          ai-gateway-mcp-aggregation:payments
{% endentity_examples %}

## Connect ChatWise to the aggregated endpoint

1. In the ChatWise app, navigate to settings.
1. Click **MCP** in the sidebar.
1. Click the **+** button.
1. Select "HTTP Server (http)".
1. In the **Name** field, enter `mcp-aggregation`.
1. In the **URL** field, enter `http://localhost:8000/mcp-aggregation`.
1. Click **Verify (View Tools)** to confirm the connection. You should see the following tools listed:
   - `get-users`
   - `get-orders-for-user`
   - `weather-internet`
   - `shuffle-cards`
   - `draw-cards`
   - `shuffle-and-draw`
1. Close the settings window.

## Validate the aggregated tools

You can now test tools from each source through the single aggregated endpoint.

1. In ChatWise, start a new chat.
1. Click the overflow (**...**) menu next to the chat input, then click the **hammer icon** to enable MCP tools. The icon turns blue when enabled.
1. From the hammer dropdown menu, enable `mcp-aggregation`, you should see 6 tools associated with it.


{% navtabs "validate-aggregated-mcp-tools" %}
{% navtab "Marketplace tools" %}

Enter the following in the ChatWise chat:

```text
What has Alice Johnson ordered?
```

ChatWise calls two tools exposed by the `marketplace-mcp` source in sequence: `get-users` to find Alice's ID, then `get-orders-for-user` to fetch her orders. Approve each tool call when prompted.

When the agent finishes reasoning, you should see a response like the following:

```text
To check Alice Johnson's orders, I need her user ID. Here's how we can proceed:

Find Alice Johnson's ID: I'll first search for her user record to get the correct ID.
Fetch Orders: Once I have the ID, I'll retrieve her order history.
Let me start by searching for her user details.

Alice Johnson's user ID is a1b2c3d4. Now, I'll retrieve her order history.

a1b2c3d4
Alice Johnson has placed the following orders:

Sugar (50kg)
Cleaning Supplies Pack
Canned Tomatoes (100 cans)
```
{:.no-copy-code}

{% endnavtab %}
{% navtab "Weather tools" %}

Enter the following in the ChatWise chat:

```text
What is the current weather in Alexandria?
```

ChatWise calls the `weather-internet` tool exposed by the `weather-mcp` source. Approve the tool call when prompted:

```text
> called weather-internet
```
{:.no-copy-code}

When the agent finishes reasoning, you should see a response like the following:

```text
Alexandria, Egypt right now:

- Temperature: 79°F (26.1°C), feels like 80°F (26.8°C)
- Condition: Sunny
- Wind: 7.4 mph NNW
- Humidity: 61%

Warm and sunny with light NNW winds.
```
{:.no-copy-code}

{% endnavtab %}
{% navtab "Deck of Cards tools" %}

Enter the following in the ChatWise chat:

```text
Shuffle a new deck and draw 5 cards.
```

ChatWise calls the `shuffle-and-draw` tool exposed by the `cards-mcp` source. Approve the tool call when prompted:

```text
> called shuffle-and-draw
```
{:.no-copy-code}

When the agent finishes reasoning, you should see a response like the following:

```text
Here are your 5 cards:

10 of Spades
Queen of Hearts
4 of Clubs
Ace of Diamonds
7 of Hearts
```
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}
