---
title: Autogenerate MCP tools for Weather API
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI MCP
    url: /plugins/ai-mcp/

description: |
    Learn how to use the AI MCP Conversion plugin to expose WeatherAPI endpoints as MCP tools, allowing AI clients like Cursor to query weather data.
products:
  - gateway
  - ai-gateway
permalink: /mcp/autogenerate-mcp-tools-for-weather-api/

series:
  id: mcp-weather-api
  position: 1

works_on:
  - on-prem

min_version:
  gateway: '3.12'

plugins:
  - ai-mcp
  - request-transformer-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - mcp
  - weather

tldr:
  q: How do I automatically generate an MCP API for weather data?
  a: |
    Use the AI MCP Conversion plugin to map WeatherAPI endpoints into MCP tools, allowing AI agents in Cursor to query current weather.

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
            export DECK_WEATHERAPI_API_KEY=YOUR_WEARTHERAPI_API_KEY
            ```
      icon_url: /assets/icons/ai.svg
    - title: Install Cursor
      content: |
        1. Go to the [Cursor downloads](https://cursor.com/downloads) page.
        2. Download and install Cursor for your OS.
        3. Launch Cursor and sign in or create an account.
      icon_url: /assets/icons/cursor.svg
  entities:
    services:
        - weather-service
    routes:
        - weather-route
automated_tests: false
---

## Add API key using Request Transformer Advanced

First, we configure the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin. This plugin modifies outgoing requests before they reach the upstream API. In this example, it automatically appends your [WeatherAPI](https://www.weatherapi.com/api-explorer.aspx) API key to the query string so that all requests are authenticated without needing to manually provide the key each time.

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

### Configure the AI MCP plugin

We can move on to configuring the AI MCP plugin. This setup exposes the upstream WeatherAPI endpoint as an MCP tool, enabling our AI client, Cursor, to call it directly.

In this configuration, we also define the tool along with its parameters—including the configured API key—so that the MCP client can make tool calls for our weather queries.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp
      route: weather-route
      config:
        tools:
          - description: Get current weather for a location
            method: GET
            path: "/weather"
            parameters:
              - name: key
                in: query
                description: Your API key
                required: true
                schema:
                  type: string
              - name: q
                in: query
                required: true
                schema:
                  type: string
                description:  Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
        server:
          timeout: 60000
{% endentity_examples %}


## Configure Cursor

1. Open your Cursor desktop app.

2. Navigate to **Cursor > Settings**.

3. In the **Settings** tab, go to **Tools & integrations** in the left sidebar.

4. In the **MCP Tools** section, click **Add Custom MCP**.

5. Paste the following JSON configuration into the newly opened `mcp.json` tab:

    ```json
    {
    "mcpServers": {
        "weather": {
        "url": "http://localhost:8000/weather",
        "headers": {
            "key": "<YOUR_WEATHERAPI_KEY>"
        }
        }
    }
    }
    ```

6. Return to the **Cursor settings** tab. You should now see the weather MCP server with one tool available:

![Tools exposed in Cursor](/assets/images/ai-gateway/cursor-tools.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

7. To open a new Cursor chat, click <kbd>cmd</kbd> + <kbd>L</kbd> if you're on Mac, or <kbd>ctrl</kbd> + <kbd>L</kbd> if you're on Windows.

8. In the Cursor chat tab, click **@ Add Context** and select `mcp.json`:

![Add context in Cursor chat](/assets/images/ai-gateway/cursor-add-context.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

## Validate MCP tools configuration

Enter the following question in the Cursor chat:

```text
What is the current weather in London?
```

You will notice that Cursor makes a tool call to the WeatherAPI tools we exposed through the AI MCP plugin:

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