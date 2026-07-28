---
title: Map a RESTful API to MCP tools
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/

description: Learn how to create an MCP Server entity in {{site.ai_gateway}} to convert any RESTful API into MCP tools, including setting up a mock Node.js server for testing.
products:
  - ai-gateway


series:
  id: mcp-conversion-2-0
  position: 1

permalink: /ai-gateway/map-api-to-mcp-tools/

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
  q: How do I turn an existing REST API into MCP tools?
  a: |
    Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity in {{site.ai_gateway}}, and it automatically converts your REST API endpoints into MCP tools that any MCP-compatible AI assistant can call, no custom server code required.

    This tutorial shows you how to create an AI MCP Server entity using kongctl to expose a REST API as MCP tools, and how to call those tools from an MCP client.
tools:
  - kongctl

prereqs:
  konnect:
    - name: KONG_TRACING_INSTRUMENTATIONS
    - name: KONG_TRACING_SAMPLING_RATE
  inline:
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
## Install mock API Server

Before creating an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity, you’ll need an upstream HTTP API to expose. For this tutorial, we’ll use a simple mock API built with Express. This allows you to test the entity without relying on an external service. This mock API simulates a small marketplace system with a fixed set of users and their associated orders. Each user has between two and five sample orders, which the API exposes through `/marketplace/users` and `/marketplace/{userId}/orders` endpoints.

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

This request confirms that the mock server is up and responding. Later, the MCP Server entity will convert this API's endpoints into MCP tool definitions. You should see the following response from the server:

```text
{"name":"Sample Users API"}%
```
{:.no-copy-code}

## Create an MCP Server entity

With the mock API server running, create an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity configured as a `conversion-listener` to expose its endpoints as MCP tools.
The following example maps the mock API operations to MCP tool definitions that the client can invoke.

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateway_mcp_servers:
  - ref: marketplace-mcp
    ai_gateway: !lookup {id: $AI_GATEWAY_ID}
    name: marketplace-mcp
    display_name: "Marketplace API"
    type: conversion-listener
    enabled: true
    policies: []
    access:
      acl_attribute_type: consumer
      acls:
        allow: []
      default_tool_acls:
        deny: []
    config:
      url: http://host.docker.internal:3000
      route:
        paths:
          - /marketplace
      logging:
        payloads: false
        statistics: true
      server:
        timeout: 60000
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
          - description: User ID to filter orders
            in: query
            name: userid
            required: true
            schema:
              type: string
EOF
```

1. In the ChatWise app, navigate to settings.
1. Click **MCP** in the sidebar.
1. Click the **+** button.
1. Select "HTTP Server (http)".
1. In the **Name** field, enter `marketplace-mcp`.
1. In the **URL** field, enter `http://localhost:8000/marketplace`.
1. Click **Verify (View Tools)** to confirm the connection. You should see the following tools listed:
   - `get-users`
   - `get-orders-for-user`
1. Close the settings window.

## Validate the configuration

1. In ChatWise, start a new chat.
1. In the chat input area, click the **hammer icon** to enable MCP tools. The icon turns blue when enabled.
1. From the hammer dropdown menu, enable your MCP server.
1. Enter the following in the ChatWise chat:

```text
What users do you see in the marketplace API?
```

```
I'll query the marketplace service for the list of users
> Called get-users
```
When prompted approve using the MCP tools you created.

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

Now, we can check what Alice Johnson ordered by entering the following message in the ChatWise chat:

```text
What has Alice Johnson ordered?
```

You'll notice that ChatWise calls the tools exposed by the MCP Server entity. First to get-users to find Alice then to get-orders-for-user.

```text
I'll look up the list of users to find Alice's user ID. Then I'll fetch her orders.

> called get-users
> called get-orders-for-user
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
