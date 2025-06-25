---
title: Kong Identity
content_type: reference
layout: reference
tech_preview: true

products:
    - konnect-platform

permalink: /kong-identity/
works_on:
    - konnect
search_aliases:
  - Kong IDP
breadcrumbs:
  - /konnect/

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

related_resources:
- text: How to configure Kong Identity
  url: /kong-identity/get-started/
- text: Dynamic Templating
  url: /kong-identity/dynamic-templates/

description: |
  Kong Identity enables customers to use {{site.konnect_short_name}} to generate, authenticate and authorize API access. Kong Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. 

faqs:
  - q: How does the authorization code flow work with Kong Identity?
    a: |
      In the authorization code flow:
      1. The **client application** displays the user consent page and authenticates the user (this part is handled outside Kong).
      2. When the user clicks "Authorize," the client app calls the `/authorize` endpoint created by attaching the OAuth2 plugin to a service.
      3. The request includes the client ID, secret, and scopes the user consented to.
      4. The **authorization server** ({{site.base_gateway}} with OAuth2 plugin) validates the client credentials and returns an **authorization code**.
      5. The client exchanges this code at the `/accesstoken` endpoint for access tokens.
      6. The access token is used to call protected APIs.
      7. When the API call is made, the **introspection plugin** validates the token with the Identity Provider (IdP), identifies the associated consumer, and adds `x-consumer-*` headers to the upstream request.

  - q: How do I retrieve my client’s secret again?
    a: |
      To retrieve your client secret, you must access the credentials stored in the service or plugin configuration. 
      If the secret was not saved securely by the client application, you may need to generate a new secret through the Kong Admin API or relevant client management interface.

---
Kong Identity enables customers to use Konnect to generate, authenticate and authorize API access. Kong Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. Kong Identity can be used with the following Kong plugins today:
  1. OpenID Connect plugin
  2. OAuth2.0 Introspection plugin
  3. Upstream OAuth plugin


## Kong Identity Flow
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client Application
    participant idsvc as Kong Identity Service
    participant gateway as Kong Gateway
    participant api as Customer API
    client->>idsvc: request access token<br>(Client ID, Client Secret, requested scope)
    idsvc->>idsvc: validate credentials
    idsvc-->>client: access token, granted scope, expiry time
    client->>gateway: /get_protected_resource<br>(access token, granted scope)
    gateway->>idsvc: validate access token
    idsvc-->>gateway: validate access token
    gateway->>api: get_resource
    api-->>gateway: resource
    gateway-->>client: resource
{% endmermaid %}
<!--vale on-->

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Authorization: Bearer $KONNECT_TOKEN'
  - 'Content-Type: application/json'
body:
  name: Appointments Dev
  audience: http://myhttpbin.dev
  description: auth server for Appointment's dev environment
{% endkonnect_api_request %}
<!--vale on-->

## Use cases
Kong Identity can be used with multiple use cases with {{site.base_gateway}} in {{site.konnect_short_name}}.

{% navtabs "use cases" %}
{% navtab "OIDC" %}

You can use the OIDC plugin to use Kong Identity as the identity provider for your {{site.base_gateway}} services. Apply the [OIDC plugin](/plugins/openid-connect/) at global/service level with the following fields:

```yaml
- name: openid-connect
  config:
    issuer: https://foo.us.identity.konghq.com/auth
```

Generate a token for the client by making a call to the issuer URL:

<!--vale off-->
{% http_request %}
url: https://<Issuer_URI>/auth/oauth/token
method: POST
headers:
  - "Content-Type: application/x-www-form-urlencoded"
body:
  grant_type: client_credentials
  client_id: generated_client_id
  client_secret: generated_client_secret
  scope: Scope
{% endhttp_request %}
<!--vale on-->


**Response:**
```json
{
  "access_token": "thisisademoaccesstoken",
  "token_type": "Bearer",
  "expires_in": 3599,
  "scope": "Scope"
}
```

{% endnavtab %}

{% navtab "OAuth2.0 Introspection" %}

You can validate access tokens sent by developers using Kong Identity’s Authorization Server by leveraging the introspection endpoint. This plugin assumes that the consumer already has an access token that will be validated against a third-party OAuth 2.0 server.

Apply the OAuth2.0 introspection plugin at global/service level with the following fields:

```yaml
- name: oauth2-introspection
  config:
    introspection_url: "https://foo.us.identity.konghq.com/auth/introspection"
    authorization_value: "Basic a29uZzpub3Qtc28tc2VjcmV0"
    consumer_by: "client_id"
    custom_claims_forward:
      - "my-claim"
```

Generate a token for the client by making a call to the issuer URL:

<!--vale off-->
{% http_request %}
url: https://<Issuer_URI>/auth/oauth/token
method: POST
headers:
  - "Content-Type: application/x-www-form-urlencoded"
body:
  grant_type: client_credentials
  client_id: generated_client_id
  client_secret: generated_client_secret
  scope: Scope
{% endhttp_request %}
<!--vale on-->


**Response:**
```json
{
  "access_token": "thisisademoaccesstoken",
  "token_type": "Bearer",
  "expires_in": 3599,
  "scope": "Scope"
}
```

{% endnavtab %}

{% navtab "Upstream OAuth" %}

The Upstream OAuth plugin allows {{site.base_gateway}} to support OAuth flows between Kong and the upstream API. The plugin can support storing tokens issued by Kong Identity.

The Upstream OAuth plugin automatically authenticates the client on protected paths in the {{site.base_gateway}}.

Apply the plugin at global or scoped level. Use Kong Identity’s OAuth Token Endpoint in the configuration.

Send an unauthenticated request to the Gateway. This route's plugin configuration will mint a new Bearer access token and use it to authenticate the request to the upstream service.

{% endnavtab %}

{% navtab "Consumer-scoped" %}

For Consumer-scoped plugins:
- Create a consumer per client in the respective control plane.
- You do not need to migrate the client credential to a consumer credential.
- The OIDC plugin will map clients to consumers using claims with the `consumer_claim` field.
- Apply the consumer-scoped plugin to the consumer entity in the control plane.

{% endnavtab %}

{% navtab "Consumer Group-scoped" %}

For Consumer Group-scoped plugins:
- Create a consumer per client in the respective control plane.
- No need to migrate the client credential to a consumer credential.
- The OIDC plugin maps clients to consumers using claims.
- Create the required consumer groups and apply the plugin at the consumer group scope.
- Add each consumer to the appropriate consumer group in the control plane.

{% endnavtab %}
{% endnavtabs %}


## Glossary 
{% table %}
columns:
  - title: Term
    key: term
  - title: Definition
    key: definition
rows:
  - term: Authorization Server
    definition: >
      Auth Servers generate OAuth 2.0 and OpenID Connect tokens. The Konnect Management API allows you to create, configure, and manage multiple Auth Servers per Konnect organization. Auth Servers are regional Konnect entities. They also provide the option to manage "claims" and "scopes" for clients.
  - term: Client
    definition: >
      The machine entity that requests tokens for authentication. Clients belong to auth servers. Clients represent the identity of machines, such as microservices, mobile apps, or scripts for {{site.base_gateway}} use cases.
  - term: Token
    definition: >
      A short-lived token for a client, generated by Kong Identity, used in the OAuth and OIDC flows. This token authenticates the machine to the application, and the claims authorize the client. The token does not contain any credential information. A JWT token is minted by the auth server.
{% endtable %}
