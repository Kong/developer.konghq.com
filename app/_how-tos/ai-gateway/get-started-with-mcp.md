---
title: Map a REST API to MCP Server
content_type: how_to
permalink: /ai-gateway/get-started-with-mcp-server/
description: Learn how to create an MCP Server entity in {{site.konnect_product_name}} to expose REST API endpoints as MCP tools.
products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0.0'

entities:
  - ai-mcp-server

tags:
  - get-started
  - ai
  - mcp

tldr:
  q: How do I expose a REST API as MCP tools in {{site.ai_gateway}}?
  a: Create an MCP Server entity with tools mapped to your API endpoints.

tools:
  - konnect-api

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/

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

---

## Install mock API Server

Before creating the MCP Server entity, you need an upstream HTTP API to expose. For this tutorial, use a simple mock API built with Express. This allows you to test the MCP Server without relying on an external service. This mock API simulates a small marketplace system with a fixed set of users and their associated orders. Each user has between two and five sample orders, which the API exposes through `/marketplace/users` and `/marketplace/orders` endpoints.

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

This request confirms that the mock server is up and responding. You should see the following response from the server:

```text
{"name":"Sample Users API"}%
```
{:.no-copy-code}

## Create an MCP Server entity

With the mock API server running, create an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity to expose its endpoints as MCP tools. The following example maps the marketplace API operations to MCP tool definitions that the client can invoke.

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/mcp-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Marketplace API
  name: marketplace-mcp
  type: conversion-listener
  enabled: true
  policies: []
  acls:
    acl_attribute_type: consumer
    allow: []
    deny: []
  default_tool_acls:
    allow: []
    deny: []
  config:
    url: http://127.0.0.1:3000
    route:
      paths:
        - /marketplace
    logging:
      payloads: false
      statistics: true
    max_request_body_size: 8388608
  tools:
    - description: Get users
      method: GET
      path: /users
      parameters:
        - name: id
          in: query
          required: false
          schema:
            type: string
          description: Optional user ID
    - description: Get orders for a user
      method: GET
      path: /orders
      parameters:
        - name: userid
          in: query
          required: true
          schema:
            type: string
          description: User ID to filter orders
{% endkonnect_api_request %}

Save the MCP Server ID from the response:

```bash
export MCP_SERVER_ID='<mcp-server-id-from-response>'
```

## Validate the configuration

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

1. Return to the **Cursor settings** tab. You should now see the marketplace MCP server with tools available.

1. To open a new Cursor chat, click <kbd>cmd</kbd> + <kbd>L</kbd> if you're on Mac, or <kbd>ctrl</kbd> + <kbd>L</kbd> if you're on Windows.

1. In the Cursor chat tab, click **@ Add Context** and select `mcp.json`.

Enter the following question in the Cursor chat:

```text
What users do you see in the API?
```

When the agent finishes reasoning, you should see output similar to:

```text
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

Now check what Alice Johnson ordered by entering the following message in the Cursor chat:

```text
What did Alice Johnson order?
```

When the agent finishes reasoning, you should see output similar to:

```text
Sugar (50kg)
Cleaning Supplies Pack
Canned Tomatoes (100 cans)
```
{:.no-copy-code}
