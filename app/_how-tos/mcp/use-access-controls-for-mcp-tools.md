---
title: Control MCP tool access with Consumer and Consumer Group ACLs
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

description: Learn how to use the AI MCP Proxy plugin to restrict access to specific MCP tools based on Kong Consumers and Consumer Groups. Configure global and per-tool ACLs, define user roles, and validate access behavior using Insomnia’s MCP Client.

products:
  - gateway
  - ai-gateway
  - insomnia

permalink: /mcp/use-access-controls-for-mcp-tools/

series:
  id: mcp-acls
  position: 1

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
  q: How do I enforce control access to MCP tools using {{site.ai_gateway}}?
  a: |
    Use the AI MCP Proxy plugin to control access to MCP tools with global and
    per-tool ACLs based on Consumers and Consumer Groups. Use Insomnia’s MCP
    Client feature to test and validate which tools each user can access.

tools:
  - deck

prereqs:
  inline:
    - title: Mock API Server
      content: |
        Before using the [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin, you need an upstream MCP-compatible HTTP server to expose. For this tutorial, we’ll use a simple Express-based MCP server that simulates a marketplace system. It provides read-only access to sample users and their orders.

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

  entities:
    services:
      - mcp-acl-service
    routes:
      - mcp-acl-route
  konnect:
    - name: KONG_STATUS_LISTEN
      value: '0.0.0.0:8100'
---
## Set up Consumer authentication

Let's configure authentication so the {{site.base_gateway}} can identify each caller. We'll use the [Key Auth](/plugins/key-auth/) plugin so each user (or AI agent) presents an API key with requests:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      route: mcp-acl-route
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Create Consumer Groups for each AI usage tier

Now, let's configure Consumer Groups that reflect access levels. These groups govern MCP tool permissions:
- `admin` - full access
- `developer` - limited access
- `suspended` - blocked from MCP tools

{% entity_examples %}
entities:
  consumer_groups:
    - name: admin
    - name: developer
    - name: suspended
{% endentity_examples %}

## Create Consumers

Let's configure individual Consumers and assign them to groups. Each Consumer will use a unique API key and inherits group permissions which will govern access to MCP tools:

{% entity_examples %}
entities:
  consumers:
    - username: alice
      groups:
        - name: admin
      keyauth_credentials:
        - key: alice-key

    - username: bob
      groups:
        - name: developer
      keyauth_credentials:
        - key: bob-key

    - username: carol
      groups:
        - name: suspended
      keyauth_credentials:
        - key: carol-key

    - username: eason
      keyauth_credentials:
        - key: eason-key
{% endentity_examples %}

## Configure the AI MCP Proxy plugin

Now, let's configure the AI MCP Proxy plugin to apply tool-level access rules. The plugin controls which users or AI agents can see or call each MCP tool. Access is determined by Consumer Groups and individual Consumers using allow and deny lists. A tool ACL replaces the default rule when present.

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

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: mcp-acl-route
      config:
        mode: passthrough-listener
        include_consumer_groups: true
        default_acl:
          - scope: tools
            allow:
              - developer
              - admin
            deny:
              - suspended
        logging:
          log_payloads: false
          log_statistics: true
          log_audits: true
        tools:
          - description: List users
            name: list_users
            acl:
              allow:
                - admin
                - eason
              deny:
                - developer
          - description: Get user
            name: get_user
            acl:
              allow:
                - admin
                - developer
          - description: List orders
            name: list_orders
            acl:
              allow:
                - admin
                - developer
          - description: List orders for users
            name: list_orders_for_user
            acl:
              allow:
                - admin
                - developer
          - description: Search orders by name (case-insensitive substring)
            name: search_orders
            acl:
              allow:
                - admin
              deny:
                - developer
{% endentity_examples %}

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
1. The connection should fail with a `INVALID_PARAMS -32602` response.<br/>
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
