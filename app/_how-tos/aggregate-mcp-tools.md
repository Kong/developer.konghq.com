---
title: Aggregate MCP tools from multiple AI MCP Proxy plugins
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/
  - text: Use Insomnia MCP clients to test aggregated MCP tools
    url: /how-to/use-insomnia-mcp-clients-to-test-aggregated-mcp-tools/

description: Learn how to aggregate MCP tools from multiple RESTful APIs using AI MCP Proxy plugins in conversion-only and listener modes.

products:
  - gateway
  - ai-gateway
permalink: /mcp/aggregate-mcp-tools/

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.12'

plugins:
  - ai-mcp-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - mcp

tldr:
  q: How do I aggregate MCP tools from multiple APIs?
  a: |
    Use AI MCP Proxy in conversion-only mode to convert each RESTful API into MCP tools, then configure a listener-mode plugin to aggregate and expose all tools to AI clients. Then, use Cursor, or any other compatible client to validate the aggregated tool calls.

tools:
  - deck

prereqs:
  inline:
    - title: Mock /marketplace API server
      content: |
        Before setting up the first [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin, you need an upstream HTTP API. For this tutorial, use a simple Express-based mock API that simulates a small marketplace with users and their orders. It exposes `/marketplace/users` and `/marketplace/{userId}/orders` endpoints.

        Run the following to download and start the mock API:

        ```sh
        curl -s -o api.js "https://gist.githubusercontent.com/subnetmarco/5ddb23876f9ce7165df17f9216f75cce/raw/a44a947d69e6f597465050cc595b6abf4db2fbea/api.js"
        npm install express
        node api.js
        ```

        Verify it’s running:

        ```sh
        curl -X GET http://localhost:3000
        ```

        You should see:

        ```text
        {"name":"Sample Users API"}%
        ```
        {:.no-copy-code}
    - title: WeatherAPI account
      content: |
        1. Go to [WeatherAPI](https://www.weatherapi.com/).
        1. Navigate to [your dashboard](https://www.weatherapi.com/my/) and copy your API key.
        1. Export your API key by running the following command in your terminal:
           ```sh
           export DECK_WEATHERAPI_API_KEY='your-weatherapi-api-key'
           ```
    - title: FreecurrencyAPI account
      content: |
        1. Go to [FreecurrencyAPI](https://freecurrencyapi.com/).
        1. Sign up for a free account.
        1. Navigate to [your dashboard](https://app.freecurrencyapi.com/dashboard) and copy your API key.
        1. Export your API key by running the following command in your terminal:
           ```sh
           export DECK_FREECURRENCYAPI_API_KEY='your-freecurrencyapi-api-key'
           ```

    - title: MCP Inspector
      content: |
          This tutorial uses the [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) which helps you explore and debug MCP servers.

          1. Ensure you have Node.js and npm installed. If needed, download them from https://nodejs.org.

          1. Update `npx` to the latest version:
              ```sh
              npm install -g npx
              ```
          1. Then install the Inspector:
              ```sh
              npm install -g @modelcontextprotocol/inspector
              ```

      icon_url: /assets/icons/mcp.svg
    - title: Cursor
      content: |
        This tutorial uses Cursor as an MCP client:
        1. Go to the [Cursor downloads](https://cursor.com/downloads) page.
        1. Download the installer for your operating system.
        1. Install Cursor on your machine.
        1. Launch Cursor and sign in to your account or create a new account.
      icon_url: /assets/icons/cursor.svg
  entities:
    services:
      - mcp-service
      - weather-service
      - freecurrency-service
    routes:
      - mcp-route
      - weather-route
      - currency-route
      - listener-route

---

## Configure the first AI MCP Proxy plugin

Let's configure the first AI MCP Proxy plugin to convert its endpoints to MCP tools.
We configure the plugin in `conversion-only` mode because this instance only converts RESTful API paths into MCP tool definitions. It doesn’t handle incoming MCP requests directly. Later, we’ll aggregate these tools from multiple conversion-only instances using listener-mode plugins.

In this configuration we define `tags[]` at the plugin level because listener AI MCP Proxy plugin will use them to discover, aggregate, and expose the registered tools.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      tags:
        - mcp-tools
      route: mcp-route
      config:
        mode: conversion-only
        tools:
        - description: Get users
          method: GET
          path: "/marketplace/users"
          parameters:
          - name: id
            in: query
            required: false
            schema:
              type: string
            description: Optional user ID
        - description: Get orders for a user
          method: GET
          path: "/marketplace/orders"
          parameters:
          - description: User ID to filter orders
            in: query
            name: userid
            required: true
            schema:
              type: string
{% endentity_examples %}

## Configure the second AI MCP Proxy plugin for the WeatherAPI

### Step 1: Add an API key using the Request Transformer Advanced plugin

To authenticate to Weather API, we'll need to configure the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin. This plugin modifies outgoing requests before they reach the upstream API. In this example, it automatically appends your [WeatherAPI](https://www.weatherapi.com/api-explorer.aspx) API key to the query string so that all requests are authenticated without needing to manually provide the key each time.

{% entity_examples %}
entities:
  plugins:
    - name: request-transformer-advanced
      route: weather-route
      enabled: true
      config:
        add:
          querystring:
            - key:${key}
variables:
  key:
    value: $WEATHERAPI_API_KEY
{% endentity_examples %}

### Step 2: Configure the AI MCP Proxy plugin

We can move on to configuring the second AI MCP Proxy plugin. Like the previous marketplace configuration, this instance only converts RESTful paths into tool definitions and doesn’t process MCP requests directly. Again, the `tags[]` field ensures that listener-mode plugins can later discover and aggregate this tool along with others from the marketplace instance.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      tags:
        - mcp-tools
      route: weather-route
      config:
        mode: conversion-only
        tools:
        - description: Get current weather for a location
          method: GET
          path: "/weather"
          parameters:
          - name: q
            in: query
            required: true
            schema:
              type: string
            description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode,
              IP address, latitude/longitude, or city name.
{% endentity_examples %}

## Configure the third AI MCP Proxy plugin for Free Currency

### Step 1: Add an API key using the Request Transformer Advanced plugin

To authenticate requests to the Free Currency API, we use the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin again to append the API key to all requests automatically.

{% entity_examples %}
entities:
  plugins:
    - name: request-transformer-advanced
      route: freecurrency-route
      enabled: true
      config:
        add:
          querystring:
            - apikey:${key}
variables:
  key:
    value: $FREECURRENCYAPI_API_KEY
{% endentity_examples %}

### Step 2: Configure the AI MCP Proxy plugin

As in the previous steps, this AI MCP Proxy instance converts the RESTful paths of [FreecurrencyAPI](https://freecurrencyapi.com/docs/currencies) into tool definitions only. They will be aggregated by the listener-mode plugin based on the `tags[]` field.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: freecurrency-route
      tags:
        - mcp-tools
      config:
        mode: conversion-only
        tools:
          - description: Get latest exchange rates for one or more currencies
            method: GET
            path: "/currency"
            parameters:
              - name: currencies
                in: query
                required: false
                schema:
                  type: string
                description: A comma-separated list of currency codes (e.g., "EUR,USD,CAD").
{% endentity_examples %}

## Configure the listener AI MCP Proxy plugin

Now, let's configure another AI MCP Proxy plugin instance in listener mode to aggregate and expose the tools registered by the conversion-only plugins. The listener plugin discovers tools based on their shared tag value—in this case, `mcp-tools`—and serves them through an MCP server that AI clients can connect to.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: listener-route
      config:
        mode: listener
        server:
          tag: mcp-tools
          timeout: 45000
        logging:
          log_statistics: true
          log_payloads: false
        max_request_body_size: 32768
{% endentity_examples %}

## Validate the configuration

### Run the MCP inspector

First, let's run the MCP Inspector to see whether our listener AI MCP Proxy plugin properly aggregates all exposed tools.

1. Execute the following command to run the MCP Inspector:

    ```sh
    npx @modelcontextprotocol/inspector --mcp-url http://localhost:8000/mcp-listener
    ```

1. If successful, you should see the following output in your terminal:

    ```sh
    Starting MCP inspector...
    ⚙️ Proxy server listening on localhost:6277
    🔑 Session token: <YOUR_TOKEN>
      Use this token to authenticate requests or set DANGEROUSLY_OMIT_AUTH=true to disable auth

    🚀 MCP Inspector is up and running at:
      http://localhost:6274/?MCP_PROXY_AUTH_TOKEN=<YOUR_TOKEN>
    ```
   {:.no-copy-code}
1. The script will automatically open a new browser window with MCP Inspector's UI:

    ![MCP Inspector's UI](/assets/images/ai-gateway/mcp-inspector.png){: style="display:block; margin-left:auto; margin-right:auto; width:70%; border-radius:10px" }

1. Click the **Connect** button on the left.

  {:.warning}
  > Make sure that you use **Streamable HTTP** as **Transport Type** and that the URL points at `http://localhost:8000/mcp-listener`

1. In the **Tools** tile, click the **List tools** button. You should see the following tools available:

    ![MCP tools in MCP Inspector](/assets/images/ai-gateway/mcp-tools.png){: style="display:block; margin-left:auto; margin-right:auto; width:70%; border-radius:10px" }

### Configure Cursor

1. Open your Cursor desktop app.

1. Navigate to **Settings** in the top right corner.

1. In the **Cursor Settings** tab, go to **Tools & MCP** in the left sidebar.

1. In the **Installed MCP Servers** section, click **New MCP Server**.

1. Paste the following JSON configuration into the newly opened `mcp.json` tab:

    ```json
    {
      "mcpServers": {
          "mcp-listener": {
              "url": "http://localhost:8000/mcp-listener"
          }
      }
    }
  ```

1. Return to the **Cursor settings** tab. You should now see the `mcp-listener` MCP server with four tools available.

1. To open a new Cursor chat, click <kbd>cmd</kbd> + <kbd>L</kbd> if you're on Mac, or <kbd>ctrl</kbd> + <kbd>L</kbd> if you're on Windows.

1. In the Cursor chat tab, click **@ Add Context** and select `mcp.json`.


### Validate aggregated MCP tools configuration

You can now test each exposed tool using Cursor.

{% navtabs "validate-mcp-tools" %}
{% navtab "Marketplace tools" %}

1. Enter the following question in the Cursor chat:

    ```text
    How many orders are there in my marketplace?
    ```

1. You will notice that Cursor now makes a tool call to the exposed marketplace tools:

    ```text
    > Ran mcp-route-2
    ```
    {:.no-copy-code}

1. When the agent finishes reasoning, you should see the following response in Cursor:

    ```text
    Based on the API responses, I can see that your marketplace currently has **27 total orders** across all users.
    ```
    {:.no-copy-code}

{% endnavtab %}
{% navtab "WeatherAPI tools" %}

1. Enter the following question in the Cursor chat:

    ```text
    What is the current weather in Alexandria?
    ```

1. You will notice that Cursor makes a tool call to the WeatherAPI tools we exposed through the AI MCP Proxy plugin:

    ```text
    > Ran weather-route-1
    ```
    {:.no-copy-code}

1. When the agent finishes reasoning, you should see the following response in Cursor:

    ```text
    Alexandria, Egypt right now:

    - Temperature: 79°F (26.1°C), feels like 80°F (26.8°C)
    - Condition: Sunny
    - Wind: 7.4 mph NNW
    - Humidity: 61%
    - Pressure: 30.00 in
    - Visibility: 6 miles
    - UV Index: 5.4

    Warm and sunny with light NNW winds.
    ```
    {:.no-copy-code}

{% endnavtab %}
{% navtab "Currency exchange tools" %}

1. Enter the following question in the Cursor chat:

    ```text
    What's the current exchange rate of USD?
    ```

1. You will notice that Cursor now makes a tool call to the exposed currency exchange tools:

    ```text
    > Ran freecurrency-route-1
    ```
    {:.no-copy-code}

1. When the agent finishes reasoning, you should see the following response in Cursor:

    ```text
    Here are the current USD exchange rates:
    USD Exchange Rates (as of now):
    EUR (Euro): 1 USD = 0.858 EUR
    GBP (British Pound): 1 USD = 0.750 GBP
    JPY (Japanese Yen): 1 USD = 152.71 JPY
    CAD (Canadian Dollar): 1 USD = 1.399 CAD
    AUD (Australian Dollar): 1 USD = 1.525 AUD
    ```
    {:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}
