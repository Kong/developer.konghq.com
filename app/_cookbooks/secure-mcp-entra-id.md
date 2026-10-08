---
title: Secure MCP with Microsoft Entra ID
description: Protect Kong-converted MCP servers with Microsoft Entra ID using JWKS validation. Interactive clients request the delegated mcp.tools scope. Client credentials with /.default are for automated tests only.
url: "/cookbooks/secure-mcp-entra-id/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
  ai-gateway: '2.0'
categories:
  - mcp
  - access-control
featured: false
popular: false

plugins:
  - openid-connect
  - ai-mcp-server
  - cors
  - post-function
requires_embeddings: false
extra_services:
  - name: Microsoft Entra ID
    env_vars: [DECK_ENTRA_ISSUER, DECK_ENTRA_JWKS_ENDPOINT, DECK_ENTRA_SCOPE, DECK_MCP_RESOURCE, DECK_MCP_RESOURCE_B, DECK_DIFY_ORIGIN]
    hint: "Create one Entra app registration that is both the MCP OAuth client and the resource. Advertise the delegated mcp.tools scope, not /.default."

hint: "Requires a Microsoft Entra tenant, an app registration (portal or Terraform), and optionally Dify to exercise the Entra login popup."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped AI Gateway and local Data Plane.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped AI Gateway name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='secure-mcp-entra-id-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an AI Gateway named `secure-mcp-entra-id-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Microsoft Entra ID
      content: |
        Create **one** Entra app registration. It is both the MCP OAuth client and the Kong MCP resource. Do not register a new app per MCP path.

        Entra has no [RFC 7662 token introspection](https://datatracker.ietf.org/doc/html/rfc7662) URL. The [openid-connect](/ai-gateway/policies/openid-connect/) AI Auth Strategy checks access tokens with JWKS instead.

        `api://{client_id}/mcp.tools` and `api://{client_id}/.default` are Entra **scope** values on the v2 token request. They are not Kong MCP paths.

        | Scope | Grant | Token identity | Use |
        | --- | --- | --- | --- |
        | `api://{client_id}/mcp.tools` | Authorization code | User (`scp`, `oid` is the person) | Interactive MCP clients |
        | `api://{client_id}/.default` | Client credentials | App (`roles`, `oid` is the service principal) | Automated JWKS smoke tests only |

        Set the MCP resource URLs and the browser client origin once. Both setup tabs reuse them:

        ```bash
        export DECK_MCP_RESOURCE='http://localhost:8000/orders-mcp'
        export DECK_MCP_RESOURCE_B='http://localhost:8000/inventory-mcp'
        export DECK_DIFY_ORIGIN='http://localhost:8088'
        ```

        {% navtabs "Entra setup" %}
        {% tab Portal %}

        Follow Microsoft's [app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) and [Expose an API](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis) guides. The table below is the MCP-specific subset.

        1. In the [Microsoft Entra admin center](https://entra.microsoft.com), register an application. Supported account types: **Accounts in this organizational directory only**. Platform: **Web**.
        1. Add a Web redirect URI that matches the MCP client callback exactly. This recipe uses `{CONSOLE_API_URL}/console/api/mcp/oauth/callback` (`http://localhost:8088/console/api/mcp/oauth/callback`).
        1. Create a client secret (**Certificates & secrets**). Store it as `ENTRA_CLIENT_SECRET`.
        1. **Expose an API**: set Application ID URI to `api://{Application (client) ID}`. Add a delegated scope named `mcp.tools` (Admins and users). The full scope string is `api://{client_id}/mcp.tools`.
        1. Open the [app manifest](https://learn.microsoft.com/en-us/entra/identity-platform/reference-app-manifest) and set `requestedAccessTokenVersion` to `2` so access tokens use `iss` `https://login.microsoftonline.com/{tenant}/v2.0`.
        1. **API permissions**: add this app's own `mcp.tools` delegated permission. Grant admin consent for `mcp.tools` and `offline_access`.
        1. Optional, smoke tests only: create an Application app role `MCP.Access` and assign this app to itself. Client credentials then receive that role when the scope is `api://{client_id}/.default`.
        1. Do not enable Dynamic Client Registration. Entra app registrations are created by an administrator, not by RFC 7591.

        Export Kong and client values. `DECK_ENTRA_SCOPE` is the delegated scope Kong advertises in Protected Resource Metadata (PRM). `ENTRA_CC_SCOPE` is for `demo.py` only:

        ```bash
        export ENTRA_TENANT_ID='YOUR_TENANT_ID'
        export ENTRA_CLIENT_ID='YOUR_CLIENT_ID'
        export ENTRA_CLIENT_SECRET='YOUR_CLIENT_SECRET'
        export DECK_ENTRA_ISSUER="https://login.microsoftonline.com/${ENTRA_TENANT_ID}/v2.0"
        export DECK_ENTRA_JWKS_ENDPOINT="https://login.microsoftonline.com/${ENTRA_TENANT_ID}/discovery/v2.0/keys"
        export DECK_ENTRA_SCOPE="api://${ENTRA_CLIENT_ID}/mcp.tools"
        export ENTRA_CC_SCOPE="api://${ENTRA_CLIENT_ID}/.default"
        ```

        {% endtab %}
        {% tab Terraform %}

        Install [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or later and authenticate with Azure (`az login` or an Entra service principal that can create app registrations). Save the following as `main.tf` in an empty directory, add `tenant_id` in `terraform.tfvars`, then `terraform init` and `terraform apply`.

        `mcp_scope` (`api://{client_id}/mcp.tools`) is what interactive MCP clients and Kong PRM use. `mcp_cc_scope` (`api://{client_id}/.default`) is what `demo.py` uses. Microsoft Graph `openid`, `profile`, and `email` are optional ID-token claims. They do not grant MCP access.

        ```hcl
        terraform {
          required_version = ">= 1.5.0"
          required_providers {
            azuread = {
              source  = "hashicorp/azuread"
              version = "~> 3.0"
            }
            random = {
              source  = "hashicorp/random"
              version = "~> 3.6"
            }
          }
        }

        provider "azuread" {
          tenant_id = var.tenant_id
        }

        variable "tenant_id" { type = string }
        variable "display_name" {
          type    = string
          default = "kong-mcp-entra"
        }
        variable "redirect_uris" {
          type = list(string)
          default = [
            "http://localhost:8088/console/api/mcp/oauth/callback",
            "http://127.0.0.1:8088/console/api/mcp/oauth/callback",
          ]
        }
        variable "secret_validity_hours" {
          type    = number
          default = 8760
        }

        resource "random_uuid" "mcp_app_role" {}
        resource "random_uuid" "mcp_scope" {}

        resource "azuread_application" "mcp" {
          display_name     = var.display_name
          sign_in_audience = "AzureADMyOrg"

          api {
            requested_access_token_version = 2
            oauth2_permission_scope {
              admin_consent_description  = "Allow the application to access MCP tools on behalf of the signed-in user."
              admin_consent_display_name = "Access MCP tools"
              enabled                    = true
              id                         = random_uuid.mcp_scope.result
              type                       = "User"
              value                      = "mcp.tools"
              user_consent_description   = "Allow access to MCP tools."
              user_consent_display_name  = "Access MCP tools"
            }
          }

          app_role {
            allowed_member_types = ["Application"]
            description          = "Application access to MCP tools (client credentials)."
            display_name         = "MCP.Access"
            enabled              = true
            id                   = random_uuid.mcp_app_role.result
            value                = "MCP.Access"
          }

          web {
            redirect_uris = var.redirect_uris
            implicit_grant {
              access_token_issuance_enabled = false
              id_token_issuance_enabled     = true
            }
          }

          optional_claims {
            access_token {
              name                  = "email"
              essential             = false
              additional_properties = []
            }
            id_token {
              name                  = "email"
              essential             = false
              additional_properties = []
            }
          }

          required_resource_access {
            resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
            resource_access {
              id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
              type = "Scope"
            }
            resource_access {
              id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
              type = "Scope"
            }
            resource_access {
              id   = "64a6cdd6-aab1-4aaf-94ca-8d45bf1763fa" # email
              type = "Scope"
            }
          }
        }

        resource "azuread_application_identifier_uri" "mcp" {
          application_id = azuread_application.mcp.id
          identifier_uri = "api://${azuread_application.mcp.client_id}"
        }

        resource "azuread_application_password" "mcp" {
          application_id = azuread_application.mcp.id
          display_name   = "kong-mcp-entra-secret"
          end_date       = timeadd(timestamp(), "${var.secret_validity_hours}h")
        }

        resource "azuread_service_principal" "mcp" {
          client_id = azuread_application.mcp.client_id
        }

        resource "azuread_app_role_assignment" "self_mcp" {
          app_role_id         = random_uuid.mcp_app_role.result
          principal_object_id = azuread_service_principal.mcp.object_id
          resource_object_id  = azuread_service_principal.mcp.object_id
        }

        resource "azuread_application_api_access" "self_mcp_tools" {
          application_id = azuread_application.mcp.id
          api_client_id  = azuread_application.mcp.client_id
          scope_ids      = [random_uuid.mcp_scope.result]
        }

        resource "azuread_service_principal_delegated_permission_grant" "self_mcp_tools" {
          service_principal_object_id          = azuread_service_principal.mcp.object_id
          resource_service_principal_object_id = azuread_service_principal.mcp.object_id
          claim_values                         = ["mcp.tools", "offline_access"]
          depends_on                           = [azuread_application_api_access.self_mcp_tools]
        }

        output "tenant_id" { value = var.tenant_id }
        output "client_id" { value = azuread_application.mcp.client_id }
        output "client_secret" {
          value     = azuread_application_password.mcp.value
          sensitive = true
        }
        output "issuer" {
          value = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
        }
        output "jwks_endpoint" {
          value = "https://login.microsoftonline.com/${var.tenant_id}/discovery/v2.0/keys"
        }
        output "mcp_scope" {
          value = "api://${azuread_application.mcp.client_id}/mcp.tools"
        }
        output "mcp_cc_scope" {
          value = "api://${azuread_application.mcp.client_id}/.default"
        }
        ```
        {:.collapsible}

        Map each resource to the Entra field it sets:

        | Terraform resource | Entra field |
        | --- | --- |
        | `azuread_application.api.requested_access_token_version = 2` | v2 access tokens (`iss` ends with `/v2.0`) |
        | `oauth2_permission_scope.value = mcp.tools` | Delegated scope (must not collide with an app role name) |
        | `azuread_application_identifier_uri` | Application ID URI `api://{client_id}` |
        | `azuread_application_api_access` + delegated permission grant | Same app requests `mcp.tools`; admin consent includes `offline_access` |
        | `web.redirect_uris` | MCP client callback, exact match |
        | `azuread_application_password` | Confidential client secret |
        | `app_role` `MCP.Access` + self assignment | Client credentials / `/.default` for `demo.py` only |
        | Graph `openid` / `profile` / `email` | Optional ID-token claims. Not MCP access. |

        Create `terraform.tfvars` with your tenant ID, apply, then export:

        ```bash
        export ENTRA_TENANT_ID="$(terraform output -raw tenant_id)"
        export ENTRA_CLIENT_ID="$(terraform output -raw client_id)"
        export ENTRA_CLIENT_SECRET="$(terraform output -raw client_secret)"
        export DECK_ENTRA_ISSUER="$(terraform output -raw issuer)"
        export DECK_ENTRA_JWKS_ENDPOINT="$(terraform output -raw jwks_endpoint)"
        export DECK_ENTRA_SCOPE="$(terraform output -raw mcp_scope)"
        export ENTRA_CC_SCOPE="$(terraform output -raw mcp_cc_scope)"
        ```

        {% endtab %}
        {% endnavtabs %}
    - title: Dify (optional)
      content: |
        [Dify](https://docs.dify.ai/en/use-dify/build/mcp) is one MCP client used in Try it out. Any client that registers a remote HTTP MCP server, runs OAuth, and imports tools can follow the same Entra path. This recipe was tested with Dify Community **1.11**, **1.12**, and **1.13**.

        1. Run self-hosted Dify so the console is at `http://localhost:8088` (or set `DECK_DIFY_ORIGIN` to that origin).
        1. From the MCP client, Kong is `http://gateway.example.com:8000`, not `http://localhost:8000`. Point `gateway.example.com` at the data plane (for example in `/etc/hosts`).
        1. Register the Entra redirect URI to Dify's callback: `{CONSOLE_API_URL}/console/api/mcp/oauth/callback`.
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'httpx>=0.27.0'
        ```
overview: |
  Remote MCP over HTTP uses OAuth 2.1. The client gets a `401`, reads [Protected Resource Metadata](https://datatracker.ietf.org/doc/html/rfc9728), signs the user in at the authorization server, then retries with a Bearer token. See the MCP [Authorization](https://modelcontextprotocol.io/specification/draft/basic/authorization) specification and the [authorization tutorial](https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/authorization).

  {{site.ai_gateway_name}} is that resource server. Attach an [openid-connect](/ai-gateway/policies/openid-connect/) AI Auth Strategy and `access.metadata` on each [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) (`conversion-listener`): Kong serves PRM, returns the `401` challenge, checks Entra JWTs with JWKS, and turns REST APIs into MCP tools. You do not build that handshake in application code.

  Entra issues the tokens. This recipe uses two example MCP paths, `/orders-mcp` and `/inventory-mcp`, on one Entra app. Interactive clients request `mcp.tools`. `demo.py` uses `/.default` only to prove JWKS.
---

## The problem

AI assistants now call internal APIs through MCP. Identity already lives in Microsoft Entra ID: Conditional Access, MFA, and audit logs. Putting MCP in front of those APIs still hits four gaps.

- **No introspection endpoint.** Entra does not implement [RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662). Gateways that require token introspection cannot validate Entra access tokens. Entra publishes a JWKS document and signs JWTs instead. See [openid-connect Auth Strategy token validation methods](/ai-gateway/policies/openid-connect/#token-validation-methods).
- **Do not put `/.default` in PRM.** Microsoft documents [`/.default`](https://learn.microsoft.com/en-us/entra/identity-platform/scopes-oidc#the-default-scope) as required for the [client credentials](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow) grant. That grant returns **application** permissions. The token `oid` is the service principal. There is no user, no Entra login popup, and Conditional Access that targets people never runs. MCP clients copy `scopes_supported` from PRM. If PRM advertises `/.default`, the assistant authenticates as the app.
- **One app registration per MCP server.** Each extra app gets its own Application ID URI, redirect URIs, and admin consent. Users sign in again for every tool catalog. You then cannot answer "which person called which tool" from a single resource app.
- **No Dynamic Client Registration.** Entra app registrations are created by an administrator. MCP clients that assume [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) DCR fail until someone pastes a Client ID and secret.

If PRM lists `/.default`, the client authenticates as the app. If you register a new Entra app per MCP URL, users sign in again for each catalog.

## The solution

Kong serves [Protected Resource Metadata](https://modelcontextprotocol.io/specification/draft/basic/authorization) that lists Entra as `authorization_servers` and advertises the **delegated** scope `api://{client_id}/mcp.tools`. When an MCP client connects without a token, Kong returns `401` with `WWW-Authenticate` pointing at that metadata. The client sends the user through Entra authorization code. Entra issues a v2 JWT whose `scp` contains `mcp.tools` and whose `oid` is the signed-in user. Kong validates the JWT against Entra JWKS and forwards selected claims upstream. REST backends never see the Bearer token (`hide_credentials: true` on the Auth Strategy).

One Entra app is enough for every listener. `/orders-mcp` and `/inventory-mcp` are two example MCP URLs on Kong ([AI MCP Server](/ai-gateway/entities/ai-mcp-server/) in `listener` mode). Point them at your own REST upstreams. Keep the same issuer, JWKS, and `mcp.tools` scope.

| Component | Responsibility |
| --- | --- |
| Microsoft Entra ID | User login, token issuance, Conditional Access, audit |
| openid-connect Auth Strategy | JWKS validation and claim-to-header |
| AI MCP Server `access.metadata` | Protected Resource Metadata (PRM) |
| AI MCP Server | REST-to-MCP tools and public MCP route (`conversion-listener`) |
| CORS Policy | Browser MCP clients can read the `401` `WWW-Authenticate` challenge |
| post-function Policy | Local HTTP only: rewrite that header to `https`. Production uses TLS. |
| MCP Client | Authorization code; Entra login popup. Dify is one example. |
| Upstream | REST API behind conversion-listener tools. httpbin is one example. |

<!-- vale off -->
{% mermaid %}
sequenceDiagram
  participant User
  participant Client as MCP Client
  participant Entra as EntraID
  participant Kong
  participant Upstream
  Note over Client: Dify is one example
  Note over Upstream: httpbin is one example
  User->>Client: Register MCP server
  Client->>Kong: MCP initialize without token
  Kong-->>Client: 401 WWW-Authenticate PRM
  Client->>Entra: Authorization code mcp.tools
  User->>Entra: Sign in popup
  Entra-->>Client: JWT access token
  Client->>Kong: Bearer JWT
  Kong->>Kong: JWKS validate
  Kong->>Upstream: conversion-listener tool
  Upstream-->>Client: Tool result
{% endmermaid %}
<!-- vale on -->

## How it works

1. The MCP client calls `/orders-mcp` or `/inventory-mcp` with no `Authorization` header.
2. The conversion-listener AI MCP Server's Auth Strategy returns `401` and a `WWW-Authenticate` header whose `resource_metadata` URL is the PRM path (`access.metadata.endpoint`).
3. The client fetches PRM, reads `authorization_servers` (the Entra v2 issuer) and `scopes_supported` (`mcp.tools`, `offline_access`).
4. The user completes Entra authorization code. The access token is a v2 JWT.
5. The openid-connect Auth Strategy fetches Entra JWKS, verifies the signature and expiry, and maps `oid`, `azp`, and `appid` to upstream headers.
6. The `conversion-listener` AI MCP Server translates MCP tool calls into HTTP against httpbin in this recipe.

### openid-connect Auth Strategy: PRM and JWKS

Entra has no introspection URL, so this recipe sets `jwks_endpoint` on an openid-connect AI Auth Strategy and omits `introspection_endpoint`. PRM fields live on each MCP Server's `access.metadata` block (not a separate OAuth Policy). Omit `audience_required` to relax audience checks the way 1.0's `insecure_relaxed_audience_validation` did.

Use `conversion-listener` so tools and the public MCP route live on one entity with Auth Strategy + PRM. Prefer that over `listener` plus `conversion-only` aggregation for this OAuth path. See [openid-connect](/ai-gateway/policies/openid-connect/) and [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).

#### Configuration details

{% raw %}
```yaml
ai_gateway_auth_strategies:
- type: openid-connect
  config:
    issuer: !env DECK_ENTRA_ISSUER
    jwks_endpoint: !env DECK_ENTRA_JWKS_ENDPOINT
    auth_methods:
      - bearer
    hide_credentials: true
    upstream_headers:
      - header: X-Entra-Oid
        path: [oid]
ai_gateway_mcp_servers:
- type: conversion-listener
  access:
    acl_attribute_type: consumer
    auth_strategies: [secure-mcp-entra-id-auth]
    metadata:
      resource: !env DECK_MCP_RESOURCE
      endpoint: /.well-known/oauth-protected-resource/orders-mcp
      authorization_servers:
        - !env DECK_ENTRA_ISSUER
      scopes_supported:
        - !env DECK_ENTRA_SCOPE
        - offline_access
```
{% endraw %}
{:.no-copy-code}

- **`access.metadata.resource`**: Canonical MCP URL in PRM. Each MCP Server has its own value (`DECK_MCP_RESOURCE`, `DECK_MCP_RESOURCE_B`).
- **`authorization_servers`**: Entra v2 issuer `https://login.microsoftonline.com/{tenant}/v2.0`.
- **`jwks_endpoint`**: `https://login.microsoftonline.com/{tenant}/discovery/v2.0/keys`. Required because Entra has no introspection URL.
- **`scopes_supported`**: Values copied into PRM. Use `api://{client_id}/mcp.tools` and `offline_access`. Do not list `/.default`.
- **`ssl_verify` / `hide_credentials`**: Verify TLS to Entra JWKS and strip the Bearer token before upstream.
- **`upstream_headers`**: Maps JWT claims to upstream headers. On delegated tokens, `oid` is the signed-in user. On client credentials tokens, `oid` is the service principal.

{:.warning}
> **Do not put `/.default` in `scopes_supported` or in the MCP client.** Microsoft requires [`scope={resource}/.default`](https://learn.microsoft.com/en-us/entra/identity-platform/scopes-oidc#the-default-scope) for client credentials. That grant collects **application** roles already granted to the app. The MCP client never opens Entra login. Kong still accepts the JWT if JWKS checks pass, so the failure mode is silent: tools work, user identity does not.

| | Delegated `mcp.tools` | `/.default` client credentials |
| --- | --- | --- |
| Grant | Authorization code | Client credentials |
| Typical client | Interactive MCP hosts | `demo.py` |
| Token `scp` | `mcp.tools` | empty |
| Token `roles` | empty | `MCP.Access` |
| Token `oid` | User object ID | Service principal object ID |
| Entra login popup | Yes | No |
| Conditional Access (user) | Applies | Does not apply to a person |
| Kong `X-Entra-Oid` | User | App |

{:.warning}
> **Omit `audience_required` for Entra.** Entra `aud` is often the application (client) ID, not the MCP resource URL. Most IdPs still omit [RFC 8707](https://datatracker.ietf.org/doc/html/rfc8707) resource indicators. Setting `audience_required` rejects every Entra token for audience mismatch.

Microsoft Graph scopes `openid`, `profile`, and `email` enrich ID tokens. They do not produce an access token for your MCP resource. Request `api://{client_id}/mcp.tools` for MCP.

### AI MCP Server: conversion-listener

Each product API is a `conversion-listener` AI MCP Server: tools, public MCP route, Auth Strategy, and PRM on one entity. `/orders-mcp` and `/inventory-mcp` share the Entra Auth Strategy. Each has its own `access.metadata.resource` so catalogs stay separate.

Upstream TLS comes from `config.url` (`https://...`).

#### Configuration details

{% raw %}
```yaml
ai_gateway_mcp_servers:
- name: orders-mcp
  type: conversion-listener
  access:
    acl_attribute_type: consumer
    auth_strategies: [secure-mcp-entra-id-auth]
  config:
    url: https://httpbin.konghq.com/anything
    route:
      paths:
        - /orders-mcp
      protocols: [http, https]
      methods: [GET, POST, OPTIONS]
  tools:
    - name: list-orders
      method: GET
      path: /orders
```
{% endraw %}
{:.no-copy-code}

- **`type: conversion-listener`**: Declares REST-to-MCP tools and accepts MCP JSON-RPC on `config.route.paths`.
- **`access.acl_attribute_type: consumer`**: Required for Auth Strategy attachment on the MCP Server.
- **`config.route`**: Public matcher for the MCP path. Include `methods` with `http`/`https`.

### CORS: browser MCP clients

The [CORS](/ai-gateway/policies/cors/) Policy is for browser MCP hosts. The console origin (`DECK_DIFY_ORIGIN`, `http://localhost:8088` in this recipe) differs from the Gateway origin (`http://localhost:8000`), so the browser treats the MCP `initialize` request as cross-origin.

Without CORS, the browser hides the `401` and the `WWW-Authenticate` header from JavaScript. MCP OAuth discovery needs that header: `resource_metadata` is the PRM URL.

- List the MCP client origin in `origins`. With `credentials: true`, a wildcard origin is invalid.
- Put `WWW-Authenticate` in `exposed_headers` so the client can read the PRM URL.

`demo.py` and curl ignore CORS.

#### Configuration details

{% raw %}
```yaml
ai_gateway_policies:
- type: cors
  config:
    origins:
      - !env DECK_DIFY_ORIGIN
    exposed_headers:
      - WWW-Authenticate
    credentials: true
```
{% endraw %}
{:.no-copy-code}

- **`origins`**: Exact console origin of the MCP client. Match `DECK_DIFY_ORIGIN`.
- **`exposed_headers`**: Must include `WWW-Authenticate`. Otherwise the browser cannot start OAuth from the `401`.
- **`credentials: true`**: Allows the `Authorization` header on later tool calls from that origin.

### Post-function Policy: HTTPS `WWW-Authenticate` on local HTTP

The Auth Strategy writes `WWW-Authenticate` from the request URL. The Konnect quickstart data plane listens on **HTTP** port 8000, so that header contains `http://localhost:8000/.well-known/...`.

Browser OAuth stacks often require an `https` `resource_metadata` URL. They reject plain `http`, or `http` plus a port. On localhost this recipe uses a [post-function](/ai-gateway/policies/post-function/) Policy to rewrite the header:

- Rewrite `http://` to `https://` in `WWW-Authenticate`.
- Strip `:port` so the URL looks like a production HTTPS origin.
- Skip the rewrite when `Host` is `gateway.example.com`. MCP clients that call Kong over HTTP on that name must keep `http` in `WWW-Authenticate`.

{:.warning}
> **Do not use this rewrite in production.** Terminate TLS with a valid certificate on the data plane or on the load balancer in front of Kong. Then Kong already emits `https` `WWW-Authenticate` values, and you omit the post-function Policy.

The Lua runs in `header_filter` on the [post-function](/ai-gateway/policies/post-function/) Policy. The full script is `secure-mcp-entra-id-www-authenticate` in [Apply the Kong configuration](#apply-the-kong-configuration).

## Apply the Kong configuration

The following configuration creates an openid-connect AI Auth Strategy (JWKS validation against Entra), CORS and post-function Policies, and two `conversion-listener` AI MCP Servers that advertise Protected Resource Metadata. Every resource is scoped using a kongctl namespace. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

`DECK_ENTRA_*`, `DECK_MCP_RESOURCE`, `DECK_MCP_RESOURCE_B`, and `DECK_DIFY_ORIGIN` are already set in Prerequisites. Ensure `AI_GATEWAY_ID` is exported from the quickstart output.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
# AI Gateway 2.0 entity config for Secure MCP with Microsoft Entra ID.
#
# 1.0 ai-mcp-oauth2 splits into:
#   - ai_gateway_auth_strategies type: openid-connect (JWKS via jwks_endpoint; no introspection)
#   - ai_gateway_mcp_servers[].access.metadata (RFC 9728 PRM)
# 1.0 ai-mcp-proxy mode becomes ai_gateway_mcp_servers.type conversion-listener
# (tools + public MCP route + Auth Strategy + PRM on one entity).
_defaults:
  kongctl:
    namespace: secure-mcp-entra-id-recipe

ai_gateway_auth_strategies:
  - ref: secure-mcp-entra-id-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: secure-mcp-entra-id-auth
    display_name: secure-mcp-entra-id Entra JWKS
    type: openid-connect
    config:
      issuer: !env DECK_ENTRA_ISSUER
      jwks_endpoint: !env DECK_ENTRA_JWKS_ENDPOINT
      auth_methods:
        - bearer
      # Entra has no RFC 7662 introspection endpoint — omit introspection_endpoint.
      # Omit audience_required to relax audience checks (1.0 insecure_relaxed_audience_validation).
      scopes:
        - !env DECK_ENTRA_SCOPE
        - offline_access
      ssl_verify: true
      hide_credentials: true
      cache_tokens_salt: secure-mcp-entra-id-oidc-cache
      upstream_headers:
        - header: X-Entra-Oid
          path:
            - oid
        - header: X-Entra-Azp
          path:
            - azp
        - header: X-Entra-App-Id
          path:
            - appid

ai_gateway_policies:
  - ref: secure-mcp-entra-id-cors
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: secure-mcp-entra-id-cors
    display_name: secure-mcp-entra-id CORS
    type: cors
    config:
      origins:
        - !env DECK_DIFY_ORIGIN
      methods:
        - GET
        - HEAD
        - PUT
        - PATCH
        - POST
        - DELETE
        - OPTIONS
      headers:
        - Accept
        - Authorization
        - Content-Type
        - MCP-Protocol-Version
        - mcp-session-id
      exposed_headers:
        - MCP-Protocol-Version
        - mcp-session-id
        - WWW-Authenticate
      credentials: true
      max_age: 3600
      preflight_continue: false
  - ref: secure-mcp-entra-id-www-authenticate
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: secure-mcp-entra-id-www-authenticate
    display_name: secure-mcp-entra-id WWW-Authenticate HTTPS rewrite
    type: post-function
    config:
      header_filter:
        - |
          local h = kong.response.get_header("WWW-Authenticate")
          if type(h) ~= "string" then
            return
          end
          local host = kong.request.get_host() or ""
          if host:find("gateway.example.com", 1, true) then
            return
          end
          h = h:gsub("http://", "https://", 1)
          h = h:gsub("(https://[^/:\"%s]+):%d+", "%1", 1)
          kong.response.set_header("WWW-Authenticate", h)

ai_gateway_mcp_servers:
  - ref: orders-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: orders-mcp
    display_name: Orders MCP
    type: conversion-listener
    access:
      acl_attribute_type: consumer
      auth_strategies:
        - secure-mcp-entra-id-auth
      metadata:
        resource: !env DECK_MCP_RESOURCE
        endpoint: /.well-known/oauth-protected-resource/orders-mcp
        authorization_servers:
          - !env DECK_ENTRA_ISSUER
        scopes_supported:
          - !env DECK_ENTRA_SCOPE
          - offline_access
    config:
      url: https://httpbin.konghq.com/anything
      max_request_body_size: 1048576
      logging:
        payloads: true
      route:
        paths:
          - /orders-mcp
        protocols:
          - http
          - https
        methods:
          - GET
          - POST
          - OPTIONS
      server:
        forward_client_headers: true
    tools:
      - name: list-orders
        description: >-
          List recent orders with an optional user filter.
          Returns order summaries including order ID and item.
        method: GET
        path: /orders
        annotations:
          read_only_hint: true
          title: List orders
        parameters:
          - name: userid
            in: query
            required: false
            description: Filter by user ID
            schema:
              type: string
      - name: get-order
        description: Get full details for a specific order.
        method: GET
        path: /orders/{orderId}
        annotations:
          read_only_hint: true
          title: Get order details
        parameters:
          - name: orderId
            in: path
            required: true
            description: The order ID
            schema:
              type: string
    policies:
      - secure-mcp-entra-id-cors
      - secure-mcp-entra-id-www-authenticate

  - ref: inventory-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: inventory-mcp
    display_name: Inventory MCP
    type: conversion-listener
    access:
      acl_attribute_type: consumer
      auth_strategies:
        - secure-mcp-entra-id-auth
      metadata:
        resource: !env DECK_MCP_RESOURCE_B
        endpoint: /.well-known/oauth-protected-resource/inventory-mcp
        authorization_servers:
          - !env DECK_ENTRA_ISSUER
        scopes_supported:
          - !env DECK_ENTRA_SCOPE
          - offline_access
    config:
      url: https://httpbin.konghq.com/anything
      max_request_body_size: 1048576
      logging:
        payloads: true
      route:
        paths:
          - /inventory-mcp
        protocols:
          - http
          - https
        methods:
          - GET
          - POST
          - OPTIONS
      server:
        forward_client_headers: true
    tools:
      - name: check-inventory
        description: Check current stock for a SKU.
        method: GET
        path: /inventory/{sku}
        annotations:
          read_only_hint: true
          title: Check inventory for SKU
        parameters:
          - name: sku
            in: path
            required: true
            description: The product SKU
            schema:
              type: string
    policies:
      - secure-mcp-entra-id-cors
      - secure-mcp-entra-id-www-authenticate
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }


## Try it out

A browser MCP client should open **Entra sign-in** when it requests `mcp.tools`. `demo.py` proves JWKS without a browser. It uses client credentials and is not the user path.

### Connect Dify (interactive `mcp.tools`)

[Dify MCP](https://docs.dify.ai/en/use-dify/build/mcp) registers a remote HTTP MCP server, then authorizes if the server requires OAuth. Entra has no DCR endpoint, so turn **Dynamic Client Registration** off and paste the Entra Client ID and secret.

Use the hostname the MCP client uses to reach the Gateway. This recipe uses `gateway.example.com`:

| Field | Orders MCP | Inventory MCP |
| --- | --- | --- |
| Server URL | `http://gateway.example.com:8000/orders-mcp` | `http://gateway.example.com:8000/inventory-mcp` |
| Identifier | unique slug | different unique slug |
| Dynamic client registration | Off | Off |
| Client ID / Secret | Same Entra app | Same Entra app |
| Scopes | `api://{client_id}/mcp.tools` | `api://{client_id}/mcp.tools` |

Authorize each server once. Dify opens the Entra login popup. After sign-in you see `list-orders` and `get-order` on the first server, and `check-inventory` on the second.

{:.warning}
> Entra's OpenID discovery document often omits `grant_types_supported`. Some Dify versions treat an empty list as client credentials. The connection then succeeds as the **app**, with no popup. If Authorize does not open Entra, confirm the client is using authorization code and that the scope is `mcp.tools`, not `/.default`.

**What happened**

1. Dify called the MCP URL without a token. Kong returned `401` and PRM.
2. Dify used the Entra confidential client and the delegated scope from PRM (and your Scopes field).
3. Entra authenticated the user. The access token `scp` contains `mcp.tools`. `oid` is that user.
4. Kong verified the JWT with JWKS and listed tools for that listener only.

### Gateway reachability without a browser (`/.default`)

The smoke test script uses [client credentials](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow) and `ENTRA_CC_SCOPE` (`api://{client_id}/.default`). The script exercises the client credentials path only. Use it to confirm JWKS, PRM, and both listeners before you connect a browser client.

```bash
export PROXY_URL='http://localhost:8000'
python demo.py
```

Expected output (claims abbreviated):

```text
Entra MCP JWKS smoke test (client credentials / .default)
Interactive user auth uses authorization code + mcp.tools, not this script.

[REQUEST] POST /orders-mcp (no bearer)
HTTP 401
  WWW-Authenticate: Bearer resource_metadata="https://localhost/.well-known/oauth-protected-resource/orders-mcp"
[OK] PRM challenge

[TOKEN] client_credentials scope=api://00000000-0000-0000-0000-000000000000/.default
[OK] token
  iss=https://login.microsoftonline.com/{tenant}/v2.0
  roles=['MCP.Access']
  scp=None
  oid=...  (service principal, not a user)

[REQUEST] POST /orders-mcp tools/list
HTTP 200
  tools=['get-order', 'list-orders']
[OK] tools/list

[REQUEST] POST /inventory-mcp tools/list
HTTP 200
  tools=['check-inventory']
[OK] tools/list

[REQUEST] POST /orders-mcp (invalid bearer)
HTTP 401
[OK] invalid token rejected

[DONE] JWKS path accepts an app token; Dify still needs mcp.tools.
```
{:.no-copy-code}

**What happened**

1. Unauthenticated `tools/list` produced the MCP `401` + PRM challenge.
2. Entra token endpoint returned an app-only JWT (`roles`, no `scp`).
3. The same token listed tools on both MCP paths because both MCP Servers trust the same Entra app.
4. An invalid Bearer token was rejected with `401`.

Inspect Kong latency headers on the `200` responses: `X-Kong-Proxy-Latency` and `X-Kong-Upstream-Latency`.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `secure-mcp-entra-id-recipe`. The recipe created an openid-connect AI Auth Strategy, CORS and post-function Policies, and two conversion-listener AI MCP Servers (`orders-mcp`, `inventory-mcp`), all scoped by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1 menu in Konnect.



## Variations and next steps

- **Production clients use `mcp.tools`.** Put `/.default` only on automation (`demo.py`). A valid app token is not a successful user login.
- **Audience.** Expect `aud` to be the app ID until Entra honors RFC 8707 for your resource URL. Keep `audience_required` omitted until then.

- **Map `oid` to Kong Consumers.** Set `consumer_claims` / `consumer_by` on the openid-connect Auth Strategy, then attach per-tool ACLs as in [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/).
- **Replace httpbin.** Point the conversion-listener MCP Servers at real REST APIs. Keep the same Entra app and MCP paths.
- **Okta or Keycloak introspection.** If the IdP exposes RFC 7662, use `introspection_endpoint` instead of `jwks_endpoint`. See [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/).
- **Third-party MCP servers.** For GitHub and similar SaaS MCP endpoints, see [Secure External MCP Gateway](/cookbooks/secure-external-mcp-gateway/).

## Cleanup

If you applied the Entra Terraform sample in Prerequisites, destroy that app registration first:

```bash
terraform destroy
```

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the {{site.ai_gateway}} from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-mcp-entra-id-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
