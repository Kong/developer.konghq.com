---
title: Observe MCP Traffic with Access Control Enabled
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/v1/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

description: Learn how to observe MCP tool activity after you apply access controls. Enable file-based logging, then review audit entries to confirm permitted tools and RPC calls.

products:
  - ai-gateway
  - insomnia

permalink: /ai-gateway/observe-mcp-traffic-with-acls/

series:
  id: mcp-acls
  position: 2

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - openai
  - mcp

tldr:
  q: How do I observe MCP tool usage with {{site.ai_gateway}}?
  a: |
    Use the File Log plugin to write MCP tool activity to a local file. Inspect the entries to see which tools each Consumer or Consumer Group accessed. Confirm the RPC calls that Chatwise sends to your MCP server.

tools:
  - kongctl

prereqs:
  inline:
    - title: ChatWise desktop application
      content: |
        Download and install [ChatWise](https://chatwise.app/) for your OS.

        After installation:
        1. Launch the app.
        2. In Settings > Providers, configure your AI provider endpoint and API key.

automated_tests: false

---

## Configure MCP tools in Chatwise

1. Open Chatwise and go to **Settings > MCP**:

   1. Click **+** at the bottom of the window and choose **HTTP server (http)** from the **Type** dropdown.
   1. Enter a user-friendly name in the **Name** field.
   1. Enter `http://localhost:8000/mcp` in the **URL** field.
   1. Enable the **Run tools automatically** option.
   1. Click **+** next to the **HTTP headers** section and add:

      - **KEY**: `api-key`
      - **VALUE**: `alice-key`
   1. Click the **Verify (view tools)** button. You should see the following tools:

      - `list_users`
      - `get_user`
      - `list_orders`
      - `list_orders_for_user`
      - `search_orders`
   1. Close **Settings**.
   1. In the chat window, click the hammer icon to enable tools.
   1. Toggle your MCP server on. You should see `1` next to the hammer icon. Click the icon to view the server name and the number of available tools.

## Configure the File Log plugin

Now, create a File Log AI Policy and add it to the existing AI MCP Server:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateway_policies:
  - ref: my-file-log
    ai_gateway: !lookup name:ai-quickstart
    name: my-file-log
    display_name: "my-file-log"
    type: file-log
    config:
      path: /tmp/mcp.json
ai_gateway_mcp_servers:
  - ref: marketplace-mcp
    ai_gateway: !lookup {id: $AI_GATEWAY_ID}
    name: marketplace-mcp
    display_name: "Marketplace API"
    type: passthrough-listener
    enabled: true
    policies:
      - !ref my-file-log#name
    access:
      acl_attribute_type: consumer
      acls:
        allow: []
      default_tool_acls:
        deny: []
        allow:
          - admin
    config:
      url: http://localhost:3001
      route:
        paths:
          - /mcp
      logging:
        payloads: false
        statistics: true
      server:
        timeout: 60000
    tools:
      - name: get_users
        description: Get user
        method: GET
        path: /mcp/get_user
        parameters:
          - name: id
            in: query
            required: false
            schema:
              type: string
            description: Optional user ID
        access:
          acls:
            allow:
              - admin
              - eason
            deny:
              - developer
      - name: list_users
        description: List users
        method: GET
        path: /mcp/list_users
        parameters: []
        access:
          acls:
            allow:
              - admin
              - eason
            deny:
              - developer
      - name: list_orders
        description: List orders
        method: GET
        path: /mcp/list_orders
        parameters: []
        access:
          acls:
            allow:
              - admin
              - developer
      - name: list_orders_for_user
        description: List order for user
        method: GET
        path: /mcp/list_orders_for_user
        parameters: []
        access:
          acls:
            allow:
              - admin
              - developer
      - name: search_orders
        description:search orders
        method: GET
        path: /mcp/search_orders
        parameters: []
        access:
          acls:
            allow:
              - admin
            deny:
              - developer
EOF
```

## Test MCP tools

Let's generate MCP traffic and verify it appears in the logs. In Chatwise, enter the following:

```text
How many orders are there in my marketplace?
```

You should see Chatwise successfully call the `list_users` tool with a response like:

```text
There are 27 orders in your marketplace.
```
{:.no-copy-code}

Next, check the audit logs in your Docker container:

```sh
docker exec -it kong-quickstart-gateway cat /tmp/mcp.json
```

You should see output similar to:

```json
{
  "ai": {
    "mcp": {
      "rpc": [
        {
          "method": "tools/call",
          "latency": 6,
          "id": "2",
          "response_body_size": 5030,
          "tool_name": "list_orders"
        }
      ],
      "audit": [
        {
          "primitive_name": "list_orders",
          "consumer": {
            "id": "6c95a611-9991-407b-b1c3-bc608d3bccc3",
            "name": "admin",
            "identifier": "consumer_group"
          },
          "scope": "primitive",
          "primitive": "tool",
          "action": "allow"
        }
      ]
    }
  },
      "rpc": [
        {
          "method": "tools/call",
          "id": "1",
          "latency": 3,
          "tool_name": "list_orders",
          "response_body_size": 5030
        }
      ]
    }
  }
}
```