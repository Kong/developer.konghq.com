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

tools:
  - kongctl

faqs:
  - q: Why doesn't a `2026-07-28` client perform an `initialize` handshake or receive an `Mcp-Session-Id`?
    a: |
      The [`2026-07-28` MCP revision](/ai-gateway/mcp-version-support/#2026-07-28) removes the session concept entirely. Every request is self-contained: it declares its protocol revision through the `MCP-Protocol-Version` header and carries the AI Consumer's API key in the `apikey` header, instead of relying on state established during a prior handshake.
  - q: Why does every `2026-07-28` request body need a `params._meta` envelope?
    a: |
      The [stateless `2026-07-28` base protocol](https://modelcontextprotocol.io/specification/2026-07-28/basic#_meta) requires every request body to repeat the protocol version, plus the calling client's capabilities, in a `params._meta` envelope, since the server can't infer either from a prior handshake.
  - q: Why do `2026-07-28` requests need `Mcp-Method` and `Mcp-Name` headers?
    a: |
      The [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http#request-metadata) mirrors the body's `method` into an `Mcp-Method` header on every request, and its `params.name` into an `Mcp-Name` header on `tools/call` requests specifically. A header that doesn't match the body is rejected with `HTTP 400` and JSON-RPC error `-32020`.

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

        These tools operate on in-memory marketplace data, allowing you to test MCP behavior without connecting to a real backend. It's built on the [MCP TypeScript SDK v2](https://github.com/modelcontextprotocol/typescript-sdk), so it speaks the stateless `2026-07-28` revision this guide validates against.

        1. Create a project directory for the mock server:

           ```bash
           mkdir marketplace-mcp && cd marketplace-mcp
           ```

        1. Set up the package manifest:

           ```bash
           cat <<'EOF' > package.json
           {
             "name": "sample-users-mcp-server",
             "version": "2.0.0",
             "private": true,
             "type": "module",
             "scripts": {
               "build": "tsc -p tsconfig.json",
               "start": "node --enable-source-maps ./dist/server.js"
             },
             "dependencies": {
               "@modelcontextprotocol/server": "^2.0.0",
               "@modelcontextprotocol/express": "^2.0.0",
               "@modelcontextprotocol/node": "^2.0.0",
               "express": "^4.19.2",
               "zod": "^4.2.0"
             },
             "devDependencies": {
               "@types/express": "^5.0.5",
               "@types/node": "^24.9.2",
               "typescript": "^5.6.3"
             }
           }
           EOF
           ```
           {:.collapsible}

        1. Add a `tsconfig.json`:

           ```bash
           cat <<'EOF' > tsconfig.json
           {
             "compilerOptions": {
               "target": "ES2022",
               "module": "ESNext",
               "moduleResolution": "Bundler",
               "strict": true,
               "esModuleInterop": true,
               "forceConsistentCasingInFileNames": true,
               "outDir": "dist",
               "skipLibCheck": true,
               "types": ["node"]
             },
             "include": ["src"]
           }
           EOF
           ```
           {:.collapsible}

        1. Add the server itself:

           ```bash
           mkdir src
           cat <<'EOF' > src/server.ts
           import { createMcpExpressApp } from '@modelcontextprotocol/express';
           import { toNodeHandler } from '@modelcontextprotocol/node';
           import { createMcpHandler, McpServer } from '@modelcontextprotocol/server';
           import * as z from 'zod/v4';

           // -------------------- In-memory data --------------------
           const users: Record<string, string> = {
             a1b2c3d4: "Alice Johnson",
             e5f6g7h8: "Bob Smith",
             i9j0k1l2: "Charlie Lee",
             m3n4o5p6: "Diana Evans",
             q7r8s9t0: "Ethan Brown",
             u1v2w3x4: "Fiona Clark",
             y5z6a7b8: "George Harris",
             c9d0e1f2: "Hannah Lewis",
             g3h4i5j6: "Ian Walker",
             k7l8m9n0: "Julia Turner"
           };

           type Order = { id: string; name: string; userId: string };
           const orders: Order[] = [
             { id: "ord001", name: "Sugar (50kg)", userId: "a1b2c3d4" },
             { id: "ord002", name: "Cleaning Supplies Pack", userId: "a1b2c3d4" },
             { id: "ord003", name: "Canned Tomatoes (100 cans)", userId: "a1b2c3d4" },
             { id: "ord004", name: "Flour (100kg)", userId: "e5f6g7h8" },
             { id: "ord005", name: "Dish Soap (10 bottles)", userId: "e5f6g7h8" },
             { id: "ord006", name: "Salt (25kg)", userId: "e5f6g7h8" },
             { id: "ord007", name: "Olive Oil (20L)", userId: "i9j0k1l2" },
             { id: "ord008", name: "Baking Powder (10kg)", userId: "i9j0k1l2" },
             { id: "ord009", name: "Rice (200kg)", userId: "m3n4o5p6" },
             { id: "ord010", name: "Vegetable Oil (15L)", userId: "m3n4o5p6" },
             { id: "ord011", name: "Pasta (80kg)", userId: "m3n4o5p6" },
             { id: "ord012", name: "Canned Beans (50 cans)", userId: "m3n4o5p6" },
             { id: "ord013", name: "Toilet Paper (Case of 48)", userId: "q7r8s9t0" },
             { id: "ord014", name: "Hand Sanitizer (20 bottles)", userId: "q7r8s9t0" },
             { id: "ord015", name: "Laundry Detergent (10L)", userId: "u1v2w3x4" },
             { id: "ord016", name: "Trash Bags (100 ct)", userId: "u1v2w3x4" },
             { id: "ord017", name: "Disinfectant Spray (5 bottles)", userId: "u1v2w3x4" },
             { id: "ord018", name: "Coffee Beans (30kg)", userId: "k7l8m9n0" },
             { id: "ord019", name: "Tea Bags (500ct)", userId: "k7l8m9n0" },
             { id: "ord020", name: "Condensed Milk (40 cans)", userId: "k7l8m9n0" },
             { id: "ord021", name: "Paper Towels (24 rolls)", userId: "g3h4i5j6" },
             { id: "ord022", name: "Broom & Mop Set", userId: "g3h4i5j6" },
             { id: "ord023", name: "Cereal (20 boxes)", userId: "c9d0e1f2" },
             { id: "ord024", name: "Powdered Milk (10kg)", userId: "c9d0e1f2" },
             { id: "ord025", name: "Snacks Variety Pack", userId: "c9d0e1f2" },
             { id: "ord026", name: "Cooking Gas Cylinder", userId: "y5z6a7b8" },
             { id: "ord027", name: "Napkins (1000ct)", userId: "y5z6a7b8" }
           ];

           // -------------------- MCP Server --------------------
           const handler = createMcpHandler(
             () => {
               const server = new McpServer({ name: "sample-users-mcp", version: "2.0.0" });

               server.registerTool(
                 "list_users",
                 {
                   description: "List all users (id, fullName).",
                   inputSchema: z.object({}),
                   outputSchema: z.object({
                     users: z.array(z.object({ id: z.string(), fullName: z.string() }))
                   })
                 },
                 async () => {
                   const list = Object.entries(users).map(([id, fullName]) => ({ id, fullName }));
                   const output = { users: list };
                   return {
                     content: [{ type: "text", text: JSON.stringify(output, null, 2) }],
                     structuredContent: output
                   };
                 }
               );

               server.registerTool(
                 "get_user",
                 {
                   description: "Get a single user by id.",
                   inputSchema: z.object({ id: z.string() }),
                   outputSchema: z.object({
                     found: z.boolean(),
                     user: z.object({ id: z.string(), fullName: z.string() }).nullable()
                   })
                 },
                 async ({ id }) => {
                   const fullName = users[id];
                   const output = fullName != null
                     ? { found: true, user: { id, fullName } }
                     : { found: false, user: null };
                   return {
                     content: [{ type: "text", text: JSON.stringify(output, null, 2) }],
                     structuredContent: output
                   };
                 }
               );

               server.registerTool(
                 "list_orders",
                 {
                   description: "List all orders.",
                   inputSchema: z.object({}),
                   outputSchema: z.object({
                     orders: z.array(z.object({ id: z.string(), name: z.string(), userId: z.string() }))
                   })
                 },
                 async () => {
                   const output = { orders };
                   return {
                     content: [{ type: "text", text: JSON.stringify(output, null, 2) }],
                     structuredContent: output
                   };
                 }
               );

               server.registerTool(
                 "list_orders_for_user",
                 {
                   description: "List orders by userId.",
                   inputSchema: z.object({ userId: z.string() }),
                   outputSchema: z.object({
                     userExists: z.boolean(),
                     orders: z.array(z.object({ id: z.string(), name: z.string(), userId: z.string() }))
                   })
                 },
                 async ({ userId }) => {
                   const exists = users[userId] != null;
                   const userOrders = exists ? orders.filter((o) => o.userId === userId) : [];
                   const output = { userExists: exists, orders: userOrders };
                   return {
                     content: [{ type: "text", text: JSON.stringify(output, null, 2) }],
                     structuredContent: output
                   };
                 }
               );

               server.registerTool(
                 "search_orders",
                 {
                   description: "Search orders by name (case-insensitive substring).",
                   inputSchema: z.object({ q: z.string().min(1) }),
                   outputSchema: z.object({
                     count: z.number(),
                     results: z.array(z.object({ id: z.string(), name: z.string(), userId: z.string() }))
                   })
                 },
                 async ({ q }) => {
                   const needle = q.toLowerCase();
                   const results = orders.filter((o) => o.name.toLowerCase().includes(needle));
                   const output = { count: results.length, results };
                   return {
                     content: [{ type: "text", text: JSON.stringify(output, null, 2) }],
                     structuredContent: output
                   };
                 }
               );

               return server;
             },
             { responseMode: 'json' }
           );

           // -------------------- HTTP wiring --------------------
           // Bind to every interface and allow the Host header Kong's dataplane container
           // sends (host.docker.internal) so the containerized gateway can reach this process.
           const app = createMcpExpressApp({
             host: '0.0.0.0',
             allowedHosts: ['localhost', '127.0.0.1', 'host.docker.internal']
           });

           const node = toNodeHandler(handler);
           app.all('/mcp', (req, res) => void node(req, res, req.body));

           const PORT = parseInt(process.env.PORT || "3001", 10);
           app.listen(PORT, '0.0.0.0', () => {
             console.log(`MCP Server (Streamable HTTP, 2026-07-28) listening at http://localhost:${PORT}/mcp`);
           });
           EOF
           ```
           {:.collapsible}

        1. Install dependencies, build, and start the server:

           ```bash
           npm install && \
           npm run build && \
           npm start
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

- `admin`: full access
- `developer`: limited access
- `suspended`: blocked from MCP tools

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

1. Configure individual AI Consumers and add them to their groups. Each one inherits the ACL rules of its group, and Eason, who belongs to no group, is only reachable through the tool-level ACLs you'll set in the next section:

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

{{ consumers | indent }}

1. Export each AI Consumer's ID as an environment variable using `kongctl get`. The credential requests that follow identify each consumer by ID, not by name:

   ```bash
   export ALICE_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" alice --output json --jq '.id' -r)
   export BOB_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" bob --output json --jq '.id' -r)
   export CAROL_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" carol --output json --jq '.id' -r)
   export EASON_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" eason --output json --jq '.id' -r)
   ```

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
extract_body:
  - name: 'api_key'
    variable: ALICE_API_KEY
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
extract_body:
  - name: 'api_key'
    variable: BOB_API_KEY
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
extract_body:
  - name: 'api_key'
    variable: CAROL_API_KEY
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
extract_body:
  - name: 'api_key'
    variable: EASON_API_KEY
capture:
  - variable: EASON_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ eason_credential | indent }}

## Configure the AI MCP Server

Configure the [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) to apply tool-level access rules. The AI MCP Server controls which AI Consumers can see or call each MCP tool. Access is determined by AI Consumer Groups and individual AI Consumers using `allow` and `deny` lists. A tool ACL replaces the default rule when present.

The following table shows the effective permissions for this configuration:

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

Apply the following configuration to configure:
* A `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) so each AI Consumer presents their key in the `apikey` header
* The AI MCP Servers and their ACL rules

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
      url: http://host.docker.internal:3001/mcp
      route:
        paths:
          - /mcp
      logging:
        payloads: false
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

{:.info}
> `suspended` has no per-tool ACL entry anywhere, so Carol falls through to `access.default_tool_acls`, which only allows `admin`. This blocks her from every tool without needing an explicit `deny`.

## Validate

Validate the ACL rules by calling `tools/list` directly against the route for each AI Consumer.

1. Check that Alice (`admin` group) sees every tool:

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
  - 'Mcp-Method: tools/list'
  - 'apikey: $ALICE_API_KEY'
display_headers: true
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/list
  params:
    _meta:
      'io.modelcontextprotocol/protocolVersion': '2026-07-28'
      'io.modelcontextprotocol/clientCapabilities': {}
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
  - 'Mcp-Method: tools/call'
  - 'Mcp-Name: search_orders'
  - 'apikey: $ALICE_API_KEY'
body:
  jsonrpc: '2.0'
  id: 2
  method: tools/call
  params:
    name: "search_orders"
    arguments:
      q: "rice"
    _meta:
      'io.modelcontextprotocol/protocolVersion': '2026-07-28'
      'io.modelcontextprotocol/clientCapabilities': {}
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ alice_search | indent }}

1. Check that Bob (`developer` group) is denied access to `list_users` and `search_orders`:

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
  - 'Mcp-Method: tools/list'
  - 'apikey: $BOB_API_KEY'
display_headers: true
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/list
  params:
    _meta:
      'io.modelcontextprotocol/protocolVersion': '2026-07-28'
      'io.modelcontextprotocol/clientCapabilities': {}
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
  - 'Mcp-Method: tools/call'
  - 'Mcp-Name: list_users'
  - 'apikey: $BOB_API_KEY'
body:
  jsonrpc: '2.0'
  id: 2
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

   The call returns `HTTP 403 Forbidden`. Bob's `developer` group is on the `deny` list for `list_users` and isn't on the `allow` list for `search_orders`, so both tools are unreachable.

1. Check that Carol (`suspended` group) is denied access to every tool

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
  - 'Mcp-Method: tools/call'
  - 'Mcp-Name: list_orders'
  - 'apikey: $CAROL_API_KEY'
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

{{ carol_call | indent }}

   Carol belongs to `suspended`, which isn't in `access.default_tool_acls.allow` and has no tool-specific override, so every tool call returns `HTTP 403 Forbidden`.

1. Check that Eason (no group) only has access to `list_users`:

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
  - 'Mcp-Method: tools/list'
  - 'apikey: $EASON_API_KEY'
display_headers: true
body:
  jsonrpc: '2.0'
  id: 1
  method: tools/list
  params:
    _meta:
      'io.modelcontextprotocol/protocolVersion': '2026-07-28'
      'io.modelcontextprotocol/clientCapabilities': {}
{% endvalidation %}
<!-- vale on -->
{% endcapture %}

{{ eason_list | indent }}

   The response lists only `list_users`. Eason belongs to no AI Consumer Group, but `list_users`' own `access.acls.allow` names him directly, alongside `admin`. Every other tool falls back to `access.default_tool_acls`, which doesn't include him.