---
title: Autogenerate serverless MCP APIs from any RESTful API
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI MCP
    url: /plugins/ai-mcp/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Learn how to use the AI MCP Conversion plugin to generate serverless MCP APIs from any RESTful API, including setting up a mock Node.js server for testing.
products:
  - gateway
  - ai-gateway
permalink: /mcp/autogenerate-serverless-mcp/

works_on:
  - on-prem

min_version:
  gateway: '3.12'

plugins:
  - ai-mcp

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - mcp
  - serverless

tldr:
  q: How do I automatically generate an MCP API from an existing REST API?
  a: |
    Use the AI MCP Conversion to map your REST API endpoints into MCP capabilities, allowing you to integrate them directly with AI Gateway.
tools:
  - deck

prereqs:
  inline:
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
    routes:
      - mcp-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: true
---
## Install mock API Server

Before using the **AI MCP Conversion**, you’ll need an upstream HTTP API to expose. For this tutorial, we’ll use a simple mock API built with Express. This allows you to test the plugin without relying on an external service. This mock API simulates a small marketplace system with a fixed set of users and their associated orders. Each user has between two and five sample orders, which the API exposes through `/marketplace/users` and `/marketplace/{userId}/orders` endpoints.

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

This request confirms that the mock server is up and responding. Later, the AI MCP Conversion will use this API’s OpenAPI schema to generate MCP tool definitions. You should see the following response from the server:

```text
{"name":"Sample Users API"}%
```
{:.no-copy-code}

## Configure the AI MCP Conversion plugin

With the mock API server running, configure the AI MCP plugin to expose its endpoints as MCP tools.
The following example maps the mock API operations to MCP tool definitions that the client can invoke.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp
      route: mcp-route
      config:
        tools:
        - description: Get users
          method: GET
          path: /marketplace/users
          parameters:
            - name: id
              in: query
              required: false
              schema:
                type: string
              description: Optional user ID
        - description: Get orders for a user
          method: GET
          path: /marketplace/{userId}/orders
          parameters:
            - description: User ID to filter orders
              in: query
              name: userid
              required: true
              schema:
                type: string
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
       "marketplace": {
         "url": "http://localhost:8000/marketplace"
       }
     }
   }
   ```

6. Return to the **Cursor settings** tab. You should now see the Marketplace MCP server with two tools available:

![Tools exposed in Cursor](/assets/images/ai-gateway/cursor-tools.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

7. To open a new Cursor chat, click <kbd>cmd</kbd> + <kbd>L</kbd> if you're on Mac, or <kbd>ctrl</kbd> + <kbd>L</kbd> if you're on Windows.

8. In the Cursor chat tab, click **@ Add Context** and select `mcp.json`:

![Add context in Cursor chat](/assets/images/ai-gateway/cursor-add-context.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

## Validate the configuration

Enter the following message in the Cursor chat:

```text
What did Alice order?
```

You'll notice that Cursor calls the tools exposed by the AI MCP Conversion plugin:

```text
I'll look up the list of users to find Alice's user ID. Then I'll fetch her orders.

called mcp-route-1
called mcp-route-2
```
{:.no-copy-code}

When the agent finishes reasoning, you should see the following response:

```text
Sugar (50kg)
Cleaning Supplies Pack
Canned Tomatoes (100 cans)
```
{:.no-copy-code}

You can validate this result against the [API exposed in the previous step](https://gist.githubusercontent.com/subnetmarco/5ddb23876f9ce7165df17f9216f75cce/raw/a44a947d69e6f597465050cc595b6abf4db2fbea/api.js).