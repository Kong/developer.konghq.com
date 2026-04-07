---
title: Configure token exchange with the AI MCP OAuth2 plugin and Okta
permalink: /mcp/configure-mcp-oauth2-token-exchange-with-okta/
content_type: how_to
description: Learn how to configure token exchange with the AI MCP OAuth2 plugin using Okta
breadcrumbs:
  - /mcp/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP OAuth2 plugin
    url: /plugins/ai-mcp-oauth2/
  - text: Token exchange in the AI MCP OAuth2 plugin
    url: /plugins/ai-mcp-oauth2/#token-exchange
  - text: AI MCP Proxy plugin
    url: /plugins/ai-mcp-proxy/
  - text: Secure MCP tools with OAuth2 and Okta
    url: /mcp/secure-mcp-tools-with-oauth2-and-okta/
  - text: OAuth 2.0 specification for MCP
    url: https://modelcontextprotocol.io/specification/draft/basic/authorization

plugins:
  - ai-mcp-oauth2
  - ai-mcp-proxy
  - cors

entities:
  - service
  - route
  - plugin

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

tools:
  - deck

prereqs:
  inline:
    - title: Upstream MCP server
      content: |
        This guide uses a sample MCP server that exposes marketplace tools (users and orders).

        1. Clone and start the server:

            ```sh
            git clone https://github.com/tomek-labuk/marketplace-acl.git && \
            cd marketplace-acl && \
            npm install && \
            npm run build && \
            node dist/server.js
            ```

        1. Verify the server is running at `http://localhost:3001/mcp`.
    - title: Okta
      content: |
        You need an [Okta](https://login.okta.com/) admin account with a developer organization.

        This setup creates two application registrations: a **Web Application** (used by {{site.ai_gateway}} for token introspection and token exchange) and a **Native Application** (used by MCP Inspector for the authorization code flow).

        #### Add a custom scope

        1. Go to **Security > API > Authorization Servers**.
        1. Click `default`.
        1. Go to the **Scopes** tab.
        1. Click **Add Scope**.
        1. Name: `mcp:access`
        1. Display phrase: `Access MCP tools`
        1. Check **Set as a default scope**.
        1. Click **Create**.

        #### Add an access policy

        1. In the same `default` authorization server, go to the **Access Policies** tab.
        1. Click **Add Policy**.
        1. Name: `MCP Access`
        1. Assign to: **All clients**
        1. Click **Create Policy**.

        #### Add a rule to the policy

        1. Inside the `MCP Access` policy, click **Add Rule**.
        1. Rule Name: `Allow MCP`
        1. Grant type: check **Client Credentials**, **Authorization Code**, and **Device Authorization**.
        1. User is: **Any user assigned the app**
        1. Scopes requested: **Any scopes**
        1. Click **Create Rule**.

        #### Export authorization server URLs

        1. Go to **Security > API > Authorization Servers**.
        1. Click the `default` server.
        1. Copy the **Issuer** URI (for example, `https://your-org.okta.com/oauth2/default`).
        1. Export the following environment variables:

            ```sh
            export DECK_OKTA_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
            export DECK_OKTA_INTROSPECTION_ENDPOINT='https://your-org.okta.com/oauth2/default/v1/introspect'
            export DECK_OKTA_TOKEN_ENDPOINT='https://your-org.okta.com/oauth2/default/v1/token'
            ```

        #### Create the web application

        This application is used by {{site.ai_gateway}} for token introspection and token exchange.

        1. Go to **Applications > Applications > Create App Integration**.
        1. Sign-in method: **OIDC - OpenID Connect**
        1. Application type: **Web Application**
        1. App integration name: `Kong MCP Gateway`
        1. Grant types: check **Client Credentials** and **Authorization Code**.
        1. Set Sign-in redirect URIs to `http://localhost/unused`. {{site.base_gateway}} does not use the redirect flow, but Okta requires the field.
        1. Assignments: **Skip group assignment for now**
        1. Click **Save**.
        1. Copy the **Client ID** and **Client Secret**.
        1. Go to the **Assignments** tab, click **Assign > Assign to People**, and assign your user.
        1. Export the credentials:

            ```sh
            export DECK_OKTA_CLIENT_ID='your-kong-web-app-client-id'
            export DECK_OKTA_CLIENT_SECRET='your-kong-web-app-client-secret'
            ```

        #### Create the native application

        This application is used by MCP Inspector for the authorization code flow.

        1. Go to **Applications > Applications > Create App Integration**.
        1. Sign-in method: **OIDC - OpenID Connect**
        1. Application type: **Native Application**
        1. App integration name: `MCP Inspector`
        1. Grant types: check **Authorization Code**.
        1. Sign-in redirect URIs: `http://localhost:6274/oauth/callback/debug`
        1. Go to the **Assignments** tab, click **Assign > Assign to People**, and assign your user.
        1. Click **Save**.
        1. Copy the **Client ID**. No secret is needed for this public client.

        {:.info}
        > The **Web Application** credentials go into the AI MCP OAuth2 Plugin config for token introspection and exchange. The **Native Application** Client ID is what you enter in MCP Inspector when connecting to the OAuth-protected MCP endpoint.
      icon_url: /assets/icons/okta.svg
    - title: MCP Inspector
      content: |
        This guide uses [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) to test the OAuth-protected MCP endpoint.

        1. Ensure you have Node.js and npm installed. If needed, download them from https://nodejs.org.
        1. Update `npx` to the latest version:
            ```sh
            npm install -g npx
            ```
        1. Install the Inspector:
            ```sh
            npm install -g @modelcontextprotocol/inspector
            ```
      icon_url: /assets/icons/mcp.svg
  entities:
    services:
      - mcp-okta-token-exchange-service
    routes:
      - mcp-okta-token-exchange

tags:
  - ai
  - mcp
  - oauth2
  - okta
  - authentication
  - security

tldr:
  q: How do I configure token exchange with the AI MCP OAuth2 plugin and Okta?
  a: |
    Configure the AI MCP Proxy plugin in passthrough-listener mode to proxy MCP traffic
    to an upstream MCP server. Add the AI MCP OAuth2 plugin with token exchange enabled
    and Okta as the authorization server. The plugin validates the incoming token,
    exchanges it for a new token scoped to the target audience, and forwards the
    exchanged token to the upstream.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Configure the AI MCP Proxy plugin in passthrough-listener mode

Configure the [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) in `passthrough-listener` mode. This mode proxies incoming MCP requests directly to the upstream MCP server (the marketplace service running on port 3001) while generating observability metrics for the traffic.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: mcp-okta-token-exchange
      config:
        mode: passthrough-listener
        max_request_body_size: 1048576
{% endentity_examples %}

## Configure the CORS plugin

Add the [CORS plugin](/plugins/cors/) to the Route so that MCP Inspector's browser-based OAuth callback can reach the MCP endpoint.

{% entity_examples %}
entities:
  plugins:
    - name: cors
      route: mcp-okta-token-exchange
      config:
        origins:
          - http://localhost:6274
{% endentity_examples %}

## Configure the AI MCP OAuth2 plugin with token exchange

Configure the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) on the same Route. The plugin validates the incoming bearer token via introspection, then exchanges it for a new token at the Okta token endpoint before forwarding the request to the upstream MCP server.

Token exchange requires `passthrough_credentials` set to `true` so that the exchanged token is forwarded to the upstream.

{:.info}
> This example sets `insecure_relaxed_audience_validation` to `true` because Okta does not yet include the resource URL in the `aud` claim as defined in [RFC 8707](https://datatracker.ietf.org/doc/html/rfc8707).

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-oauth2
      route: mcp-okta-token-exchange
      config:
        resource: http://localhost:8000/mcp/okta
        metadata_endpoint: /.well-known/oauth-protected-resource/mcp/okta
        authorization_servers:
          - ${okta_auth_server}
        introspection_endpoint: ${okta_introspection_endpoint}
        client_id: ${okta_client_id}
        client_secret: ${okta_client_secret}
        insecure_relaxed_audience_validation: true
        passthrough_credentials: true
        claim_to_header:
          - claim: sub
            header: X-User-Id
        token_exchange:
          enabled: true
          token_endpoint: ${okta_token_endpoint}
          client_auth: client_secret_post
          request:
            audience:
              - api://mcp-upstream
variables:
  okta_auth_server:
    value: $OKTA_AUTH_SERVER
  okta_introspection_endpoint:
    value: $OKTA_INTROSPECTION_ENDPOINT
  okta_token_endpoint:
    value: $OKTA_TOKEN_ENDPOINT
  okta_client_id:
    value: $OKTA_CLIENT_ID
  okta_client_secret:
    value: $OKTA_CLIENT_SECRET
{% endentity_examples %}

Configuration breakdown:
* `resource`: The identifier for the protected MCP server. Matches the URL that MCP clients use to access it.
* `metadata_endpoint`: The path where the plugin serves OAuth Protected Resource Metadata. Must match one of the paths on the Route so MCP clients can discover the authorization server.
* `authorization_servers` and `introspection_endpoint`: Connect the plugin to Okta for token validation.
* `client_id`, `client_secret`, and `client_auth`: Credentials that {{site.base_gateway}} uses to authenticate with the introspection and token exchange endpoints.
* `passthrough_credentials`: Required for token exchange. Forwards the exchanged token to the upstream MCP server.
* `claim_to_header`: Maps the `sub` claim from the validated token to the `X-User-Id` upstream header.
* `token_exchange.enabled`: Activates token exchange after successful token validation.
* `token_exchange.token_endpoint`: The Okta token endpoint where the exchange request is sent.
* `token_exchange.client_auth: client_secret_post`: Authenticates with Okta using the client credentials in the POST body.
* `token_exchange.request.audience`: The target audience for the exchanged token. Set this to the identifier of the upstream service that will consume the token.

## Connect with MCP Inspector

1. Start MCP Inspector:

    ```sh
    npx @modelcontextprotocol/inspector@latest --mcp-url http://localhost:8000/mcp/okta
    ```

1. Open the MCP Inspector UI in your browser at the URL shown in the terminal output.

1. Set **Transport Type** to **Streamable HTTP**.

1. Set the URL to `http://localhost:8000/mcp/okta`.

1. Click **Open Auth Settings**.

1. Enter the **Native Application** Client ID from the Okta setup (the `MCP Inspector` app, not the `Kong MCP Gateway` app). Leave **Client Secret** empty.

    {:.info}
    > Use the Client ID from the **Native Application** (`MCP Inspector`) you created in Okta. Do not use the Web Application Client ID. The Web Application credentials are used by {{site.base_gateway}} for token introspection and exchange, not by MCP clients.

1. Click **Guided OAuth Flow**.

1. **Metadata Discovery**: click **Continue**.

1. **Client Registration**: click **Continue**.

1. **Preparing Authorization**: click the authorization link. A new browser tab opens with the Okta login page. Sign in with your Okta user credentials. Copy the authorization code from the browser.

1. **Request Authorization and acquire authorization code**: paste the authorization code and click **Continue**.

1. **Token Request**: click **Continue**.

1. **Authentication Complete** shows a green checkmark.

1. Click **Connect**. MCP Inspector connects to the OAuth-protected MCP endpoint.

## Validate

### Verify unauthenticated requests are rejected

Send a request without a token:

```sh
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/mcp/okta \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

The response returns `401`, confirming the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) is enforcing authentication.

### Verify MCP tools via MCP Inspector

1. In MCP Inspector, go to the **Tools** tab and click **List Tools**. You should see the marketplace tools exposed by the upstream MCP server:

    ```text
    list_users
    get_user
    list_orders
    list_orders_for_user
    search_orders
    ```
    {:.no-copy-code}

1. Select the **list_users** tool and click **Run Tool**. A successful response with marketplace user data confirms that {{site.base_gateway}} validated the original token, exchanged it at the Okta token endpoint, and forwarded the exchanged token to the upstream MCP server.
