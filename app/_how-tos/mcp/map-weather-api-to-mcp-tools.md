---
title: Map Weather API to MCP tools
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

description: |
    Learn how to use the AI MCP Proxy plugin to expose WeatherAPI endpoints as MCP tools, allowing AI clients like Cursor to query weather data.
products:
  - gateway
  - ai-gateway
permalink: /mcp/map-weather-api-to-mcp-tools/

series:
  id: mcp-weather-api
  position: 1

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
  q: How do I create an MCP API for weather data?
  a: |
    Use the AI MCP Proxy plugin to map WeatherAPI endpoints into MCP tools, allowing AI agents in Cursor to query current weather.

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
    - title: Install Cursor
      content: |
        1. Go to the [Cursor downloads](https://cursor.com/downloads) page.
        2. Download and install Cursor for your OS.
        3. Launch Cursor and sign in or create an account.
      icon_url: /assets/icons/cursor.svg
    - title: Python
      include_content: prereqs/python
      icon_url: /assets/icons/python.svg
  entities:
    services:
        - weather-service
    routes:
        - weather-route
  konnect:
    - name: KONG_STATUS_LISTEN
      value: '0.0.0.0:8100'

---

## Configure the AI MCP Proxy plugin

Configure the [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin to expose the upstream WeatherAPI endpoint as an MCP tool. This setup also includes your [WeatherAPI](https://www.weatherapi.com/api-explorer.aspx) API key in `tools[].query`, so every MCP tool call includes the required `key` query parameter.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: weather-route
      config:
        mode: conversion-listener
        tools:
        - description: Get current weather for a location
          method: GET
          path: "/weather"
          query:
            key:
              - ${key}
          parameters:
          - name: q
            in: query
            required: true
            schema:
              type: string
            description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode,
              IP address, latitude/longitude, or city name.
        server:
          timeout: 60000
variables:
  key:
    value: $WEATHERAPI_API_KEY
{% endentity_examples %}


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
              "url": "http://localhost:8000/weather"
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
