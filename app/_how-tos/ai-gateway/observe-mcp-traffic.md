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

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: '/assets/icons/ai-gateway.svg'

faqs:
  - q: What's different about `2026-07-28` MCP traffic in these log entries compared to `2025-06-18` or `2025-11-25`?
    a: |
      Two things are specific to `2026-07-28` traffic:

      - There's no `mcp_session_id` field anywhere in the entry. `2026-07-28` removes the session concept entirely, so the runtime doesn't populate or expect one. See [MCP version support](/ai-gateway/mcp-version-support/).
      - `rpc.tool_name` is populated from the `Mcp-Name` header rather than parsed out of the JSON-RPC body, since `2026-07-28` requires that header on every call.
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
      url: http://localhost:3001
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
      - name: get_user
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
        description: List orders for a user
        method: GET
        path: /mcp/list_orders_for_user
        parameters: []
        access:
          acls:
            allow:
              - admin
              - developer
      - name: search_orders
        description: Search orders by name (case-insensitive substring)
        method: GET
        path: /mcp/search_orders
        parameters: []
        access:
          acls:
            allow:
              - admin
            deny:
              - developer
{% endentity_examples %}

`config.logging.audits: true` tells the runtime to record an ACL decision entry for every tool discovery and call, not just the RPC timing and size data that's recorded by default.

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
  - 'apikey: $ALICE_API_KEY'
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/call
  params:
    name: "list_orders"
    arguments: {}
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
  - 'apikey: $BOB_API_KEY'
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/call
  params:
    name: "list_users"
    arguments: {}
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ bob_call | indent }}

## Validate the log entries

Check the audit logs in your Docker container:

{% validation custom-command %}
command: |
  docker exec -it kong-quickstart-gateway cat /tmp/mcp.json
expected:
  return_code: 0
render_output: false
{% endvalidation %}

You should see one `rpc` entry and one `audit` entry per call. Alice's allowed `list_orders` call looks like:

```json
{
  "ai": {
    "mcp": {
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
  }
}
```
{:.collapsible .no-copy-code}

Bob's denied `list_users` call looks like:

```json
{
  "ai": {
    "mcp": {
      "rpc": [
        {
          "method": "tools/call",
          "id": "1",
          "tool_name": "list_users",
          "error": "HTTP 403 Forbidden"
        }
      ],
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
{:.collapsible .no-copy-code}

{:.success}
> **MCP traffic in {{site.konnect_short_name}}**
>
> You can also see tool usage and ACL denials without setting up a File Log Policy, using {{site.konnect_short_name}} Analytics. Go to **Observability > Dashboards**, create a dashboard from the **Agentic analytics** template, and filter by tool name or AI Consumer.

For metrics-based observability instead of raw log entries, see [Monitor MCP traffic with OpenTelemetry](/ai-gateway/monitor-mcp-traffic-with-otel/).
