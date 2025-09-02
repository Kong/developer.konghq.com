---
title: Dev Portal Dynamic Client Registration
content_type: reference
layout: reference

products:
    - dev-portal

breadcrumbs: 
  - /dev-portal/
tags:
  - dynamic-client-registration
  - authentication

works_on:
    - konnect
search_aliases:
  - dcr
  - oidc
description: | 
    Describes supported DCR identity providers and supported DCR authentication methods. 
related_resources:
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: Configure Dynamic Client Registration with Okta
    url: /how-to/okta-dcr/
  - text: Configure Dynamic Client Registration with Curity
    url: /how-to/curity-dcr/
  - text: Configure Dynamic Client Registration with Auth0
    url: /how-to/auth0-dcr/
  - text: Configure Dynamic Client Registration with Azure
    url: /how-to/azure-dcr/
  - text: About OIDC Dynamic Client Registration
    url: https://openid.net/specs/openid-connect-registration-1_0.html
  - text: About Dev Portal OIDC authentication
    url: /dev-portal/auth-strategies/#dev-portal-oidc-authentication
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: Dev Portal developer sign-up
    url: /dev-portal/developer-signup/
  - text: Link static clients with self-managed OIDC
    url: /dev-portal/auth-strategies/#link-static-clients-with-self-managed-oidc
faqs:
  - q: What connections and protocols are involved between Dev Portal and our organization when DCR is enabled?
    a: "{{site.konnect_short_name}} will make HTTP requests to the IdP for DCR. The details of the request are IdP-specific."
  - q: What connections and protocols are involved when a custom HTTP DCR bridge is configured for a custom IdP?
    a: Kong uses HTTPS to transmit events to the domain you've provided and includes a key that can be used on your custom handler implementation to verify the events are from {{site.konnect_short_name}}.
---
Dynamic Client Registration (DCR) in {{site.konnect_short_name}} Dev Portal lets an application in the portal register as a client at an Identity Provider (IdP). The IdP returns a client identifier and the registered client metadata. This shifts credential issuance and client policy to the IdP and enables OpenID Connect (OIDC) features that the IdP supports.

## DCR in the {{site.konnect_short_name}} workflow

1. You set an application authentication strategy for an API in Dev Portal, then link the API to a Gateway Service.
2. {{site.konnect_short_name}} applies a managed configuration on that Service.
3. A developer creates an application in Dev Portal for that API.
4. Dev Portal registers that application as a client at the IdP through DCR and displays the returned credentials to the developer.

Requests to your API succeed only when the client presents valid credentials and the application holds a registration for the linked Service.

## DCR protocol
1. Portal admins → set a DCR-based strategy on the API in Dev Portal to define how client apps identify to the API.
2. Portal admins → link the API to a Gateway Service to ensure that all requests are routed through a Service that follows the strategy.
3. Developer → creates an application in Dev Portal for that API to request client credentials through a self-service path.
4. Dev Portal → calls the endpoint for client registration with client metadata to register the application as a client.
5. Authorization server (IdP) → returns a registration response that contains `client_id` and the registered metadata, and in some cases a `client_secret`, to provide credentials for token and authorization flows.
6. Developer → uses the issued credentials at the token endpoint and then calls the API to obtain tokens and access the API under the policy that you set.

{% mermaid %}
sequenceDiagram
    actor Developer
    Developer->> +Portal: Creates an application
    Portal->>+IDP: Creates an application
    IDP->>-Portal: Returns client metadatas, ClientID/Secrets
    Portal->>Portal: Saves application record in database with ONLY ClientID mapping
    Portal->>-Developer: returns application creation success with clientID/Secret
{% endmermaid %}

### What a valid DCR request and response look like

**Request example:** Send a POST to the **Client Registration Endpoint** with client metadata as top-level JSON members. This example follows RFC 7591 and OIDC Dynamic Client Registration 1.0:
```json
{
    "client_name": "Orders Web",
    "redirect_uris": [
        "https://app.example.com/callback"
    ],
    "grant_types": [
        "authorization_code",
        "refresh_token"
    ],
    "token_endpoint_auth_method": "client_secret_basic",
    "application_type": "web"
}
```
- `redirect_uris`, `grant_types`, `token_endpoint_auth_method`, and `client_name` are standard client metadata under RFC 7591.
- `application_type` is an OIDC client metadata parameter with allowed values like web and native, from OIDC Dynamic Client Registration 1.0.

**Response example:** On success, the endpoint returns HTTP 201 and a JSON body that contains the issued identifier and the registered metadata. When the server supports client management, it also returns a Registration Access Token and a Client Configuration Endpoint URI. An example of the response you might get:
```json
{
    "client_id": "s6BhdRkqt3",
    "client_secret": "ZJYCqe3GGRvdrudKyZS0XhGv_Z45DuKhCUk0gBR1vZk",
    "client_id_issued_at": 1730419200,
    "client_secret_expires_at": 0,
    "registration_access_token": "this.is.an.access.token.value.ffx83",
    "registration_client_uri": "https://server.example.com/connect/register?client_id=s6BhdRkqt3",
    "token_endpoint_auth_method": "client_secret_basic",
    "application_type": "web",
    "redirect_uris": [
        "https://app.example.com/callback"
    ],
    "client_name": "Orders Web",
    "grant_types": [
        "authorization_code",
        "refresh_token"
    ]
}
```
- `client_id` is required. 
- `client_secret` appears for confidential clients.
- `client_id_issued_at` and `client_secret_expires_at` are standard response members.
- `registration_access_token` and `registration_client_uri` appear when the server enables client management. Implementations return both values or neither.

In a DCR strategy, the Dev Portal submits the registration request to your IdP and displays the returned client credentials to the developer’s application. This behavior appears in [Application authentication strategies](/application_authentication_strategies).

## Authentication methods

DCR registers the application as a client at your Identity Provider. The client authenticates when it requests tokens or calls protected resources after registration. DCR support in {{site.konnect_short_name}} provides multiple methods by which applications can be authenticated using industry-standard protocols. These methods include:

* **Client credentials grant**: Authenticate with the client ID and secret provided to the application.
* **Bearer tokens**: Authenticate using a token requested from the IdP's `/token` endpoint.
* **Session cookie**: Allow sessions from either client credentials or bearer tokens to persist via cookie until an expiration.

Each method is available when using the following DCR identity providers:
* [Okta](/how-to/okta-dcr/)
* [Curity](/how-to/curity-dcr/)
* [Azure](/how-to/azure-ad-dcr/)
* [Auth0](/how-to/auth0-dcr/)

{:.info}
> **Note:** When using DCR, each application automatically receives a client ID and secret. These credentials can be used to authenticate directly with services using the client credentials grant, or to obtain an access token from the identity provider when using the bearer token authentication method.

### Authentication with bearer tokens

You can obtain a bearer access token by requesting it from the IdP's `/token` endpoint:

The following table describes the token endpoints for IdPs:

<!--vale off-->
{% table %}
columns:
  - title: Vendor
    key: vendor
  - title: Endpoint
    key: endpoint
  - title: Body
    key: body
rows:
  - vendor: "Auth0"
    endpoint: "POST `https://$REGION.auth0.com/oauth/token`"
    body: '`{ "grant_type": "client_credentials", "audience": "$YOUR_AUDIENCE" }`'
  - vendor: "Curity"
    endpoint: "POST `https://$YOUR_CURITY_DOMAIN/oauth/v2/oauth-token`"
    body: '`{ "grant_type": "client_credentials" }`'
  - vendor: "Okta"
    endpoint: "POST `https://$OKTA_SUBDOMAIN.okta.com/oauth2/default/v1/token`"
    body: '`{ "grant_type": "client_credentials" }`'
  - vendor: "Azure"
    endpoint: "POST `https://login.microsoftonline.com/$YOUR_TENANT_ID/oauth2/v2.0/token`"
    body: '`{ "grant_type": "client_credentials", "scope": "https://graph.microsoft.com/.default" }`'
{% endtable %}
<!--vale on-->


### Authentication with session cookie

After successfully authenticating using either client credentials or a bearer access token, you can use session cookie authentication to authenticate subsequent requests without including the original credentials. To use this method, ensure that your identity provider is configured to send session cookie response headers.

## Configure a custom IdP for Dynamic Client Registration

{{site.konnect_short_name}} Dev Portal supports a variety of the most widely adopted identity provider (IdP) for Dynamic Client Registration (DCR):

* Auth0
* Azure
* Curity
* Okta

If your third-party IdP is not on this list, you can still use your IdP with {{site.konnect_short_name}} by using a custom HTTP DCR bridge. This HTTP DCR bridge acts as a proxy and translation layer between your IdP and DCR applications in the Dev Portal. When a developer creates a DCR application in the Dev Portal, {{site.konnect_short_name}} calls your HTTP DCR bridge which can translate the application data into a suitable format for your third-party IdP.

{% mermaid %}
sequenceDiagram
    actor Developer
    participant Konnect Dev Portal
    participant HTTP DCR Bridge
    participant IdP
    Developer->>Konnect Dev Portal: Create application
    Konnect Dev Portal->>HTTP DCR Bridge: POST Create application
    HTTP DCR Bridge->>IdP: POST Create application
    IdP--)HTTP DCR Bridge: 200 OK and credentials
    HTTP DCR Bridge->>Konnect Dev Portal: Create application response (with credentials from IdP)
    Konnect Dev Portal->>Developer: Show credentials
{% endmermaid %}

> _**Figure 1:** This diagram illustrates how an HTTP DCR bridge creates an application in an IdP when a developer submits an application in the {{site.konnect_short_name}} Dev Portal. First, the developer creates an application in the Dev Portal, which triggers the portal to send the application details to the HTTP DCR bridge. The bridge then sends a `POST create application` request to the IdP. If the IdP successfully processes the request, it returns a `200` status code along with the credentials for the developer’s application. These credentials are then displayed to the developer in the Dev Portal._

### Configure custom DCR using the {{site.konnect_short_name}} Dev Portal DCR Handler

To use an unsupported IdP with DCR, you must implement an API that conforms to the [{{site.konnect_short_name}} Dev Portal DCR Handler spec](https://github.com/Kong/konnect-portal-dcr-handler/blob/main/openapi/openapi.yaml). Kong provides an example reference implementation in the [{{site.konnect_short_name}} Dev Portal DCR Handler repository](https://github.com/Kong/konnect-portal-dcr-handler). This is an example HTTP DCR bridge implementation and is not meant to be deployed in production. We encourage you to use this implementation as a guide to create your own implementation.

Any request that does not return a `2xx` status code is considered a failure and will halt the application creation process in your {{site.konnect_short_name}} Dev Portal.
