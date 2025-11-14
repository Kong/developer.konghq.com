---
title: Observe MCP Traffic with Access Control Enabled
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

description: Learn how to observe MCP tool activity after you apply access controls. Enable file-based logging, then review audit entries to confirm permitted tools and RPC calls.


products:
  - gateway
  - ai-gateway
  - insomnia

permalink: /mcp/observe-mcp-traffic-with-acls/

series:
  id: mcp-acls
  position: 2

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

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
  q: How do I observe MCP tool usage with Kong AI Gateway?
  a: |
    Use the File Log plugin to write MCP tool activity to a local file. Inspect the entries to see which tools each Consumer or Consumer Group accessed. Confirm the RPC calls that Chatwise sends to your MCP server.

tools:
  - deck

prereqs:
  entities:
    services:
      - mcp-acl-service
    routes:
      - mcp-acl-route
  konnect:
    - name: KONG_STATUS_LISTEN
      value: '0.0.0.0:8100'
---

## Configure MCP tools in Chatwise

1. Open Chatwise and go to **Settings > MCP**:

   1. Choose **HTTP server (http)** from the **Type** dropdown.
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
   1. In the chat window, click the hammer icon to enable tools. You should see `1` next to the icon. Clicking it will show the name of your MCP server and the number of available tools.

## Configure the File Log plugin

Now, let's configure the File Log plugin:

{% entity_examples %}
entities:
  plugins:
   - name: file-log
     config:
      path: /tmp/mcp.json
{% endentity_examples %}

## Test MCP tools

Let's generate MCP traffic and verify it appears in the logs. In Chatwise, enter the following:

```text
List all users available in my marketplace
```

You should see Chatwise successfully call the `list_users` tool with a response like:

```text
Here is the list of users in your marketplace:

Alice Johnson
Bob Smith
Charlie Lee
Diana Evans
Ethan Brown
Fiona Clark
George Harris
Hannah Lewis
Ian Walker
Julia Turner
```

Next, check the audit logs in your Docker container:

```sh
docker exec -it kong-quickstart-gateway cat /tmp/mcp.json
```

You should see output similar to:

```json
{
  "ai": {
    "mcp": {
      "audit": [
        {
          "primitive_name": "list_users",
          "primitive": "tool",
          "action": "allow",
          "consumer": {
            "name": "admin",
            "id": "e6b415a7-4823-abcd-1234-d86324780e06",
            "identifier": "consumer_group"
          },
          "scope": "primitive"
        },
        {
          "action": "allow",
          "consumer": {
            "name": "admin",
            "id": "e6b415a7-4823-abcd-1234-d86324780e06",
            "identifier": "consumer_group"
          },
          "scope": "global"
        }
      ],
      "rpc": [
        {
          "method": "tools/call",
          "id": "1",
          "latency": 3,
          "tool_name": "list_users",
          "response_body_size": 1375
        }
      ]
    }
  }
}
```
