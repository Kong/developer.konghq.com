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

description: Learn how to observe MCP tool activity after you apply access controls. Attach a File Log Policy to an AI MCP Server, generate traffic with the MCP Inspector CLI, then read the audit entries to see which tools each AI Consumer reached and how the ACLs decided each call.

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
    Use the [File Log Policy](/ai-gateway/policies/file-log/) to write MCP tool activity to a local file, and set `config.logging.audits: true` on the AI MCP Server so every ACL decision is recorded.

    This tutorial attaches a File Log Policy to the Petstore AI MCP Server you built in [Control MCP tool access with AI Consumer and AI Consumer Group ACLs](/ai-gateway/use-access-controls-for-mcp-tools/), generates allowed and denied tool calls with the MCP Inspector CLI, then reads the resulting `ai.mcp` log entries.

tools:
  - kongctl

prereqs:
  inline:
    - title: Petstore API
      include_content: prereqs/third-party/swagger-petstore

cleanup:
  inline:
    - title: Stop Petstore API
      include_content: cleanup/third-party/swagger-petstore
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: '/assets/icons/ai-gateway.svg'

faqs:
  - q: Why does a denied call have no `rpc` entry?
    a: |
      The ACL check runs before the request is dispatched as an RPC, so a denied call never becomes one. Only the `ai.mcp.audit` entry records it. That also means `rpc` latency and size data only ever covers calls that reached the upstream MCP server.
  - q: Why does a single tool call write several log entries?
    a: |
      The MCP Inspector CLI opens a fresh MCP session for each invocation, so one `tools/call` command produces a short sequence of requests: `initialize`, `notifications/initialized`, `tools/list`, and the tool call itself. Each one is a separate request through {{site.ai_gateway}}, so each gets its own File Log entry, and all of them share one `ai.mcp.mcp_session_id`.

      Both `tools/list` and the tool call carry an `ai.mcp.audit` array, because discovery and invocation are separate ACL decisions. The discovery entry has no `primitive_name`, since it covers the tool list as a whole rather than one tool.
  - q: Which MCP protocol revision appears in `ai.mcp.protocol_version`?
    a: |
      Whichever revision the client negotiates during `initialize`, not a value you configure on the AI MCP Server. The MCP Inspector CLI used in this tutorial negotiates `2025-11-25`, so entries include an `ai.mcp.mcp_session_id`. A client that negotiates `2026-07-28` has no session concept, and {{site.ai_gateway}} omits `mcp_session_id` for that traffic. See [MCP version support](/ai-gateway/mcp-version-support/).
---

## Attach a File Log Policy

Create a File Log Policy and attach it to the existing `petstore-acl-mcp` AI MCP Server.

Because `kongctl` manages each AI MCP Server declaratively, this configuration repeats the entity's full definition from the previous tutorial, with two additions: the new AI Policy in `policies`, and `config.logging.audits: true`.

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
  - ref: petstore-acl-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: petstore-acl-mcp
    display_name: "Petstore API"
    type: conversion-listener
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
      url: http://host.docker.internal:8080/api/v3
      route:
        paths:
          - /petstore-acl
      logging:
        payloads: false
        audits: true
      server:
        timeout: 60000
    tools:
      - name: get-pets-by-status
        description: Find pets by status
        method: GET
        path: /petstore-acl/pet/findByStatus
        access:
          acls:
            allow:
              - admin
              - support
              - eason
        parameters:
          - name: status
            in: query
            required: true
            schema:
              type: string
              enum:
                - available
                - pending
                - sold
            description: Status value to filter pets by
      - name: get-pet-by-id
        description: Get a pet by ID
        method: GET
        path: /petstore-acl/pet/{petId}
        access:
          acls:
            allow:
              - admin
              - support
        parameters:
          - description: ID of the pet to retrieve
            in: path
            name: petId
            required: true
            schema:
              type: integer
      - name: get-inventory
        description: Get pet inventories by status
        method: GET
        path: /petstore-acl/store/inventory
        access:
          acls:
            allow:
              - admin
              - support
      - name: get-order-by-id
        description: Get a purchase order by ID
        method: GET
        path: /petstore-acl/store/order/{orderId}
        access:
          acls:
            allow:
              - admin
              - support
        parameters:
          - description: ID of the order to retrieve
            in: path
            name: orderId
            required: true
            schema:
              type: integer
      - name: delete-pet
        description: Delete a pet
        method: DELETE
        path: /petstore-acl/pet/{petId}
        access:
          acls:
            allow:
              - admin
            deny:
              - support
        parameters:
          - description: ID of the pet to delete
            in: path
            name: petId
            required: true
            schema:
              type: integer
{% endentity_examples %}

## Generate MCP traffic

Call the AI MCP Server as two different AI Consumers, using the [MCP Inspector CLI](https://modelcontextprotocol.io/docs/tools/inspector#cli) and passing each one's API key in the `apikey` header.

1. Alice, in `admin`, successfully calls `get-pet-by-id`:

{% capture alice_call %}
<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    $KONNECT_PROXY_URL/petstore-acl \
    --transport http --method tools/call \
    --tool-name get-pet-by-id \
    --tool-arg path_petId=7 \
    --header "apikey: $ALICE_API_KEY" | jq -r '.content[0].text' | jq -c '.'
expected:
  return_code: 0
  message: |
    {"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
render_output: false
{% endvalidation %}
<!--vale on-->
{% endcapture %}

{{ alice_call | indent }}

1. Bob, in `support`, is denied `delete-pet`. The call is rejected with `HTTP 403 Forbidden`, which the MCP Inspector CLI reports as a transport error and a non-zero exit code:

{% capture bob_call %}
<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    $KONNECT_PROXY_URL/petstore-acl \
    --transport http --method tools/call \
    --tool-name delete-pet \
    --tool-arg path_petId=9 \
    --header "apikey: $BOB_API_KEY"
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->
{% endcapture %}

{{ bob_call | indent }}

## Validate the log entries

Each line in `/tmp/mcp.json` is a complete File Log entry, and MCP activity sits in an `ai.mcp` object alongside the standard `request`, `response`, and `consumer` fields.

Read the log from inside your {{site.ai_gateway}} Docker container. Filtering to entries that carry an `audit` array narrows the output to the ACL decisions, skipping the `initialize` and `notifications/initialized` handshake requests that each MCP Inspector CLI invocation also generates:

<!--vale off-->
{% validation custom-command %}
command: |
  docker exec kong-ai-quickstart-gateway cat /tmp/mcp.json \
    | jq 'select(.ai.mcp.audit) | .ai.mcp'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

You get four entries, because each AI Consumer's client discovers the tool list before invoking a tool, and discovery is itself an ACL decision. The entries without a `primitive_name` are the `tools/list` decisions; the two that name a tool are the calls.

An allowed call produces both an `rpc` entry and an `audit` entry. Alice's `get-pet-by-id` call looks like the following:

```json
{
  "mcp_session_id": "98971c19-9539-4611-9cfe-a9eefc11f702",
  "mcp_server_id": "8c3cd66f-4c4f-4809-a671-2f412a794d01",
  "protocol_version": "2025-11-25",
  "rpc": [
    {
      "method": "tools/call",
      "tool_name": "get-pet-by-id",
      "latency": 46,
      "response_body_size": 290,
      "id": "2"
    }
  ],
  "audit": [
    {
      "primitive": "tool",
      "scope": "primitive",
      "primitive_name": "get-pet-by-id",
      "consumer": {
        "name": "admin",
        "id": "327670e0-4d13-47a8-9453-5b7370bfbba7",
        "identifier": "consumer_group"
      },
      "action": "allow"
    }
  ],
  "tool_list_cache_hit": true
}
```
{:.no-copy-code}

In an `audit` entry, `consumer.id` is always the UUID of the AI Consumer that made the call, while `consumer.name` is the subject that actually matched the ACL rule. `consumer.identifier` tells you which kind of subject that was:

- `consumer_group`: an AI Consumer Group granted the decision, and `name` is the group. Alice's call matched through `admin`.
- `username`: the individual AI Consumer matched, and `name` is the AI Consumer's own name.

That means the same AI Consumer can show up under either identifier depending on which rule decided a given request. For the full field list, see the [audit log reference](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs).

Bob's denied `delete-pet` call has no `rpc` entry at all, only the `audit` entry recording the ACL decision:

```json
{
  "mcp_session_id": "1d8ca25a-50b5-4871-b4e9-81d0f2f3fa89",
  "mcp_server_id": "8c3cd66f-4c4f-4809-a671-2f412a794d01",
  "protocol_version": "2025-11-25",
  "tool_list_cache_hit": true,
  "audit": [
    {
      "primitive": "tool",
      "scope": "primitive",
      "primitive_name": "delete-pet",
      "consumer": {
        "name": "support",
        "id": "ae05d1a5-1a43-4176-a882-af5c2d0b2e78",
        "identifier": "consumer_group"
      },
      "action": "deny"
    }
  ]
}
```
{:.no-copy-code}

Confirm that the denial was recorded:

<!--vale off-->
{% validation custom-command %}
command: |
  docker exec kong-ai-quickstart-gateway cat /tmp/mcp.json \
    | jq -r '.ai.mcp.audit[]? | select(.primitive_name == "delete-pet") | .action' \
    | sort -u
expected:
  return_code: 0
  message: "deny"
render_output: false
{% endvalidation %}
<!--vale on-->

{:.success}
> **MCP traffic in {{site.konnect_short_name}}**
>
> You can also see tool usage and ACL denials without setting up a File Log Policy, using {{site.konnect_short_name}} Analytics. Go to **Observability > Dashboards**, create a dashboard from the **Agentic analytics** template, and filter by tool name or AI Consumer.

For metrics-based observability instead of raw log entries, see [Monitor MCP traffic with OpenTelemetry](/ai-gateway/monitor-mcp-traffic-with-otel/).
