---
title: Configure token exchange with the AI MCP OAuth2 plugin
permalink: /mcp/configure-mcp-oauth2-token-exchange/
content_type: how_to
description: Configure token exchange with the AI MCP OAuth2 plugin using Keycloak and an upstream MCP server
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
  - text: OAuth 2.0 specification for MCP
    url: https://modelcontextprotocol.io/specification/draft/basic/authorization

plugins:
  - ai-mcp-oauth2
  - ai-mcp-proxy

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
    - title: WeatherAPI
      include_content: prereqs/weatherapi
      icon_url: /assets/icons/gateway.svg
    - title: Set up isolated Keycloak token exchange
      include_content: prereqs/auth/mcp-oauth2/keycloak-token-exchange-weather
      icon_url: /assets/icons/keycloak.svg
    - title: Upstream MCP server
      content: |
        This guide uses a small MCP debug server that rejects the original client token and only accepts the exchanged token forwarded by {{site.ai_gateway}}. This makes the token exchange observable during validation.

        Create the server:

        ```sh
        cat > token-exchange-mcp-server.py <<'EOF'
        #!/usr/bin/env python3
        import base64
        import json
        import os
        from http.server import BaseHTTPRequestHandler, HTTPServer


        HOST = os.environ.get("TOKEN_EXCHANGE_MCP_HOST", "0.0.0.0")
        PORT = int(os.environ.get("TOKEN_EXCHANGE_MCP_PORT", "3002"))
        EXPECTED_AZP = os.environ.get("TOKEN_EXCHANGE_EXPECTED_AZP", "token-exchange-gateway")

        USERS = [
            {"id": "a1b2c3d4", "fullName": "Alice Johnson"},
            {"id": "e5f6g7h8", "fullName": "Bob Smith"},
        ]


        def _json_response(handler, status, payload):
            body = json.dumps(payload).encode("utf-8")
            handler.send_response(status)
            handler.send_header("Content-Type", "application/json")
            handler.send_header("Content-Length", str(len(body)))
            handler.end_headers()
            handler.wfile.write(body)


        def _decode_jwt_payload(token):
            parts = token.split(".")
            if len(parts) != 3:
                raise ValueError("invalid JWT format")

            payload = parts[1]
            payload += "=" * (-len(payload) % 4)
            decoded = base64.urlsafe_b64decode(payload.encode("ascii"))
            return json.loads(decoded.decode("utf-8"))


        def _extract_claims(handler):
            authorization = handler.headers.get("Authorization", "")
            if not authorization.startswith("Bearer "):
                raise PermissionError("missing bearer token")

            token = authorization.split(" ", 1)[1].strip()
            claims = _decode_jwt_payload(token)
            if claims.get("azp") != EXPECTED_AZP:
                raise PermissionError(
                    f"unexpected azp '{claims.get('azp')}', expected '{EXPECTED_AZP}'"
                )
            return claims


        def _mcp_result(request_id, structured_content):
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "content": [{"type": "text", "text": json.dumps(structured_content, indent=2)}],
                    "structuredContent": structured_content,
                },
            }


        class Handler(BaseHTTPRequestHandler):
            server_version = "token-exchange-mcp/1.0"

            def do_POST(self):
                if self.path != "/mcp":
                    _json_response(self, 404, {"error": "not found"})
                    return

                length = int(self.headers.get("Content-Length", "0"))
                raw_body = self.rfile.read(length)

                try:
                    claims = _extract_claims(self)
                    request = json.loads(raw_body.decode("utf-8"))
                except PermissionError as exc:
                    _json_response(self, 403, {"error": str(exc)})
                    return
                except Exception as exc:
                    _json_response(self, 400, {"error": str(exc)})
                    return

                method = request.get("method")
                request_id = request.get("id")
                params = request.get("params") or {}

                if method == "tools/list":
                    _json_response(
                        self,
                        200,
                        {
                            "jsonrpc": "2.0",
                            "id": request_id,
                            "result": {
                                "tools": [
                                    {
                                        "name": "list_users",
                                        "description": "List sample users.",
                                        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
                                    },
                                    {
                                        "name": "show_auth_context",
                                        "description": "Return selected claims from the upstream bearer token.",
                                        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
                                    },
                                ]
                            },
                        },
                    )
                    return

                if method == "tools/call":
                    tool_name = params.get("name")
                    if tool_name == "list_users":
                        _json_response(self, 200, _mcp_result(request_id, {"users": USERS}))
                        return
                    if tool_name == "show_auth_context":
                        aud = claims.get("aud")
                        if isinstance(aud, str):
                            aud = [aud]
                        _json_response(
                            self,
                            200,
                            _mcp_result(
                                request_id,
                                {
                                    "iss": claims.get("iss"),
                                    "azp": claims.get("azp"),
                                    "aud": aud or [],
                                    "sub": claims.get("sub"),
                                },
                            ),
                        )
                        return

                    _json_response(
                        self,
                        200,
                        {
                            "jsonrpc": "2.0",
                            "id": request_id,
                            "error": {"code": -32601, "message": f"unknown tool '{tool_name}'"},
                        },
                    )
                    return

                _json_response(
                    self,
                    200,
                    {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": {"code": -32601, "message": f"unsupported method '{method}'"},
                    },
                )

            def log_message(self, format, *args):
                return


        if __name__ == "__main__":
            httpd = HTTPServer((HOST, PORT), Handler)
            print(f"Token-exchange MCP server listening at http://{HOST}:{PORT}/mcp")
            httpd.serve_forever()
        EOF
        ```

        Start the server in a separate terminal:

        ```sh
        python3 token-exchange-mcp-server.py
        ```

        Verify the server is running at `http://localhost:3002/mcp`.
  entities:
    services:
      - mcp-token-exchange-isolated-service
    routes:
      - mcp-token-exchange-isolated

tags:
  - ai
  - mcp
  - oauth2
  - authentication

tldr:
  q: How do I configure token exchange with the AI MCP OAuth2 plugin?
  a: |
    Configure the AI MCP Proxy plugin in passthrough-listener mode on a dedicated MCP route.
    Add the AI MCP OAuth2 plugin with token exchange enabled. This setup uses separate
    routes, resource metadata, and Keycloak clients so it can coexist with a JWK-based
    MCP configuration while still validating a real token-exchange flow.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.ai_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Configure the AI MCP Proxy plugin in passthrough-listener mode

Configure the [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) in `passthrough-listener` mode on the `mcp-token-exchange-isolated` Route. This mode proxies incoming MCP requests directly to the upstream MCP server while preserving the exchanged bearer token on the upstream request.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: mcp-token-exchange-isolated
      tags:
        - token-exchange
      config:
        mode: passthrough-listener
        max_request_body_size: 1048576
{% endentity_examples %}

## Configure the AI MCP OAuth2 plugin with token exchange

Configure the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) on the same `mcp-token-exchange-isolated` Route. The plugin validates the incoming bearer token via introspection, then exchanges it for a new token at the Keycloak token endpoint before forwarding the request to the upstream MCP server.

Token exchange requires `passthrough_credentials` set to `true` so that the exchanged token is forwarded to the upstream.

{:.info}
> This example sets `insecure_relaxed_audience_validation` to `true` because the exchanged-token flow in this guide relies on a dedicated Keycloak audience mapper for the gateway client, not on the MCP resource URL being present in the incoming token's `aud` claim.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-oauth2
      route: mcp-token-exchange-isolated
      tags:
        - token-exchange
      config:
        resource: http://localhost:8000/mcp-exchange
        metadata_endpoint: /.well-known/oauth-protected-resource/mcp-exchange
        authorization_servers:
          - ${keycloak_issuer}
        introspection_endpoint: ${keycloak_introspection_url}
        client_id: ${token_exchange_gateway_client_id}
        client_secret: ${token_exchange_gateway_client_secret}
        client_auth: client_secret_post
        insecure_relaxed_audience_validation: true
        passthrough_credentials: true
        claim_to_header:
          - claim: sub
            header: X-User-Id
        token_exchange:
          enabled: true
          token_endpoint: ${keycloak_token_url}
          client_auth: inherit
variables:
  keycloak_issuer:
    value: $TOKEN_EXCHANGE_KEYCLOAK_ISSUER
  keycloak_introspection_url:
    value: $TOKEN_EXCHANGE_KEYCLOAK_INTROSPECTION_URL
  keycloak_token_url:
    value: $TOKEN_EXCHANGE_KEYCLOAK_TOKEN_URL
  token_exchange_gateway_client_id:
    value: $TOKEN_EXCHANGE_GATEWAY_CLIENT_ID
  token_exchange_gateway_client_secret:
    value: $TOKEN_EXCHANGE_GATEWAY_CLIENT_SECRET
{% endentity_examples %}

With this configuration, {{site.ai_gateway}} first validates the incoming bearer token against the dedicated Keycloak realm using introspection, then exchanges that token at the Keycloak token endpoint before proxying the MCP request upstream. `passthrough_credentials: true` ensures the upstream server receives the exchanged token instead of the original client token. The dedicated `resource` and `metadata_endpoint` keep this flow isolated from the JWK-based setup while still exposing OAuth Protected Resource Metadata for MCP clients.

## Validate the flow

### Verify unauthenticated requests are rejected

Send a request without a token:

<!--vale off-->
{% validation request-check %}
url: /mcp-exchange
status_code: 401
method: POST
headers:
  - 'Content-Type: application/json'
body:
  jsonrpc: "2.0"
  method: tools/list
  id: 1
  params: {}
{% endvalidation %}
<!--vale on-->

The response returns `401`, confirming the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) is enforcing authentication.

### Obtain a token from Keycloak

Obtain a token from Keycloak as `token-exchange-client`, including the `add-token-exchange-gateway-audience` optional scope so that `token-exchange-gateway` is added to the audience:

```sh
TOKEN_EXCHANGE_TOKEN=$(curl -s -X POST \
  http://$KEYCLOAK_HOST:8080/realms/token-exchange/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=$DECK_TOKEN_EXCHANGE_CLIENT_ID" \
  -d "client_secret=$DECK_TOKEN_EXCHANGE_CLIENT_SECRET" \
  -d "username=alex" \
  -d "password=doe" \
  -d "scope=openid profile add-token-exchange-gateway-audience" | jq -r .access_token) && echo $TOKEN_EXCHANGE_TOKEN
```

If you decode the token, the resulting access token will have an `aud` claim containing `token-exchange-gateway`, and an `azp` claim with `token-exchange-client`.

### Verify authenticated MCP requests succeed

Send the token to {{site.ai_gateway}} and list the available MCP tools:

<!--vale off-->
{% validation request-check %}
url: /mcp-exchange
status_code: 200
method: POST
headers:
  - 'Accept: application/json, text/event-stream'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $TOKEN_EXCHANGE_TOKEN'
body:
  jsonrpc: "2.0"
  method: tools/list
  id: 1
  params: {}
{% endvalidation %}
<!--vale on-->

A successful response returns the tools exposed by the upstream MCP server.

Call the upstream directly with the original token. The request fails because the upstream only accepts tokens whose `azp` claim is `token-exchange-gateway`:

```sh
curl -i --no-progress-meter http://localhost:3002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_EXCHANGE_TOKEN" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
```

The response returns `403`, proving the original token is not accepted by the upstream MCP server.

Call a tool through {{site.ai_gateway}} to verify the full request chain, including token exchange:

<!--vale off-->
{% validation request-check %}
url: /mcp-exchange
status_code: 200
method: POST
headers:
  - 'Accept: application/json, text/event-stream'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $TOKEN_EXCHANGE_TOKEN'
body:
  jsonrpc: "2.0"
  method: tools/call
  id: 2
  params:
    name: show_auth_context
    arguments: {}
{% endvalidation %}
<!--vale on-->

A successful response confirms that {{site.ai_gateway}} validated the original token, exchanged it at the Keycloak token endpoint, and forwarded the exchanged token to the upstream MCP server. The upstream accepts the request only because it receives a token whose `azp` claim is `token-exchange-gateway`:

```json
{"jsonrpc": "2.0", "id": 2, "result": {"content": [{"type": "text", "text": "{\n  \"iss\": \"http://localhost:8080/realms/token-exchange\",\n  \"azp\": \"token-exchange-gateway\",\n  \"aud\": [\n    \"account\"\n  ],\n  \"sub\": \"3f61670f-5e6b-4344-a5a0-a41fd48f3e39\"\n}"}], "structuredContent": {"iss": "http://localhost:8080/realms/token-exchange", "azp": "token-exchange-gateway", "aud": ["account"], "sub": "3f61670f-5e6b-4344-a5a0-a41fd48f3e39"}}}
```
{:.no-copy-code}
