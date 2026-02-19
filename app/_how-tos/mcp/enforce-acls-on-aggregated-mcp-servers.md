---
title: Enforce ACLs on aggregated MCP servers
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/
  - text: Control MCP tool access with Consumer and Consumer Group ACLs
    url: /mcp/use-access-controls-for-mcp-tools/
  - text: Aggregate MCP tools from multiple AI MCP Proxy plugins
    url: /mcp/aggregate-mcp-tools/

description: Restrict access to aggregated MCP tools using Consumer Groups. This guide shows how to define per-tool ACLs on conversion-only plugins and enforce them through a listener with the `include_consumer_groups` setting.

products:
  - ai-gateway
  - gateway

permalink: /mcp/enforce-acls-on-aggregated-mcp-servers/

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-mcp-proxy
  - key-auth
  - request-transformer-advanced

entities:
  - service
  - route
  - plugin
  - consumer
  - consumer_group

tags:
  - ai
  - mcp

tldr:
  q: How do I enforce ACLs on MCP tools aggregated from multiple sources?
  a: |
    Configure the AI MCP Proxy plugin in `listener` mode with `include_consumer_groups: true`
    on your aggregation route. Define per-tool ACLs on individual conversion-only routes.
    The listener enforces these ACLs based on the authenticated Consumer's group membership.

tools:
  - deck

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
  entities:
    services:
      - weather-internet-service
      - deck-of-cards
    routes:
      - weather-internet-mcp
      - cards-api-mcp
      - mcp-aggregation

automated_tests: false
---

In this how-to, you'll restrict access to aggregated MCP tools using Consumer Groups. This allows you to define per-tool ACLs on conversion-only plugins and enforce them through a listener with the `include_consumer_groups` setting.

## Set up Consumer authentication

Configure authentication so {{site.base_gateway}} can identify each caller. Use the [Key Auth](/plugins/key-auth/) plugin so each user (or AI agent) presents an API key with requests:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      route: mcp-aggregation
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Create Consumer Groups for each access tier

Configure [Consumer Groups](/gateway/entities/consumer-group/) that reflect access levels. These groups govern MCP tool permissions:
- `gold-partner` - full access to all tools
- `silver-partner` - full access to all tools
- `bronze-partner` - blocked from MCP tools
- no group (`eason` user) - blocked from MCP tools

{% entity_examples %}
entities:
  consumer_groups:
    - name: gold-partner
    - name: silver-partner
    - name: bronze-partner
{% endentity_examples %}

## Create Consumers

Configure individual [Consumers](/gateway/entities/consumer/) and assign them to groups. Consumers here can represent the humans or agents using the MCP tools. Each Consumer uses a unique API key and inherits group permissions which govern access to MCP tools:

{% entity_examples %}
entities:
  consumers:
    - username: alice
      groups:
        - name: gold-partner
      keyauth_credentials:
        - key: alice-key

    - username: bob
      groups:
        - name: silver-partner
      keyauth_credentials:
        - key: bob-key

    - username: carol
      groups:
        - name: bronze-partner
      keyauth_credentials:
        - key: carol-key

    - username: eason
      keyauth_credentials:
        - key: eason-key
{% endentity_examples %}

## Configure the WeatherAPI MCP tool

In this how-to, we'll use the WeatherAPI to demonstrate how you can enforce access limits on aggregated MCP servers by configuring it as an MCP tool.

### Add an API key using the Request Transformer Advanced plugin

To authenticate to WeatherAPI, configure the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin. This plugin automatically appends your API key to the query string so that all requests are authenticated.

{% entity_examples %}
entities:
  plugins:
    - name: request-transformer-advanced
      service: weather-internet-service
      config:
        add:
          querystring:
            - key:${key}
variables:
  key:
    value: $WEATHERAPI_API_KEY
{% endentity_examples %}

### Configure the AI MCP Proxy plugin for WeatherAPI

Configure the AI MCP Proxy plugin in `conversion-only` mode to convert the WeatherAPI endpoint into an MCP tool and define access controls. The `tags` field enables the listener to discover this tool during aggregation. The `acl` block specifies which Consumer Groups can call this tool.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: weather-internet-mcp
      tags:
        - ai-gateway-mcp-aggregation
      config:
        mode: conversion-only
        logging:
          log_audits: true
          log_payloads: true
          log_statistics: true
        tools:
          - name: weather-internet
            description: Get current weather for a location
            method: GET
            path: "./v1/current.json"
            acl:
              allow:
                - gold-partner
                - silver-partner
              deny:
                - bronze-partner
            parameters:
              - name: q
                in: query
                required: true
                description: "Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name."
                schema:
                  type: string
                  default: London
{% endentity_examples %}

## Configure the Deck of Cards MCP tools

Configure the [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin in `conversion-only` mode to convert the [Deck of Cards API](https://deckofcardsapi.com/) endpoints into MCP tools. Each tool has its own ACL configuration.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: cards-api-mcp
      tags:
        - ai-gateway-mcp-aggregation
      config:
        mode: conversion-only
        logging:
          log_audits: true
          log_payloads: true
          log_statistics: true
        max_request_body_size: 16384
        tools:
          - name: shuffle-cards
            description: Shuffle a new deck of cards. Returns a deck_id to use with draw-cards.
            method: GET
            path: "/cards-api/new/shuffle/"
            acl:
              allow:
                - gold-partner
                - silver-partner
              deny:
                - bronze-partner
            parameters:
              - name: deck_count
                in: query
                required: false
                description: "Number of decks to use (default 1, blackjack typically uses 6)"
                schema:
                  type: integer
                  default: 1
          - name: draw-cards
            description: Draw cards from an existing deck. Requires a deck_id from shuffle-cards.
            method: GET
            path: "/cards-api/{deck_id}/draw/"
            acl:
              allow:
                - gold-partner
                - silver-partner
              deny:
                - bronze-partner
            parameters:
              - name: deck_id
                in: path
                required: true
                description: "Deck ID returned from shuffle-cards"
                schema:
                  type: string
              - name: count
                in: query
                required: true
                description: "Number of cards to draw"
                schema:
                  type: integer
                  default: 1
          - name: shuffle-and-draw
            description: Create a new shuffled deck and draw cards in one request.
            method: GET
            path: "./new/draw/"
            acl:
              allow:
                - gold-partner
                - silver-partner
              deny:
                - bronze-partner
            parameters:
              - name: count
                in: query
                required: true
                description: "Number of cards to draw"
                schema:
                  type: integer
                  default: 1
{% endentity_examples %}

## Configure the listener AI MCP Proxy plugin

Configure the AI MCP Proxy plugin in `listener` mode to aggregate and expose the tools registered by the conversion-only plugins. The listener discovers tools based on their shared tag value and serves them through an MCP server that AI clients can connect to.

The `include_consumer_groups: true` setting is essential. Without it, the listener cannot pass Consumer Group membership to the aggregated tools, and ACL rules will not evaluate correctly.

The table below shows the effective permissions for the configuration:

<!-- vale off -->
{% table %}
columns:
  - title: MCP Tool
    key: tool
  - title: gold-partner
    key: gold
  - title: silver-partner
    key: silver
  - title: bronze-partner
    key: bronze
  - title: No group
    key: none

rows:
  - tool: "`weather-internet`"
    gold: Yes
    silver: Yes
    bronze: No
    none: No
  - tool: "`shuffle-cards`"
    gold: Yes
    silver: Yes
    bronze: No
    none: No
  - tool: "`draw-cards`"
    gold: Yes
    silver: Yes
    bronze: No
    none: No
  - tool: "`shuffle-and-draw`"
    gold: Yes
    silver: Yes
    bronze: No
    none: No
{% endtable %}
<!-- vale on -->

The following plugin configuration applies the ACL rules for the MCP tools shown in the table above:

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: mcp-aggregation
      tags:
        - ai-gateway-mcp-aggregation
      config:
        mode: listener
        include_consumer_groups: true
        server:
          tag: ai-gateway-mcp-aggregation
          timeout: 45000
        logging:
          log_audits: true
          log_statistics: true
          log_payloads: true
        max_request_body_size: 32768
{% endentity_examples %}

## Validate the configuration

Use [ChatWise](https://chatwise.app/) to validate the ACL configuration. ChatWise is an AI chat client that supports MCP servers. You should've already [downloaded and installed ChatWise](#chatwise-desktop-application) in the prerequisites for this how-to.

### Configure ChatWise

1. In the ChatWise app, navigate to settings.
1. Click **MCP** in the sidebar.
1. Click the **+** button.
1. Select "HTTP Server (http)".
1. In the **Name** field, enter `aggregated-mcp`.
1. In the **URL** field, enter `http://localhost:8000/mcp/aggregation`.
1. Next to **HTTP headers**, click **+**.
1. In the **Key** field, enter `apikey`.
1. In the **Value** field, enter `alice-key`.
1. Click **Verify (View Tools)** to confirm the connection. You should see the following tools listed:
   - `draw-cards`
   - `shuffle-and-draw`
   - `shuffle-cards`
   - `weather-internet`
1. Close the settings window.

### Test tool access

Now verify access for each user by updating the API key in the MCP server settings:

{% navtabs "validate-mcp-access" %}
{% navtab "Alice (gold-partner)" %}

Alice belongs to the **gold-partner** group and has access to all tools.

1. In ChatWise, start a new chat.
1. In the chat input area, click the **hammer icon** to enable MCP tools. The icon turns blue when enabled.
1. From the hammer dropdown menu, enable your MCP server.
1. Enter the following in the ChatWise chat:

   ```text
   Shuffle cards
   ```

1. ChatWise should call the `shuffle-cards` tool and respond with the deck ID:

   ```text
   The deck has been successfully shuffled. The new deck ID is xucbyje9gmy5.
   Let me know how many cards you would like to draw!
   ```
   {:.no-copy-code}

1. Enter the following in the ChatWise chat:

   ```text
   Draw 1 card.
   ```

1. ChatWise should call the `draw-cards` tool and display the drawn card with its image:
   ```text
   The card drawn from the deck is the Queen of Hearts
   ```
   {:.no-copy-code}

1. Enter the following in the ChatWise chat:
   ```text
   What's the weather in London
   ```

1. ChatWise should call the `weather-internet` tool and respond with the current weather:

   ```text
   The current weather in London is as follows:
   - Temperature: 7.2°C (45.0°F)
   - Condition: Light rain
   - Wind: 14.1 mph (22.7 kph) from the south-southeast
   - Humidity: 100%
   ```
   {:.no-copy-code}


{% endnavtab %}

{% navtab "Carol (bronze-partner)" %}

Carol belongs to the **bronze-partner** group, which is explicitly denied access to all tools.

1. In the ChatWise MCP settings, set the `apikey` header value to `carol-key`.
1. Start a new chat.
1. Enter the following in the ChatWise chat:
   ```text
   Shuffle cards
   ```

1. The tool call should fail. ChatWise will display:
   ```text
   It seems there is a restriction preventing me from shuffling the cards at the moment.
   Unfortunately, I'm unable to proceed with this request. Please try again later.
   ```
   {:.no-copy-code}


{% endnavtab %}
{% navtab "Eason (no group)" %}

   Eason is not part of any group and no tools explicitly allow ungrouped consumers.

1. In the ChatWise MCP settings, set the `apikey` header value to `eason-key`.
1. Start a new chat.
1. Enter the following in the ChatWise chat:
   ```text
   What's the weather in Berlin
   ```

1. The tool call should fail with a restriction message.


{% endnavtab %}
{% endnavtabs %}