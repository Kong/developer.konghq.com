---
title: Aggregate MCP tools - expose an internal MCP server
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

description: Learn how to aggregate MCP tools from multiple RESTful APIs using AI MCP Proxy. This tutorial shows how to configure conversion-only instances to convert APIs into tools and a listener instance to expose them through an internal MCP server.

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
  - openai
  - mcp

tldr:
  q: How do I aggregate MCP tools from multiple APIs?
  a: |
    Use AI MCP Proxy in conversion-only mode to convert each RESTful API into MCP tools, then configure a listener-mode plugin to aggregate and expose all tools to AI clients.

tools:
  - deck

prereqs:
  inline:
    - title: Create WeatherAPI account
      content: |
        1. Go to [WeatherAPI](https://www.weatherapi.com/).
        2. Sign up for a free account.
        3. Navigate to [your dashboard](https://www.weatherapi.com/my/) and copy your API key.
        4. Export your API key by running the following command in your terminal:
           ```sh
           export DECK_WEATHERAPI_API_KEY='your-weatherapi-api-key'
           ```
    - title: MCP Inspector
      content: |
        ```sh
        npm install -g @modelcontextprotocol/inspector
        ```
      icon_url: /assets/icons/mcp.svg
    - title: Cursor
      content: |
        This tutorial uses Cursor as an MCP client:
        1. Go to the [Cursor downloads](https://cursor.com/downloads) page.
        2. Download the installer for your operating system.
        3. Install Cursor on your machine.
        4. Launch Cursor and sign in to your account or create a new account.
      icon_url: /assets/icons/cursor.svg
  entities:
    services:
      - mcp-service
      - weather-service
    routes:
      - mcp-route
      - weather-route
      - listener-route
---
## Install mock API Server

Before configuring the first [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin, you’ll need an upstream HTTP API to expose. For this tutorial, we’ll use a simple mock API built with Express. This allows you to test the plugin without relying on an external service. This mock API simulates a small marketplace system with a fixed set of users and their associated orders. Each user has between two and five sample orders, which the API exposes through `/marketplace/users` and `/marketplace/{userId}/orders` endpoints.

Running these commands will download the mock API script and install any required dependencies automatically:

```sh
curl -s -o api.js "https://gist.githubusercontent.com/subnetmarco/5ddb23876f9ce7165df17f9216f75cce/raw/a44a947d69e6f597465050cc595b6abf4db2fbea/api.js"
npm install express
node api.js
```

Validate the API is running:

```sh
curl -X GET http://localhost:3000
```

This request confirms that the mock server is up and responding. Later, the AI MCP Proxy will use this API’s OpenAPI schema to generate MCP tool definitions. You should see the following response from the server:

```text
{"name":"Sample Users API"}%
```
{:.no-copy-code}

## Configure the first AI MCP Proxy plugin

With the mock API server running, configure the AI MCP Proxy plugin to expose its endpoints as MCP tools.
In this tutorial, we configure the plugin in conversion-only mode because this instance only converts RESTful API paths into MCP tool definitions. It doesn’t handle incoming MCP requests directly. Later, we’ll aggregate these tools from multiple conversion-only instances using listener-mode plugins.

In this configuration we also define `tags` at the plugin level because listener plugins use them to discover and expose the registered tools.

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

## Configure the second AI MCP Proxy plugin



### Step 1: Add an API key using the Request Transformer Advanced plugin

First, we'll configure the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin. This plugin modifies outgoing requests before they reach the upstream API. In this example, it automatically appends your [WeatherAPI](https://www.weatherapi.com/api-explorer.aspx) API key to the query string so that all requests are authenticated without needing to manually provide the key each time.

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

We can move on to configuring the second AI MCP Proxy plugin. We configure this instance of the **AI MCP Proxy** plugin in **conversion-only** mode to map the WeatherAPI endpoint as an MCP tool. Like the previous marketplace configuration, this instance only converts RESTful paths into tool definitions and doesn’t process MCP requests directly.

Again, the `tags` field ensures that listener-mode plugins can later discover and aggregate this tool along with others from the marketplace instance. We’ll configure the **listener** instance in the next steps to expose all registered tools to our AI client.

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

## Configure the listener AI MCP Proxy plugin

Now, let's configure another AI MCP Proxy plugin instance in listener mode to aggregate and expose the tools registered by the conversion-only plugins. The listener plugin discovers tools based on their shared tag value—in this case, `mcp-tools`—and serves them through an MCP server that AI clients can connect to.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: mcp-listener
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

## Run the MCP inspector

First, let's run the MCP Inspector to see whether our listener AI MCP Proxy plugin properly aggregates all exposed tools.

1. Execute the following command to run the MCP Inspector:

    ```sh
    npx @modelcontextprotocol/inspector --mcp-url http://localhost:8000/mcp-listener node path/to/server/index.js
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
1. The script will automatically open a new browser window with MCP Inspector's UI:

    ![MCP Inspector's UI](/assets/images/ai-gateway/mcp-inspector.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

1. Click the **Connect** button on the left.

1. In the **Tools** tile, click the **List tools** button. You should see the following tools available:

    ![MCP tools in MCP Inspector](/assets/images/ai-gateway/mcp-tools.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

## Configure Cursor

1. Open your Cursor desktop app.

1. Navigate to **Settings** in the top right corner.

1. In the **Cursor Settings** tab, go to **Tools & MCP** in the left sidebar.

1. In the **Installed MCP Servers** section, click **New MCP Server**.

1. Paste the following JSON configuration into the newly opened `mcp.json` tab:

    ```json
    {
      "mcpServers": {
          "weather": {
              "url": "http://localhost:8000/mcp-listener"
          }
      }
    }
  ```

1. Return to the **Cursor settings** tab. You should now see the weather MCP server with one tool available:

   ![Tools exposed in Cursor](/assets/images/ai-gateway/cursor-weather-tools.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

1. To open a new Cursor chat, click <kbd>cmd</kbd> + <kbd>L</kbd> if you're on Mac, or <kbd>ctrl</kbd> + <kbd>L</kbd> if you're on Windows.

1. In the Cursor chat tab, click **@ Add Context** and select `mcp.json`:

![Add context in Cursor chat](/assets/images/ai-gateway/cursor-add-context.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

## Validate MCP tools configuration

Enter the following question in the Cursor chat:

```text
What is the current weather in London?
```

You will notice that Cursor makes a tool call to the WeatherAPI tools we exposed through the AI MCP Proxy plugin:

```text
I'll fetch the current weather for London.
> Called weather-route-1
```
{:.no-copy-code}

When the agent finishes reasoning, you should see the following response in Cursor:

```text
London weather (now)
- Condition: Overcast
- Temperature: 17.2°C (63.0°F)
- Feels like: 17.2°C (63.0°F)
- Wind: 14.8 kph NE (gusts 18.8 kph)
- Humidity: 83%
- Pressure: 1016 mb
- Visibility: 10 km
- UV index: 0.1
- Updated: 2025-08-19 07:45 (Europe/London)
```
{:.no-copy-code}

Let's also check whether Cursor can also call our marketplace tools. Enter the following question in the Cursor chat:

```text
How many orders are there in my marketplace?
```

You will notice that Cursor now makes a tool call to the exposed marketplace tools:

```text
> Ran mcp-route-2
```
{:.no-copy-code}

When the agent finishes reasoning, you should see the following response in Cursor:

```text
Based on the API responses, I can see that your marketplace currently has **27 total orders** across all users.

Here's the breakdown by user:

**Order Distribution:**
- **Alice Johnson** (a1b2c3d4): 3 orders
- **Bob Smith** (e5f6g7h8): 3 orders
- **Charlie Lee** (i9j0k1l2): 2 orders
- **Diana Evans** (m3n4o5p6): 4 orders
- **Ethan Brown** (q7r8s9t0): 2 orders
- **Fiona Clark** (u1v2w3x4): 3 orders
- **George Harris** (y5z6a7b8): 2 orders
- **Hannah Lewis** (c9d0e1f2): 3 orders
- **Ian Walker** (g3h4i5j6): 2 orders
- **Julia Turner** (k7l8m9n0): 3 orders

**Total: 27 orders**

The orders include various food and household items like sugar, flour, cleaning supplies, oils, pasta, toilet paper, and other essentials. Diana Evans has the most orders (4), while several users have 2-3 orders each.
```
{:.no-copy-code}