---
title: Observe MCP traffic with the File Log Policy
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: File Log Policy
    url: /ai-gateway/policies/file-log/
  - text: "{{site.ai_gateway}} audit log reference"
    url: /ai-gateway/ai-audit-log-reference/#ai-mcp-logs
  - text: MCP version support
    url: /ai-gateway/mcp-version-support/
  - text: Monitor MCP traffic with OpenTelemetry
    url: /ai-gateway/monitor-mcp-traffic-with-otel/
  - text: Control MCP tool access with AI Consumer and AI Consumer Group ACLs
    url: /ai-gateway/use-access-controls-for-mcp-tools/

description: Learn how to observe MCP tool activity after you apply access controls. Attach a File Log Policy, then review audit entries to confirm permitted tools and RPC calls, using stateless 2026-07-28 MCP traffic.

products:
  - ai-gateway

series:
  id: mcp-acls-2-1
  position: 2

permalink: /ai-gateway/observe-mcp-traffic/

works_on:
  - konnect

min_version:
  ai-gateway: '2.1'

entities:
  - ai-mcp-server
  - ai-policy

tags:
  - ai
  - mcp
  - observability

tldr:
  q: How do I observe MCP tool usage with {{site.ai_gateway}}?
  a: |
    Use the [File Log Policy](/ai-gateway/policies/file-log/) to write MCP tool activity to a local file. Inspect the entries to see which tools each AI Consumer or AI Consumer Group accessed, and whether ACLs allowed or denied the call.

tools:
  - kongctl

prereqs:
  inline:
    - title: Mock API Server
      content: |
        This tutorial reuses the AI Consumers, AI Consumer Groups, AI Auth Strategy, and AI MCP Server created in [Control MCP tool access with AI Consumer and AI Consumer Group ACLs](/ai-gateway/use-access-controls-for-mcp-tools/), along with the `$ALICE_API_KEY` and `$BOB_API_KEY` values exported there.

        Keep the mock marketplace MCP server from that tutorial running on port `3001`. The AI MCP Server proxies to it, so the traffic you generate here fails without it. Confirm it's still listening, which returns `200`:

        ```bash
        curl -s -o /dev/null -w '%{http_code}\n' -X POST http://localhost:3001/mcp \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json, text/event-stream' \
          -H 'MCP-Protocol-Version: 2026-07-28' \
          -H 'Mcp-Method: tools/list' \
          -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{}}}}'
        ```
      icon_url: /assets/icons/github.svg

cleanup:
  inline:
    - title: Stop the mock API server
      content: |
        Stop the mock marketplace MCP server with `Ctrl+C` in the terminal running it.
      icon_url: '/assets/icons/code.svg'
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: '/assets/icons/ai-gateway.svg'

faqs:
  - q: What's different about `2026-07-28` MCP traffic in these log entries compared to `2025-06-18` or `2025-11-25`?
    a: |
      There's no `mcp_session_id` field anywhere in the entry. `2026-07-28` removes the session concept entirely, so the runtime doesn't populate or expect one, and `ai.mcp.protocol_version` records the revision instead. See [MCP version support](/ai-gateway/mcp-version-support/).

      Every other `ai.mcp` field behaves the same way across revisions. For the full list, see the [audit log reference](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs).
  - q: Why does a denied call have no `rpc` entry?
    a: |
      The ACL check runs before the request is dispatched as an RPC, so a denied call never becomes one. Only the `ai.mcp.audit` entry records it. That also means `rpc` latency and size data only ever covers calls that reached the upstream MCP server.
---

## Attach a File Log Policy

Create a File Log Policy and add it to the existing AI MCP Server, alongside the ACL configuration:

{% entity_examples %}
ai_gateway_policies:
  - ref: my-file-log
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-file-log
    display_name: "my-file-log"
    type: file-log
    enabled: true
    global: false
    config:
      path: /tmp/mcp.json

ai_gateway_mcp_servers:
  - ref: marketplace-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: marketplace-mcp
    display_name: "Marketplace API"
    type: passthrough-listener
    enabled: true
    policies:
      - !ref my-file-log#name
    access:
      auth_strategies:
        - my-key-auth
      acl_attribute_type: consumer
      acls:
        allow: []
      default_tool_acls:
        allow:
          - admin
        deny: []
    config:
      url: http://host.docker.internal:3001/mcp
      route:
        paths:
          - /mcp
      logging:
        payloads: false
        audits: true
      server:
        timeout: 60000
    tools:
      - name: list_users
        access:
          acls:
            allow:
              - admin
              - eason
            deny:
              - developer
      - name: get_user
        access:
          acls:
            allow:
              - admin
              - developer
      - name: list_orders
        access:
          acls:
            allow:
              - admin
              - developer
      - name: list_orders_for_user
        access:
          acls:
            allow:
              - admin
              - developer
      - name: search_orders
        access:
          acls:
            allow:
              - admin
            deny:
              - developer
{% endentity_examples %}

Setting `config.logging.audits: true` in the AI MCP Server configuration tells the runtime to record an ACL decision entry for every tool discovery and call, not just the RPC timing and size data that's recorded by default.

## Generate MCP traffic

Call the MCP server as two different AI Consumers.

1. Alice, in `admin`, successfully calls `list_orders`:

{% capture alice_call %}
<!-- vale off -->
{% validation request-check %}
url: /mcp/
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'MCP-Protocol-Version: 2026-07-28'
  - 'Mcp-Method: tools/call'
  - 'Mcp-Name: list_orders'
  - 'apikey: $ALICE_API_KEY'
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/call
  params:
    name: "list_orders"
    arguments: {}
    _meta:
      'io.modelcontextprotocol/protocolVersion': '2026-07-28'
      'io.modelcontextprotocol/clientCapabilities': {}
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ alice_call | indent }}

1. Bob, in `developer`, is denied `list_users`:

{% capture bob_call %}
<!-- vale off -->
{% validation request-check %}
url: /mcp/
method: POST
status_code: 403
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'MCP-Protocol-Version: 2026-07-28'
  - 'Mcp-Method: tools/call'
  - 'Mcp-Name: list_users'
  - 'apikey: $BOB_API_KEY'
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/call
  params:
    name: "list_users"
    arguments: {}
    _meta:
      'io.modelcontextprotocol/protocolVersion': '2026-07-28'
      'io.modelcontextprotocol/clientCapabilities': {}
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ bob_call | indent }}

## Validate the log entries

Each line in `/tmp/mcp.json` is a complete File Log entry, and MCP activity sits in its `ai.mcp` object alongside the standard `request`, `response`, and `consumer` fields. Read the audit logs in your Docker container, filtering to that object:

{% validation custom-command %}
command: |
  docker exec kong-ai-quickstart-gateway cat /tmp/mcp.json | jq '.ai.mcp'
expected:
  return_code: 0
render_output: false
{% endvalidation %}

An allowed call produces both an `rpc` entry and an `audit` entry; a denied call produces only an `audit` entry. Alice's allowed `list_orders` call produces:

```json
{
  "mcp_server_id": "37102e42-f18b-410a-ab8c-6719c914dd1c",
  "protocol_version": "2026-07-28",
  "rpc": [
    {
      "method": "tools/call",
      "id": "1",
      "latency": 3,
      "tool_name": "list_orders",
      "response_body_size": 5030
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
```
{:.no-copy-code}

In an `audit` entry, `consumer.identifier` tells you what `consumer.name` refers to. Here it's `consumer_group`, so `name` is the AI Consumer Group that granted access (`admin`), while `id` is the UUID of the AI Consumer that made the call (Alice). For the full field list, see the [audit log reference](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs).

Bob's denied `list_users` call has no `rpc` entry at all, only the `audit` entry recording the ACL decision:

```json
{
  "ai": {
    "mcp": {
      "audit": [
        {
          "primitive_name": "list_users",
          "consumer": {
            "id": "b2f6a2b1-6a15-4e3f-9e0b-6a2f7a1c9d10",
            "name": "developer",
            "identifier": "consumer_group"
          },
          "scope": "primitive",
          "primitive": "tool",
          "action": "deny"
        }
      ]
    }
  }
}
```
{:.no-copy-code}

{:.success}
> **MCP traffic in {{site.konnect_short_name}}**
>
> You can also see tool usage and ACL denials without setting up a File Log Policy, using {{site.konnect_short_name}} Analytics. Go to **Observability > Dashboards**, create a dashboard from the **Agentic analytics** template, and filter by tool name or AI Consumer.

For metrics-based observability instead of raw log entries, see [Monitor MCP traffic with OpenTelemetry](/ai-gateway/monitor-mcp-traffic-with-otel/).