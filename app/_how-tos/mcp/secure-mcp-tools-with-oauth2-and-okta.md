---
title: Secure MCP tools with OAuth2 and Okta
content_type: how_to
permalink: /mcp/secure-mcp-tools-with-oauth2-and-okta/
breadcrumbs:
  - /mcp/

description: Use the AI MCP OAuth2 plugin with Okta to protect MCP tools exposed through the AI MCP Proxy plugin

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-mcp-proxy
  - ai-mcp-oauth2
  - cors

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - mcp
  - oauth2
  - okta
  - authentication
  - security

tldr:
  q: How do I protect MCP tools with OAuth2 using Okta?
  a: Configure the AI MCP Proxy plugin to expose REST API endpoints as MCP tools, then add the AI MCP OAuth2 plugin to validate access tokens from Okta before MCP clients can call those tools.

tools:
  - deck

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/
  - text: AI MCP OAuth2
    url: /plugins/ai-mcp-oauth2/

prereqs:
  inline:
    - title: WeatherAPI
      content: |
        1. Go to [WeatherAPI](https://www.weatherapi.com/).
        2. Sign up for a free account.
        3. Navigate to [your dashboard](https://www.weatherapi.com/my/) and copy your API key.
        4. Export your API key:

            ```sh
            export DECK_WEATHERAPI_API_KEY='your-weatherapi-api-key'
            ```
    - title: Okta
      include_content: prereqs/okta-mcp-oauth2
      icon_url: /assets/icons/okta.svg
    - title: MCP Inspector
      content: |
          This guide uses the [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) to test the OAuth-protected MCP endpoint.

          1. Ensure you have Node.js and npm installed. If needed, download them from https://nodejs.org.

          1. Update `npx` to the latest version:
              ```sh
              npm install -g npx
              ```
          1. Install the Inspector:
              ```sh
              npm install -g @modelcontextprotocol/inspector
              ```
      icon_url: /assets/icons/mcp.svg
  entities:
    services:
      - weather-api-service
    routes:
      - weather-api-route
      - weather-mcp

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the AI MCP Proxy tools

Configure the [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) in `conversion-only` mode on the `weather-api-route` Route. This instance converts the WeatherAPI REST endpoints into MCP tool definitions. The `weather-tools` tag lets the listener instance discover and aggregate these tools.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: weather-api-route
      tags:
        - weather-tools
      config:
        mode: conversion-only
        tools:
          - annotations:
              title: Realtime API
            description: "Forecast weather API method returns, depending upon your price plan level, upto next 14 day weather forecast and weather alert as json or xml. The data is returned as a Forecast Object.<br /><br />Forecast object contains astronomy data, day weather forecast and hourly interval weather information for a given city."
            method: GET
            path: "current.json"
            query:
              key:
                - ${weatherapi_key}
            parameters:
              - name: q
                in: query
                description:
                  Pass US Zipcode, UK Postcode, Canada Postalcode, IP address,
                  Latitude/Longitude (decimal degree) or city name. Visit [request
                  parameter section](https://www.weatherapi.com/docs/#intro-request)
                  to learn more.
                required: true
                type: string
              - in: query
                name: lang
                type: string
                required: false
                description: Returns 'condition:text' field in API in the desired language.<br /> Visit [request parameter section](https://www.weatherapi.com/docs/#intro-request) to check 'lang-code'.
          - annotations:
              title: Forecast API
            description: "Forecast weather API method returns, depending upon your price plan level, upto next 14 day weather forecast and weather alert as json or xml. The data is returned as a Forecast Object.<br /><br />Forecast object contains astronomy data, day weather forecast and hourly interval weather information for a given city."
            method: GET
            path: "forecast.json"
            query:
              key:
                - ${weatherapi_key}
            parameters:
              - in: query
                name: q
                schema:
                  type: string
                required: true
                description: Pass US Zipcode, UK Postcode, Canada Postalcode, IP address, Latitude/Longitude (decimal degree) or city name. Visit [request parameter section](https://www.weatherapi.com/docs/#intro-request) to learn more.
              - in: query
                name: days
                schema:
                  type: integer
                enum: [1, 2, 3]
                required: true
                description: Number of days of weather forecast. Value ranges from 1 to 14
              - in: query
                name: dt
                schema:
                  type: string
                format: date
                required: false
                description: Date should be between today and next 14 day in yyyy-MM-dd format. e.g. '2015-01-01'
              - in: query
                name: unixdt
                schema:
                  type: integer
                required: false
                description: Please either pass 'dt' or 'unixdt' and not both in same request. unixdt should be between today and next 14 day in Unix format. e.g. 1490227200
              - in: query
                name: hour
                schema:
                  type: integer
                required: false
                description: Must be in 24 hour. For example 5 pm should be hour=17, 6 am as hour=6
              - in: query
                name: lang
                schema:
                  type: string
                required: false
                description: Returns 'condition:text' field in API in the desired language.<br /> Visit [request parameter section](https://www.weatherapi.com/docs/#intro-request) to check 'lang-code'.
              - in: query
                name: alerts
                schema:
                  type: string
                required: false
                description: Enable/Disable alerts in forecast API output. Example, alerts=yes or alerts=no.
              - in: query
                name: aqi
                schema:
                  type: string
                required: false
                description: Enable/Disable Air Quality data in forecast API output. Example, aqi=yes or aqi=no.
              - in: query
                name: tp
                schema:
                  type: integer
                required: false
                description: Get 15 min interval or 24 hour average data for Forecast and History API. Available for Enterprise clients only. E.g:- tp=15
          - annotations:
              title: History API
            description: "History weather API method returns historical weather for a date on or after 1st Jan, 2010 as json. The data is returned as a Forecast Object."
            method: GET
            path: "history.json"
            query:
              key:
                - ${weatherapi_key}
            parameters:
              - name: q
                in: query
                description:
                  Pass US Zipcode, UK Postcode, Canada Postalcode, IP address,
                  Latitude/Longitude (decimal degree) or city name. Visit [request
                  parameter section](https://www.weatherapi.com/docs/#intro-request)
                  to learn more.
                required: true
                type: string
              - name: dt
                in: query
                description: Date on or after 1st Jan, 2015 in yyyy-MM-dd format
                required: true
                type: string
                format: date
              - name: unixdt
                in: query
                description:
                  Please either pass 'dt' or 'unixdt' and not both in same
                  request.<br />unixdt should be on or after 1st Jan, 2015 in Unix
                  format
                required: false
                type: integer
              - name: end_dt
                in: query
                description:
                  Date on or after 1st Jan, 2015 in yyyy-MM-dd format<br />'end_dt'
                  should be greater than 'dt' parameter and difference should not be
                  more than 30 days between the two dates.
                required: false
                type: string
                format: date
              - name: unixend_dt
                in: query
                description:
                  Date on or after 1st Jan, 2015 in Unix Timestamp format<br
                  />unixend_dt has same restriction as 'end_dt' parameter. Please
                  either pass 'end_dt' or 'unixend_dt' and not both in same request.
                  e.g. unixend_dt=1490227200
                required: false
                type: integer
              - name: hour
                in: query
                description:
                  Must be in 24 hour. For example 5 pm should be hour=17, 6 am as
                  hour=6
                required: false
                type: integer
              - name: lang
                in: query
                description:
                  Returns 'condition:text' field in API in the desired language.<br
                  /> Visit [request parameter
                  section](https://www.weatherapi.com/docs/#intro-request) to check
                  'lang-code'.
                required: false
                type: string
          - annotations:
              title: Search API
            description: "WeatherAPI.com Search or Autocomplete API returns matching cities and towns as an array of Location object."
            method: GET
            path: "search.json"
            query:
              key:
                - ${weatherapi_key}
            parameters:
              - name: q
                in: query
                description:
                  Pass US Zipcode, UK Postcode, Canada Postalcode, IP address,
                  Latitude/Longitude (decimal degree) or city name. Visit [request
                  parameter section](https://www.weatherapi.com/docs/#intro-request)
                  to learn more.
                required: true
                type: string
          - annotations:
              title: IP Lookup API
            description: "IP Lookup API method allows a user to get up to date information for an IP address."
            method: GET
            path: "ip.json"
            query:
              key:
                - ${weatherapi_key}
            parameters:
              - name: q
                in: query
                description: Pass IP address.
                required: true
                type: string
variables:
  weatherapi_key:
    value: $WEATHERAPI_API_KEY
{% endentity_examples %}

## Configure the AI MCP Proxy listener

Configure a second [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) instance in `listener` mode on the `weather-mcp` Route. This instance aggregates tools tagged `weather-tools` and serves them over the MCP protocol to connected clients.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: weather-mcp
      config:
        mode: listener
        server:
          tag: weather-tools
          timeout: 45000
        logging:
          log_statistics: true
          log_payloads: false
        max_request_body_size: 32768
{% endentity_examples %}

## Configure the CORS plugin

Add the [CORS plugin](/plugins/cors/) to the `weather-mcp` Route so that MCP Inspector's browser-based OAuth callback can reach the MCP endpoint.

{% entity_examples %}
entities:
  plugins:
    - name: cors
      route: weather-mcp
      enabled: true
      config:
        origins:
          - http://localhost:6274
{% endentity_examples %}

## Configure the AI MCP OAuth2 plugin

Configure the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) on the `weather-mcp` Route. This Plugin validates OAuth2 access tokens issued by Okta before allowing MCP clients to call the weather tools.

The `resource` field identifies this MCP server to the authorization server. The `metadata_endpoint` path must match one of the paths on the `weather-mcp` Route so the Plugin can serve the OAuth Protected Resource Metadata that MCP clients need to discover the authorization server.

`insecure_relaxed_audience_validation` is set to `true` because Okta does not yet include the resource URL in the audience (`aud`) claim as defined in [RFC 8707](https://datatracker.ietf.org/doc/html/rfc8707).

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-oauth2
      route: weather-mcp
      enabled: true
      config:
        client_id: ${okta_client_id}
        client_secret: ${okta_client_secret}
        insecure_relaxed_audience_validation: true
        authorization_servers:
          - ${okta_auth_server}
        introspection_endpoint: ${okta_introspection_endpoint}
        resource: http://localhost:8000/weather/mcp
        metadata_endpoint: /.well-known/oauth-protected-resource/weather/mcp
variables:
  okta_auth_server:
    value: $OKTA_AUTH_SERVER
    description: The Okta authorization server URL, for example https://your-org.okta.com/oauth2/default.
  okta_introspection_endpoint:
    value: $OKTA_INTROSPECTION_ENDPOINT
    description: The Okta token introspection endpoint, for example https://your-org.okta.com/oauth2/default/v1/introspect.
  okta_client_id:
    value: $OKTA_CLIENT_ID
    description: The Client ID from the Kong MCP Gateway web application in Okta.
  okta_client_secret:
    value: $OKTA_CLIENT_SECRET
    description: The Client Secret from the Kong MCP Gateway web application in Okta.
{% endentity_examples %}

## Connect with MCP Inspector

1. Start MCP Inspector:
```sh
    npx @modelcontextprotocol/inspector@latest --mcp-url http://localhost:8000/weather/mcp
```

1. Open the MCP Inspector UI in your browser at the URL shown in the terminal output.

1. Set **Transport Type** to **Streamable HTTP**.

1. Set the URL to `http://localhost:8000/weather/mcp`.

1. Click **Open Auth Settings**.

1. Enter the **Native Application** Client ID from the Okta setup (the `MCP Inspector` app, not the `Kong MCP Gateway` app). Leave **Client Secret** empty.

    {:.warning}
    > Use the Client ID from the **Native Application** (`MCP Inspector`) you created in Okta. Do not use the Web Application Client ID. The Web Application credentials are used by {{site.base_gateway}} for token introspection, not by MCP clients.

1. Click **Guided OAuth Flow**.

1. **Metadata Discovery**: click **Continue**.

1. **Client Registration**: click **Continue**.

1. **Preparing Authorization**: click the authorization link. A new browser tab opens with the Okta login page. Sign in with your Okta user credentials. Copy the authorization code from the browser.

1. **Request Authorization and acquire authorization code**: paste the authorization code and click **Continue**.

1. **Token Request**: click **Continue**.

1. **Authentication Complete** shows a green checkmark.

1. Click **Connect**. MCP Inspector connects to the OAuth-protected MCP endpoint.

## Validate

1. In MCP Inspector, go to the **Tools** tab and click **List Tools**. You should see the weather tools exposed by the [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/):

    ```text
    Forecast API
    History API
    IP Lookup API
    Search API
    Realtime API
    ```
    {:.no-copy-code}

1. Select the **Realtime API** tool, enter `London` for the `q` parameter, and click **Run Tool**. You should receive a JSON response with current weather data:

    ```json
    {
      "location": {
        "name": "London",
        "region": "City of London, Greater London",
        "country": "United Kingdom"
      },
      "current": {
        "temp_c": 15.3,
        "condition": {
          "text": "Partly cloudy"
        },
        "wind_kph": 11.2,
        "humidity": 72
      }
    }
    ```
    {:.no-copy-code}

1. To confirm that unauthenticated requests are rejected, send an MCP tool call without a token:

    ```sh
    curl --no-progress-meter --fail-with-body http://localhost:8000/weather/mcp \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"Realtime API","arguments":{"q":"London"}}}'
    ```

    The response returns a `401` status, confirming the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) is enforcing authentication on MCP tool calls.
