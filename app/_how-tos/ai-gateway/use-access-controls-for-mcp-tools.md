---
title: Control MCP tool access with AI Consumer and AI Consumer Group ACLs
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: MCP version support
    url: /ai-gateway/mcp-version-support/
  - text: Observe MCP traffic with the File Log Policy
    url: /ai-gateway/observe-mcp-traffic/

description: Learn how to create an AI MCP Server entity in {{site.ai_gateway}} to restrict access to specific MCP tools based on AI Consumers and AI Consumer Groups. Configure default and per-tool ACLs, define user roles, and validate access behavior as a stateless 2026-07-28 MCP client.

products:
  - ai-gateway

series:
  id: mcp-acls-2-1
  position: 1

permalink: /ai-gateway/use-access-controls-for-mcp-tools/

works_on:
  - konnect

min_version:
  ai-gateway: '2.1'

entities:
  - ai-mcp-server
  - ai-consumer
  - ai-consumer-group
  - ai-auth-strategy

tags:
  - ai
  - mcp
  - security

tldr:
  q: How do I enforce control access to MCP tools using {{site.ai_gateway}}?
  a: |
    Use the [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity to control access to MCP tools with default and per-tool ACLs based on AI Consumers and AI Consumer Groups.

    This tutorial shows you how to configure four AI Consumers across three access tiers, and how to validate which tools each one can see and call as a stateless `2026-07-28` MCP client, no session handshake required.

tools:
  - kongctl

prereqs:
  inline:
    - title: Mock API Server
      content: |
        Before creating an AI MCP Server, you need an upstream MCP-compatible HTTP server to expose. For this tutorial, use a simple Express-based MCP server that simulates a marketplace system. It provides read-only access to sample users and their orders.

        The server exposes a single `/mcp` endpoint and registers tools instead of REST routes, including:

        * `list_users`
        * `get_user`
        * `list_orders`
        * `list_orders_for_user`
        * `search_orders`

        These tools operate on in-memory marketplace data, allowing you to test MCP behavior without connecting to a real backend.

        Run the following command to clone the repository, install dependencies, build the server, and start it:

        ```bash
        git clone https://github.com/tomek-labuk/marketplace-acl.git && \
        cd marketplace-acl && \
        npm install && \
        npm run build && \
        node dist/server.js
        ```

        When the server starts, it listens at:

        ```
        http://localhost:3001/mcp
        ```
      icon_url: /assets/icons/github.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: '/assets/icons/ai-gateway.svg'
---

## Create AI Consumer Groups for each usage tier

Configure [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) that reflect access levels. These groups govern MCP tool permissions:

- `admin`, full access
- `developer`, limited access
- `suspended`, blocked from MCP tools

{% entity_examples %}
ai_gateway_consumer_groups:
  - ref: admin
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Admin
    name: admin
    policies: []
  - ref: developer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Developer
    name: developer
    policies: []
  - ref: suspended
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Suspended
    name: suspended
    policies: []
{% endentity_examples %}

## Create AI Consumers

1. Configure individual AI Consumers. Each one inherits the ACL rules of its group, and Eason, who belongs to no group, is only reachable through the tool-level ACLs you'll set in the next section:

{% capture consumers %}
{% entity_examples %}
ai_gateway_consumers:
  - ref: alice
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Alice
    name: alice
    type: api-key
    policies: []
  - ref: bob
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Bob
    name: bob
    type: api-key
    policies: []
  - ref: carol
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Carol
    name: carol
    type: api-key
    policies: []
  - ref: eason
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Eason
    name: eason
    type: api-key
    policies: []
{% endentity_examples %}
{% endcapture %}

{{ consumers | indent }}

1. Add each AI Consumer to its group:

{% capture consumer_groups %}
{% entity_examples %}
ai_gateway_consumer_groups:
  - ref: admin
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: admin
    display_name: Admin
    policies: []
    consumers:
      - !ref alice#name
  - ref: developer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: developer
    display_name: Developer
    policies: []
    consumers:
      - !ref bob#name
  - ref: suspended
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: suspended
    display_name: Suspended
    policies: []
    consumers:
      - !ref carol#name
{% endentity_examples %}
{% endcapture %}

{{ consumer_groups | indent }}

1. Create an API key credential for Alice, and save the generated key. {{site.ai_gateway}} generates the key value; it isn't set by you and can't be retrieved again after this step:

{% capture alice_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$ALICE_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Alice key
  name: alice-key
  type: api-key
capture:
  - variable: ALICE_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ alice_credential | indent }}

1. Create an API key credential for Bob:

{% capture bob_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$BOB_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Bob key
  name: bob-key
  type: api-key
capture:
  - variable: BOB_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ bob_credential | indent }}

1. Create an API key credential for Carol:

{% capture carol_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CAROL_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Carol key
  name: carol-key
  type: api-key
capture:
  - variable: CAROL_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ carol_credential | indent }}

1. Create an API key credential for Eason:

{% capture eason_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$EASON_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Eason key
  name: eason-key
  type: api-key
capture:
  - variable: EASON_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ eason_credential | indent }}

## Create an AI Auth Strategy

Create a `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) so each AI Consumer presents their key in the `apikey` header:

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: my-key-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-key-auth
    display_name: "my-key-auth"
    type: key-auth
    config:
      key_names:
        - apikey
      key_in_header: true
      key_in_query: false
{% endentity_examples %}

## Configure the AI MCP Server

Configure the AI MCP Server to apply tool-level access rules. The AI MCP Server controls which AI Consumers can see or call each MCP tool. Access is determined by AI Consumer Groups and individual AI Consumers using `allow` and `deny` lists. A tool ACL replaces the default rule when present.

The following table shows the effective permissions for the configuration:

<!-- vale off -->
{% table %}
columns:
  - title: MCP tool
    key: tool
  - title: Admin group
    key: admin
  - title: Developer group
    key: developer
  - title: Eason consumer
    key: eason
  - title: Suspended group
    key: suspended
rows:
  - tool: "`list_users`"
    admin: Yes
    developer: No
    eason: Yes
    suspended: No
  - tool: "`get_user`"
    admin: Yes
    developer: Yes
    eason: No
    suspended: No
  - tool: "`list_orders`"
    admin: Yes
    developer: Yes
    eason: No
    suspended: No
  - tool: "`list_orders_for_user`"
    admin: Yes
    developer: Yes
    eason: No
    suspended: No
  - tool: "`search_orders`"
    admin: Yes
    developer: No
    eason: No
    suspended: No
{% endtable %}
<!-- vale on -->

The following configuration applies the ACL rules for the MCP tools shown in the preceding table:

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: marketplace-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: marketplace-mcp
    display_name: "Marketplace API"
    type: passthrough-listener
    enabled: true
    policies: []
    access:
      auth_strategies:
        - !ref my-key-auth#name
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

{:.info}
> `suspended` has no per-tool ACL entry anywhere, so Carol falls through to `access.default_tool_acls`, which only allows `admin`. That's what blocks her from every tool without needing an explicit `deny`.

## Validate access as a stateless MCP client

`2026-07-28` clients don't perform an `initialize` handshake, and {{site.ai_gateway}} doesn't issue an `Mcp-Session-Id`. Every request declares its protocol revision through the `MCP-Protocol-Version` header and carries the AI Consumer's API key in the `apikey` header. Validate the ACL rules by calling `tools/list` directly against the route for each AI Consumer.

1. Alice (admin group): sees every tool

{% capture alice_list %}
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
display_headers: true
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/list
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ alice_list | indent }}

   The response lists all five tools. Alice belongs to `admin`, so calling `search_orders`, the most restricted tool, also succeeds:

{% capture alice_search %}
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
  id: 2
  method: tools/call
  params:
    name: "search_orders"
    arguments: {}
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ alice_search | indent }}

1. Bob (developer group): denied list_users and search_orders

{% capture bob_list %}
<!-- vale off -->
{% validation request-check %}
url: /mcp/
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'MCP-Protocol-Version: 2026-07-28'
  - 'apikey: $BOB_API_KEY'
display_headers: true
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/list
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ bob_list | indent }}

   The response only lists `get_user`, `list_orders`, and `list_orders_for_user`. Calling `list_users` directly confirms the same rule:

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
  id: 2
  method: tools/call
  params:
    name: "list_users"
    arguments: {}
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ bob_call | indent }}

   The call returns `HTTP 403 Forbidden`. Bob's `developer` group is on the `deny` list for `list_users` and isn't on the `allow` list for `search_orders`, so both tools are unreachable.

1. Carol (suspended group): denied every tool

{% capture carol_call %}
<!-- vale off -->
{% validation request-check %}
url: /mcp/
method: POST
status_code: 403
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'MCP-Protocol-Version: 2026-07-28'
  - 'apikey: $CAROL_API_KEY'
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

{{ carol_call | indent }}

   Carol belongs to `suspended`, which isn't in `access.default_tool_acls.allow` and has no tool-specific override, so every tool call returns `HTTP 403 Forbidden`.

1. Eason (no group): only list_users

{% capture eason_list %}
<!-- vale off -->
{% validation request-check %}
url: /mcp/
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, text/event-stream'
  - 'MCP-Protocol-Version: 2026-07-28'
  - 'apikey: $EASON_API_KEY'
display_headers: true
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/list
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ eason_list | indent }}

   The response lists only `list_users`. Eason belongs to no AI Consumer Group, but `list_users`' own `access.acls.allow` names him directly, alongside `admin`. Every other tool falls back to `access.default_tool_acls`, which doesn't include him.

To see how these allow and deny decisions are recorded, see [Observe MCP traffic with the File Log Policy](/ai-gateway/observe-mcp-traffic/).
