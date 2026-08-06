---
title: Control MCP tool access with Consumer and Consumer Group ACLs
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

description: Learn how to create an AI MCP Server entity in {{site.ai_gateway}} to restrict access to specific MCP tools based on AI Consumers and AI Consumer Groups. Configure global and per-tool ACLs, define user roles, and validate access behavior using Insomnia’s MCP Client.

products:
  - ai-gateway
  - insomnia

permalink: /ai-gateway/use-access-controls-for-mcp-tools/

series:
  id: mcp-acls
  position: 1

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - openai
  - mcp

tldr:
  q: How do I enforce control access to MCP tools using {{site.ai_gateway}}?
  a: |
    Use the AI MCP Server to control access to MCP tools with global and
    per-tool ACLs based on AI Consumers and AI Consumer Groups. Use Insomnia’s MCP
    Client feature to test and validate which tools each user can access.

tools:
  - kongctl

prereqs:
  inline:
    - title: Mock API Server
      content: |
        Before creating an AI MCP Server, you need an upstream MCP-compatible HTTP server to expose. For this tutorial, we’ll use a simple Express-based MCP server that simulates a marketplace system. It provides read-only access to sample users and their orders.

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

---


## Create Consumer Groups for each AI usage tier

Start by configuring [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) that reflect access levels. 

These groups govern MCP tool permissions:
- `admin` - full access
- `developer` - limited access
- `suspended` - blocked from MCP tools

{% entity_examples %}
ai_gateway_consumer_groups:
  - ref: admin
    ai_gateway: !lookup name:ai-quickstart
    display_name: Internal Teams
    name: admin
    policies: []
  - ref: developer
    ai_gateway: !lookup name:ai-quickstart
    display_name: Internal Teams
    name: developer
    policies: []
  - ref: suspended
    ai_gateway: !lookup name:ai-quickstart
    display_name: Internal Teams
    name: suspended
    policies: []
{% endentity_examples %}

## Create Consumers

Configure individual AI Consumers and assign them to groups. 

We'll use the [Key Auth](/ai-gateway/policies/key-auth/) AI Policy so that each AI Consumer presents an API key in their requests that is used for `api-key` authentication.

Each AI Consumer inherits group permissions that govern access to MCP tools:

{% entity_examples %}
ai_gateway_consumers:
  - ref: alice
    ai_gateway: !lookup name:ai-quickstart
    display_name: Alice
    name: alice
    type: api-key
    policies:
      - !ref my-key-auth#name
  - ref: bob
    ai_gateway: !lookup name:ai-quickstart
    display_name: Bob
    name: bob
    type: api-key
    policies:
      - !ref my-key-auth#name
  - ref: carol
    ai_gateway: !lookup name:ai-quickstart
    display_name: Carol
    name: carol
    type: api-key
    policies: []
  - ref: eason
    ai_gateway: !lookup name:ai-quickstart
    display_name: Eason
    name: eason
    type: api-key
    policies:
      - !ref my-key-auth#name
ai_gateway_policies:
  - ref: my-key-auth
    ai_gateway: !lookup name:ai-quickstart
    name: my-key-auth
    display_name: "my-key-auth"
    type: key-auth
    config:
      key_names:
          - apikey
{% endentity_examples %}

## Configure the AI MCP Proxy plugin

Configure the AI MCP Server to apply tool-level access rules. The AI MCP Server controls which users or AI agents can see or call each MCP tool. Access is determined by AI Consumer Groups and individual AI Consumers using allow and deny lists. A tool ACL replaces the default rule when present.

The table below shows the effective permissions for the configuration:

<!-- vale off -->
{% table %}
columns:
  - title: MCP Tool
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

The following plugin configuration applies the ACL rules for the MCP tools shown in the table above:


```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateway_mcp_servers:
  - ref: marketplace-mcp
    ai_gateway: !lookup {id: $AI_GATEWAY_ID}
    name: marketplace-mcp
    display_name: "Marketplace API"
    type: passthrough-listener
    enabled: true
    policies: []
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

## Validate the configuration

Let's use Insomnia's MCP Client feature to validate our ACL configuration:

1. Go to the Insomnia app.
1. Click **Create MCP Client** in the left sidebar.
1. Enter the preferred name and click **Create**.
1. In the `HTTP` field enter `http://localhost:8000/mcp`.
1. Go to the **Auth** tab.
1. Select **API Key** from the Auth type dropdown.

Now let's verify access for each user by connecting with their API key:

{% navtabs "validate-mcp-access" %}
{% navtab "Alice (admin group)" %}

1. Enter `apikey` in the Key field.
1. Enter `alice-key` in the Value field.
1. Click the **Connect** button.
1. Once connected, Insomnia should list these tools in the sidebar:

   ```text
   list_users
   get_user
   list_orders
   list_orders_for_user
   search_orders
   ```

   Alice belongs to the **admin** group and has access to all tools.
1. Click **Disconnect** to switch to another user.

{% endnavtab %}
{% navtab "Bob (developer group)" %}

1. Enter `apikey` in the Key field.
1. Enter `bob-key` in the Value field.
1. Click the **Connect** button.
1. Once connected, Insomnia should list these tools in the sidebar:

   ```text
   get_user
   list_orders
   list_orders_for_user
   ```
   {:.no-copy-code}

   Bob belongs to the **developer** group and is denied access to `list_users`.
1. Click **Disconnect** to update the key for the next user.

{% endnavtab %}
{% navtab "Carol (suspended group)" %}

1. Enter `apikey` in the Key field.
1. Enter `carol-key` in the Value field.
1. Click the **Connect** button.
   
   The connection should fail with a `HTTP 403 Forbidden` response.<br/>
   Carol belongs to the **suspended** group, which is globally denied access to all tools.
1. Click **Disconnect** to switch to another user.

{% endnavtab %}
{% navtab "Eason (no group)" %}

1. Enter `apikey` in the Key field.
1. Enter `eason-key` in the Value field.
1. Click the **Connect** button.
1. Once connected, Insomnia should list this tool in the sidebar:

   ```text
   list_users
   ```
  {:.no-copy-code}

   Eason is not part of any group but is explicitly allowed access to `list_users` in the tool’s ACL.
1. Click **Disconnect** after validation.

{% endnavtab %}
{% endnavtabs %}
