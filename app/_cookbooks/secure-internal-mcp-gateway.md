---
title: Secure Internal MCP Gateway
description: Aggregate multiple internal APIs into a single MCP server with OAuth 2.1 authentication and tool-level access control via consumer-group ACLs.
url: "/cookbooks/secure-internal-mcp-gateway/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - mcp
  - access-control
featured: false
popular: false
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `secure-internal-mcp-gateway-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Identity Provider
      content: |
        The aggregated MCP endpoint authenticates users against your identity provider (IdP) with token introspection, and reads their teams from a `groups` claim. This cookbook covers Okta and Keycloak. Each setup creates two applications: a confidential client that Kong uses to call the introspection endpoint, and a public client for the MCP client.

        {% navtabs "Identity Provider" %}
        {% navtab "Okta" %}

        You need an Okta organization with admin access.

        **Create the Kong MCP Gateway application**

        This confidential client represents Kong. Kong uses its credentials to call Okta's introspection endpoint ([Okta: Client Credentials flow](https://developer.okta.com/docs/guides/implement-grant-type/clientcreds/main/)).

        1. In the Okta Admin Console, go to **Applications and Resources > Applications**, click **Create App Integration**, and select **Classic experience**.
        1. Select **API Services**, then click **Next**.
        1. Name the application `Kong MCP Gateway` and click **Save**.
        1. On the **General** tab, in **Client Credentials**, copy the **Client ID** and the **Client secret**.

        **Create the MCP Client application**

        This public client represents Insomnia. It uses Authorization Code with PKCE and no client secret ([Okta: Authorization Code with PKCE](https://developer.okta.com/docs/guides/implement-grant-type/authcodepkce/main/)).

        1. Go to **Applications and Resources > Applications**, click **Create App Integration**, and select **Classic experience**.
        1. Select **OIDC - OpenID Connect** and **Single-Page Application**, then click **Next**.
        1. Name the application `MCP Client`.
        1. Set the sign-in redirect URI to `https://app.insomnia.rest/oauth/redirect`, Insomnia's default OAuth redirect URL.
        1. Click **Save**.
        1. In **Client Credentials**, confirm that client authentication is **None**. With **None**, Okta requires PKCE.
        1. Copy the **Client ID**. You enter it in Insomnia.

        **Add the groups claim**

        The OpenID Connect AI Auth Strategy reads the `groups` claim and maps each value to the AI Consumer Group with the same name ([Okta: Customize tokens with a groups claim](https://developer.okta.com/docs/guides/customize-tokens-groups-claim/main/)).

        1. Go to **Security > API** and select the `default` authorization server.
        1. Click the **Claims** tab, then click **Add Claim**.
        1. Set **Name** to `groups`, keep **Include in token type** as **Access Token**, and set **Value type** to **Groups**.
        1. Set **Filter** to **Matches regex** with the value `.*`, then click **Create**.

        **Create the groups and a test user**

        1. Go to **Directory > Groups** and create `warehouse-ops` and `customer-support`.
        1. Go to **Directory > People** and add a user, for example `mcp-test-user@example.com`, or pick an existing user who can sign in.
        1. Open the user, click the **Groups** tab, and add the user to `warehouse-ops`.
        1. Open the `MCP Client` application, click the **Assignments** tab, and assign the user. Without this assignment, Okta blocks the sign-in.

        **Export the Okta values**

        Export the `default` authorization server's issuer URL, its introspection endpoint, and the **Kong MCP Gateway** application's credentials:

        ```bash
        export OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export OAUTH_CLIENT_ID='your-kong-mcp-gateway-client-id'
        export OAUTH_CLIENT_SECRET='your-kong-mcp-gateway-client-secret'
        ```

        {% endnavtab %}
        {% navtab "Keycloak" %}

        You need a Keycloak realm with admin access, for example a realm named `mcp-demo`.

        **Create the Kong MCP Gateway client**

        This confidential client represents Kong. Only confidential clients can call Keycloak's introspection endpoint ([Keycloak: OIDC endpoints](https://www.keycloak.org/securing-apps/oidc-layers)).

        1. In the Keycloak Admin Console, click **Clients**, then **Create client**.
        1. Set **Client ID** to `kong-mcp-gateway` and click **Next**.
        1. Turn on **Client authentication**, then click **Save**.
        1. On the **Credentials** tab, copy the **Client Secret**.

        **Create the MCP Client**

        This public client represents Insomnia.

        1. Click **Clients**, then **Create client**.
        1. Set **Client ID** to `mcp-client` and click **Next**.
        1. Keep **Client authentication** off, keep **Standard flow** on, and set **PKCE Method** to **S256**. Without a PKCE method, Keycloak accepts the client's requests without PKCE ([Keycloak: Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html)).
        1. Set **Valid redirect URIs** to `https://app.insomnia.rest/oauth/redirect`, then click **Save**.

        **Add the audience and groups mappers**

        Keycloak's introspection endpoint answers only a client that is in the token's `aud` claim, and Keycloak doesn't add a `groups` claim by default. Add both to the tokens issued to `mcp-client`:

        1. Open the `mcp-client` client, click the **Client scopes** tab, and click `mcp-client-dedicated`.
        1. Click **Configure a new mapper** and select **Audience**. Set **Name** to `kong-mcp-gateway-audience`, set **Included Client Audience** to `kong-mcp-gateway`, keep **Add to access token** on, and click **Save**.
        1. Click **Add mapper > By configuration** and select **Group Membership**. Set **Name** and **Token Claim Name** to `groups`, turn off **Full group path**, keep **Add to access token** and **Add to token introspection** on, and click **Save**.

        **Create the groups and a test user**

        1. Click **Groups** and create `warehouse-ops` and `customer-support`.
        1. Click **Users** and add a user, for example `mcp-test-user`, or pick an existing one. On the **Credentials** tab, set a password and turn off **Temporary**.
        1. On the user's **Groups** tab, add the user to `warehouse-ops`.

        **Export the Keycloak values**

        Export the realm's issuer URL, its introspection endpoint, and the `kong-mcp-gateway` credentials:

        ```bash
        export OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export OAUTH_CLIENT_ID='kong-mcp-gateway'
        export OAUTH_CLIENT_SECRET='your-kong-mcp-gateway-client-secret'
        ```

        {% endnavtab %}
        {% endnavtabs %}
    - title: Insomnia
      content: |
        This tutorial uses [Insomnia](https://insomnia.rest/) as the MCP client. Insomnia connects to MCP servers and runs the OAuth flow that MCP servers advertise ([MCP clients in Insomnia](/insomnia/mcp-clients-in-insomnia/)).

        Install the latest version of Insomnia from [insomnia.rest/download](https://insomnia.rest/download).
overview: |
  Turn internal REST APIs into MCP tools behind one MCP endpoint in {{site.ai_gateway_name}}, so that users sign in with your identity provider and their team decides which tools they can call. You'll set up:

  * Eight MCP tools from three mock REST APIs (orders, inventory, customers), with no MCP server to run
  * One aggregated MCP endpoint that MCP clients discover and sign in to with OAuth 2.1
  * Tool ACLs that give the `warehouse-ops` and `customer-support` teams different tools

  For third-party MCP servers, for example GitHub, see the [Secure External MCP Gateway cookbook](/cookbooks/secure-external-mcp-gateway/).
---

## What this cookbook solves

Most teams expose internal APIs to AI agents through separate MCP servers, each with its own authentication and its own tool catalog, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each team runs and secures its own MCP server, so agents connect to many endpoints and each one has its own credentials."
    solution: "One `listener` AI MCP Server aggregates the tools of each team's `conversion-only` AI MCP Server behind `/ecommerce-mcp`."
  - problem: "Building an MCP server for each REST API takes code that someone has to maintain."
    solution: "A `conversion-only` AI MCP Server turns REST endpoints into MCP tools from configuration."
  - problem: "Each agent sees every tool, so a warehouse agent can call customer-data tools."
    solution: "Tool ACLs on each tool allow AI Consumer Groups that match IdP groups. Kong removes other tools from `tools/list` and rejects calls to them."
  - problem: "Offboarding a user means touching every MCP server they had access to."
    solution: "An OpenID Connect AI Auth Strategy validates each token with your IdP, so disabling the user or changing their group in the IdP takes effect at Kong."
{% endtable %}

## Try it out

Apply the configuration, connect Insomnia to the aggregated MCP endpoint, then compare the tools that each team gets.

### Apply the Kong configuration

The configuration creates three `conversion-only` [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) (orders, inventory, and customers) with eight tools, one `listener` AI MCP Server that aggregates them, an OpenID Connect AI Auth Strategy for your IdP, two AI Consumer Groups (`warehouse-ops` and `customer-support`), and a [CORS](/ai-gateway/policies/cors/) Policy. The tools call `https://httpbin.konghq.com/anything`, which echoes each request. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the URL that MCP clients use for the aggregated endpoint. Kong advertises it as the protected resource in its OAuth metadata:

```bash
export MCP_RESOURCE_URL='http://localhost:8000/ecommerce-mcp'
```

The IdP values come from the prerequisites. The same configuration works with Okta and Keycloak. Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: secure-internal-mcp-gateway-recipe

ai_gateway_auth_strategies:
- ref: secure-internal-mcp-gateway-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-internal-mcp-gateway-auth
  display_name: secure-internal-mcp-gateway OIDC auth
  type: openid-connect
  config:
    issuer: !env 'OAUTH_AUTH_SERVER'
    introspection_endpoint: !env 'OAUTH_INTROSPECTION_URL'
    client_id:
    - !env 'OAUTH_CLIENT_ID'
    client_secret:
    - !secret {source: !env 'OAUTH_CLIENT_SECRET'}
    auth_methods:
    - introspection
    cache_introspection: true
    scopes:
    - openid
    consumer_optional: true
    consumer_groups_claim:
    - groups
    consumer_groups_optional: false
    credential_claim:
    - sub
    cache_tokens_salt: secure-internal-mcp-gateway-oidc-cache
    ssl_verify: true
    hide_credentials: true

ai_gateway_consumer_groups:
- ref: warehouse-ops
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: warehouse-ops
  display_name: Warehouse Operations
- ref: customer-support
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: customer-support
  display_name: Customer Support

ai_gateway_mcp_servers:
- ref: orders-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: orders-mcp
  display_name: Orders API MCP tools
  type: conversion-only
  config:
    url: https://httpbin.konghq.com/anything
    route:
      paths:
      - /orders-api
    max_request_body_size: 1048576
    logging:
      payloads: true
  tools:
  - name: list-orders
    description: >-
      List recent orders with optional filters for status and date.
      Returns order summaries including order ID, status, and total.
    method: GET
    path: orders
    annotations:
      read_only_hint: true
      title: List orders
    access:
      acls:
        allow:
        - warehouse-ops
        - customer-support
    parameters:
    - name: status
      in: query
      required: false
      description: Filter by order status (pending, shipped, delivered, cancelled)
      schema:
        type: string
    - name: date
      in: query
      required: false
      description: Filter by order date (YYYY-MM-DD)
      schema:
        type: string
  - name: get-order
    description: >-
      Get full details for a specific order including line items,
      shipping address, and payment status.
    method: GET
    path: orders/{orderId}
    annotations:
      read_only_hint: true
      title: Get order details
    access:
      acls:
        allow:
        - warehouse-ops
        - customer-support
    parameters:
    - name: orderId
      in: path
      required: true
      description: The order ID
      schema:
        type: string
  - name: cancel-order
    description: >-
      Cancel a pending order. This action cannot be undone.
      Only customer support agents can perform cancellations.
    method: POST
    path: orders/{orderId}/cancel
    annotations:
      destructive_hint: true
      title: Cancel order
    access:
      acls:
        allow:
        - customer-support
    parameters:
    - name: orderId
      in: path
      required: true
      description: The order ID to cancel
      schema:
        type: string

- ref: inventory-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: inventory-mcp
  display_name: Inventory API MCP tools
  type: conversion-only
  config:
    url: https://httpbin.konghq.com/anything
    route:
      paths:
      - /inventory-api
    max_request_body_size: 1048576
    logging:
      payloads: true
  tools:
  - name: list-inventory
    description: >-
      List inventory items with optional filters for category
      or low stock alerts.
    method: GET
    path: inventory
    annotations:
      read_only_hint: true
      title: List inventory
    access:
      acls:
        allow:
        - warehouse-ops
        - customer-support
    parameters:
    - name: category
      in: query
      required: false
      description: Filter by product category
      schema:
        type: string
    - name: low_stock
      in: query
      required: false
      description: Set to true to show only items below restock threshold
      schema:
        type: string
  - name: check-inventory
    description: >-
      Check current stock level, reorder threshold, and product
      details for a specific SKU.
    method: GET
    path: inventory/{sku}
    annotations:
      read_only_hint: true
      title: Check inventory for SKU
    access:
      acls:
        allow:
        - warehouse-ops
        - customer-support
    parameters:
    - name: sku
      in: path
      required: true
      description: The product SKU
      schema:
        type: string
  - name: restock-item
    description: >-
      Add units to a product's inventory. Only warehouse
      operations staff can perform restocking.
    method: POST
    path: inventory/{sku}/restock
    annotations:
      destructive_hint: true
      title: Restock inventory item
    access:
      acls:
        allow:
        - warehouse-ops
    parameters:
    - name: sku
      in: path
      required: true
      description: The product SKU to restock
      schema:
        type: string
    - name: quantity
      in: query
      required: true
      description: Number of units to add to inventory
      schema:
        type: integer

- ref: customers-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: customers-mcp
  display_name: Customers API MCP tools
  type: conversion-only
  config:
    url: https://httpbin.konghq.com/anything
    route:
      paths:
      - /customers-api
    max_request_body_size: 1048576
    logging:
      payloads: true
  tools:
  - name: get-customer
    description: >-
      Retrieve customer profile including name, contact info,
      and account status. Only customer support can access
      customer data.
    method: GET
    path: customers/{customerId}
    annotations:
      read_only_hint: true
      title: Get customer details
    access:
      acls:
        allow:
        - customer-support
    parameters:
    - name: customerId
      in: path
      required: true
      description: The customer ID
      schema:
        type: string
  - name: update-customer-contact
    description: >-
      Update a customer's contact information. Only customer
      support agents can modify customer records.
    method: PUT
    path: customers/{customerId}/contact
    annotations:
      destructive_hint: true
      title: Update customer contact info
    access:
      acls:
        allow:
        - customer-support
    parameters:
    - name: customerId
      in: path
      required: true
      description: The customer ID to update
      schema:
        type: string
    - name: email
      in: query
      required: false
      description: New email address
      schema:
        type: string
    - name: phone
      in: query
      required: false
      description: New phone number
      schema:
        type: string

- ref: ecommerce-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ecommerce-mcp
  display_name: Aggregated Ecommerce MCP Server
  type: listener
  sources:
  - orders-mcp
  - inventory-mcp
  - customers-mcp
  access:
    acl_attribute_type: consumer
    auth_strategies:
    - secure-internal-mcp-gateway-auth
    metadata:
      resource: !env 'MCP_RESOURCE_URL'
      endpoint: /.well-known/oauth-protected-resource/ecommerce-mcp
  config:
    max_request_body_size: 1048576
    logging:
      payloads: true
      audits: true
    route:
      paths:
      - /ecommerce-mcp
      protocols:
      - http
      - https
    server:
      forward_client_headers: true
  policies:
  - secure-internal-mcp-gateway-cors

ai_gateway_policies:
- ref: secure-internal-mcp-gateway-cors
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-internal-mcp-gateway-cors
  display_name: secure-internal-mcp-gateway CORS
  type: cors
  config:
    origins:
    - '*'
    methods:
    - GET
    - HEAD
    - PUT
    - PATCH
    - POST
    - DELETE
    - OPTIONS
    credentials: false
    preflight_continue: false
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

### Connect Insomnia to Kong

Create an MCP client in Insomnia. When Kong rejects the first request, Insomnia reads Kong's protected resource metadata, finds your IdP, and runs the sign-in.

1. In Insomnia, click **MCP Clients** in the left pane, name the client `Ecommerce MCP`, and click **Create**.
1. In **MCP Server URL**, enter `http://localhost:8000/ecommerce-mcp`.
1. Click the **Auth** tab, select **OAuth 2.0**, set **Grant Type** to **MCP Auth Flow**, and enter the Client ID of the `MCP Client` application (Okta) or `mcp-client` (Keycloak). Leave **Client Secret** empty.
1. Click **Connect**. Kong answers with `401` and a link to its protected resource metadata. Insomnia opens your IdP in the browser.
1. Sign in as your test user. Insomnia connects with the IdP token. The **Events** tab shows each step of the OAuth flow.

### Call tools as warehouse-ops

The left pane lists the tools that Kong returns for the `warehouse-ops` group: `list-orders`, `get-order`, `list-inventory`, `check-inventory`, and `restock-item`. Kong removed `cancel-order`, `get-customer`, and `update-customer-contact`.

Call `check-inventory` with `sku` set to `WIDGET-42`. The response is httpbin's echo of the request, with the URL `https://httpbin.konghq.com/anything/inventory/WIDGET-42`.

If a client calls a tool that its AI Consumer Group can't use, for example `cancel-order`, Kong rejects the `tools/call` request with `403 Forbidden` before it reaches the API ([ACL evaluation logic](/ai-gateway/entities/ai-mcp-server/#acl-evaluation-logic)).

### Switch to customer-support

The `groups` claim decides the AI Consumer Group, so you change a user's tools in the IdP, not in Kong.

1. In your IdP, remove the test user from `warehouse-ops` and add the user to `customer-support`.
1. In Insomnia, disconnect, delete the access token on the **Auth** tab, and connect again. Sign in when the browser opens.

The tool list now has seven tools: each tool except `restock-item`.

### Check the results

The Insomnia sessions confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "OAuth discovery and sign-in"
    evidence: "Insomnia gets a `401` from Kong, then opens your IdP's sign-in page without any OAuth endpoint in its configuration."
  - behavior: "One endpoint for three APIs"
    evidence: "Tools from the orders, inventory, and customers AI MCP Servers appear in one tool list."
  - behavior: "REST-to-MCP conversion"
    evidence: "`check-inventory` returns httpbin's echo of `GET /anything/inventory/WIDGET-42`."
  - behavior: "Tool ACLs from IdP groups"
    evidence: "`warehouse-ops` gets five tools, and `customer-support` gets seven. Changing the IdP group changes the list after the next sign-in."
{% endtable %}

To review the created entities and the MCP traffic, open the `secure-internal-mcp-gateway-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

The MCP client connects to the `listener` AI MCP Server on `/ecommerce-mcp`. Kong validates the IdP token, maps the `groups` claim to an AI Consumer Group, filters the aggregated tool list with each tool's ACL, and converts each allowed tool call into an HTTP request to the team's API.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as Kong AI Gateway
    participant I as Identity Provider
    participant B as Backend APIs

    C->>K: MCP request, no token
    activate K
    K-->>C: 401 and protected resource metadata
    deactivate K
    C->>I: Authorization Code with PKCE
    activate I
    I-->>C: Access token
    deactivate I
    C->>K: tools/list with the IdP token
    activate K
    K->>I: Introspect the token (else 401)
    activate I
    I-->>K: Claims with sub and groups
    deactivate I
    K->>K: Map groups to an AI Consumer Group (else rejected)
    K-->>C: Tools that the group can call
    deactivate K
    C->>K: tools/call
    activate K
    K->>K: Tool ACL for the AI Consumer Group (else 403)
    K->>B: HTTP request for the tool
    activate B
    B-->>K: Response
    deactivate B
    K-->>C: Tool result
    deactivate K
{% endmermaid %}
<!-- vale on -->

### AI MCP Servers

Each team's API has a `conversion-only` AI MCP Server, which defines MCP tools from REST endpoints and their ACLs. A `conversion-only` AI MCP Server accepts no MCP traffic itself. The `listener` AI MCP Server lists them by `name` in `sources`, exposes all their tools on one route, and applies the ACL that travels with each tool. When a client calls a tool, the listener sends the HTTP request through the `conversion-only` AI MCP Server's route plus the tool's `path` ([Tool paths in conversion-only servers](/ai-gateway/entities/ai-mcp-server/#tool-paths-in-conversion-only-servers)).

The following settings configure the AI MCP Servers:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`type: conversion-only`"
    purpose: "Defines tools for aggregation. The orders, inventory, and customers AI MCP Servers use it."
  - setting: "`config.url`"
    purpose: "The API base URL. All three APIs use httpbin in this cookbook."
  - setting: "`config.route.paths` (`conversion-only`)"
    purpose: "The route that the listener sends tool calls through, for example `/inventory-api`. Without a route, the data plane can't compile the configuration."
  - setting: "`tools[].method`, `path`, and `parameters`"
    purpose: "The HTTP request that the tool sends, and the tool's input. The `path` has no leading `/`, so Kong adds it to the route. Path parameters such as `{sku}` fill the path."
  - setting: "`tools[].annotations`"
    purpose: "MCP hints for agents, for example `read_only_hint` and `destructive_hint`."
  - setting: "`tools[].access.acls.allow`"
    purpose: "The AI Consumer Groups that can call the tool. The ACL travels with the tool to the listener."
  - setting: "`type: listener` and `sources`"
    purpose: "Aggregates the tools of the three `conversion-only` AI MCP Servers on one route."
  - setting: "`access.auth_strategies`"
    purpose: "Each request needs a valid IdP token."
  - setting: "`access.acl_attribute_type: consumer`"
    purpose: "Kong evaluates the ACLs against the caller's AI Consumer Groups."
  - setting: "`access.metadata.resource` and `endpoint`"
    purpose: "Kong serves protected resource metadata for `MCP_RESOURCE_URL` at `/.well-known/oauth-protected-resource/ecommerce-mcp` and adds the path to the route. The authorization server and scopes come from the AI Auth Strategy's `issuer` and `scopes`."
  - setting: "`config.route.paths: [/ecommerce-mcp]` (`listener`)"
    purpose: "The endpoint that MCP clients call."
  - setting: "`config.server.forward_client_headers: true`"
    purpose: "Kong forwards the client's request headers to the APIs when it calls a tool. The OpenID Connect AI Auth Strategy already removed the IdP token."
  - setting: "`config.logging.payloads` and `audits: true`"
    purpose: "Kong logs MCP payloads and an audit entry for each ACL decision."
  - setting: "`config.max_request_body_size: 1048576`"
    purpose: "Limits request bodies to 1 MB, which is enough for these tool calls."
{% endtable %}

The tools have the following access:

{% table %}
columns:
  - title: Tool
    key: tool
  - title: warehouse-ops
    key: warehouse
  - title: customer-support
    key: support
rows:
  - tool: "`list-orders`, `get-order`, `list-inventory`, `check-inventory`"
    warehouse: "Allowed"
    support: "Allowed"
  - tool: "`restock-item`"
    warehouse: "Allowed"
    support: "Denied"
  - tool: "`cancel-order`, `get-customer`, `update-customer-contact`"
    warehouse: "Denied"
    support: "Allowed"
{% endtable %}

### OpenID Connect AI Auth Strategy and AI Consumer Groups

Authentication is an AI Auth Strategy, not an AI Policy. The OpenID Connect AI Auth Strategy validates each token with your IdP's introspection endpoint and maps the values in the `groups` claim to the AI Consumer Groups with the same names. The AI Consumer Groups have no members in Kong, because the IdP decides group membership. Because the listener sets `access.metadata`, {{site.ai_gateway}} adds the OAuth resource server behavior that MCP clients expect ([Protected resource metadata](/ai-gateway/entities/ai-mcp-server/#protected-resource-metadata)).

The following settings configure the OpenID Connect AI Auth Strategy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`issuer`"
    purpose: "Your IdP's authorization server, from `OAUTH_AUTH_SERVER`. The protected resource metadata advertises it."
  - setting: "`auth_methods: [introspection]`"
    purpose: "Kong validates the token with the introspection endpoint, so the IdP can issue opaque tokens."
  - setting: "`introspection_endpoint`, `client_id`, and `client_secret`"
    purpose: "The introspection endpoint and the Kong MCP Gateway client's credentials. `client_id` and `client_secret` are lists."
  - setting: "`cache_introspection: true`"
    purpose: "Kong caches introspection results, so it doesn't call the IdP for each request."
  - setting: "`scopes: [openid]`"
    purpose: "The scope that the protected resource metadata advertises, so the MCP client requests it."
  - setting: "`consumer_optional: true`"
    purpose: "Kong accepts the request without an AI Consumer. The AI Auth Strategy sets `consumer_groups_claim` and no `consumer_claims`: Konnect accepts only one of the two."
  - setting: "`consumer_groups_claim: [groups]`"
    purpose: "Kong maps each value in the `groups` claim to the AI Consumer Group with the same name."
  - setting: "`consumer_groups_optional: false`"
    purpose: "Kong rejects a user whose groups match no AI Consumer Group, so a user without a team can't connect."
  - setting: "`credential_claim: [sub]`"
    purpose: "Kong identifies a caller without an AI Consumer by the `sub` claim."
  - setting: "`cache_tokens_salt`"
    purpose: "A stable, non-secret value for the token cache keys."
  - setting: "`ssl_verify: true`"
    purpose: "Kong verifies the IdP's TLS certificate."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the IdP token before it calls the APIs."
{% endtable %}

The AI Auth Strategy has no `audience_required`, so Kong doesn't check the token's `aud` claim against `MCP_RESOURCE_URL`. Okta and Keycloak don't issue tokens for that audience by default. Group mapping works without an AI Consumer: the `groups` claim from introspection selects the AI Consumer Group, and the tool ACLs use it.

{:.info}
> **Production credentials:** This cookbook stores the IdP client secret in an environment variable for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference it from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### CORS Policy

The CORS Policy on the listener answers browser preflight requests, so MCP clients that run in a browser can call the endpoint. Insomnia doesn't need it.

The following settings configure the CORS Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`origins: ['*']`"
    purpose: "The value of the `Access-Control-Allow-Origin` header: any origin. In production, list your clients' origins."
  - setting: "`methods`"
    purpose: "The value of the `Access-Control-Allow-Methods` header."
  - setting: "`credentials: false`"
    purpose: "Kong doesn't send `Access-Control-Allow-Credentials: true`. MCP clients authenticate with the `Authorization` header, not cookies."
  - setting: "`preflight_continue: false`"
    purpose: "Kong answers `OPTIONS` preflight requests instead of proxying them to the APIs."
{% endtable %}

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Point the tools at real APIs"
    how: "Change `config.url` on each `conversion-only` AI MCP Server to the team's API, and adjust each tool's `path` and `parameters`."
  - variation: "Add another team's tools"
    how: "Add a `conversion-only` AI MCP Server with its tools and ACLs, and add its `name` to the listener's `sources`. The AI Auth Strategy and the AI Consumer Groups don't change."
  - variation: "Aggregate an existing MCP server"
    how: "Add an `upstream-server` AI MCP Server for the MCP server and add it to `sources`. See [Tool aggregation with upstream-server](/ai-gateway/entities/ai-mcp-server/#tool-aggregation-with-upstream-server)."
  - variation: "Set a default tool ACL"
    how: "Set `access.default_tool_acls` on the listener for tools that have no ACL of their own. A tool's own ACL replaces the default. See [ACL tool control](/ai-gateway/entities/ai-mcp-server/#acl-tool-control)."
  - variation: "Validate JWTs locally"
    how: "For an IdP without an introspection endpoint, set `auth_methods: [bearer]` and leave out `introspection_endpoint`. Kong validates the JWT with the IdP's signing keys. See [OIDC token authentication](/ai-gateway/entities/ai-auth-strategy/#oidc-token-authentication)."
  - variation: "Check the token audience"
    how: "If your IdP issues tokens for the MCP resource URL, set `audience_required` on the AI Auth Strategy to that URL."
  - variation: "Limit calls for each team"
    how: "Attach a [Rate Limiting Advanced](/ai-gateway/policies/rate-limiting-advanced/) Policy to the listener to limit requests for each AI Consumer or AI Consumer Group. See [Rate limiting](/ai-gateway/entities/ai-mcp-server/#rate-limiting)."
  - variation: "Connect another MCP client"
    how: "Add the client's OAuth redirect URL to your IdP's MCP client application. Token validation and the tool ACLs don't change."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

In Insomnia, delete the `Ecommerce MCP` MCP client. In your IdP, delete the two applications and the two groups that you created.
