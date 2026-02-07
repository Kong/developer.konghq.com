---
title: Autogenerate MCP tools from a RESTful API
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

description: Learn how to use the AI MCP Proxy plugin to generate MCP from any RESTful API, including setting up a mock Node.js server for testing.
products:
  - gateway
  - ai-gateway
permalink: /mcp/autogenerate-mcp-tools/

series:
  id: mcp-conversion
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
  q: How do I automatically generate an MCP API from an existing REST API?
  a: |
    Use the AI MCP Proxy to map your REST API endpoints into MCP capabilities, allowing you to integrate them directly with {{site.ai_gateway}}.
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
  konnect:
    - name: KONG_STATUS_LISTEN
      value: '0.0.0.0:8100'
---
## Install mock API Server

Before using the [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin, you’ll need an upstream HTTP API to expose. For this tutorial, we’ll use a simple mock API built with Express. This allows you to test the plugin without relying on an external service. This mock API simulates a small marketplace system with a fixed set of users and their associated orders. Each user has between two and five sample orders, which the API exposes through `/marketplace/users` and `/marketplace/{userId}/orders` endpoints.

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

## Configure the AI MCP Proxy plugin

With the mock API server running, configure the AI MCP Proxy plugin to expose its endpoints as MCP tools.
The following example maps the mock API operations to MCP tool definitions that the client can invoke.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: mcp-route
      config:
        mode: conversion-listener
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
        server:
          timeout: 60000
{% endentity_examples %}

1. Open your Cursor desktop app.

1. Navigate to **Settings** in the top right corner.

1. In the **Cursor Settings** tab, go to **Tools & MCP** in the left sidebar.

1. In the **Installed MCP Servers** section, click **New MCP Server**.

1. Paste the following JSON configuration into the newly opened `mcp.json` tab:

    ```json
    {
     "mcpServers": {
       "marketplace": {
         "url": "http://localhost:8000/marketplace"
       }
     }
   }
  ```

1. Return to the **Cursor settings** tab. You should now see the weather MCP server with one tool available:

   ![Tools exposed in Cursor](/assets/images/ai-gateway/cursor-tools.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

1. To open a new Cursor chat, click <kbd>cmd</kbd> + <kbd>L</kbd> if you're on Mac, or <kbd>ctrl</kbd> + <kbd>L</kbd> if you're on Windows.

1. In the Cursor chat tab, click **@ Add Context** and select `mcp.json`:

![Add context in Cursor chat](/assets/images/ai-gateway/cursor-add-context.png){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

## Validate the configuration

Enter the following question in the Cursor chat:

```text
What users do you see in the API?
```

```
I'll query the marketplace service for the list of users
> Called mcp-route-1
```

When the agent finishes reasoning, You should see the following output:

```text
Let me check what users are available in the API:
I can see 10 users in the API:
1. Alice Johnson (ID: a1b2c3d4)
2. Bob Smith (ID: e5f6g7h8)
3. Charlie Lee (ID: i9j0k1l2)
4. Diana Evans (ID: m3n4o5p6)
5. Ethan Brown (ID: q7r8s9t0)
6. Fiona Clark (ID: u1v2w3x4)
7. George Harris (ID: y5z6a7b8)
8. Hannah Lewis (ID: c9d0e1f2)
9. Ian Walker (ID: g3h4i5j6)
10. Julia Turner (ID: k7l8m9n0)
```
{:.no-copy-code}

Now, we can check what Alice Johnson ordered by entering the following message in the Cursor chat:

```text
What did Alice Johnson order?
```

You'll notice that Cursor calls the tools exposed by the AI MCP Proxy plugin:

```text
I'll look up the list of users to find Alice's user ID. Then I'll fetch her orders.

> called mcp-route-1
> called mcp-route-2
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