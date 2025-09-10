---
title: "Kong Identity"
content_type: reference
layout: reference
beta: true

products:
    - konnect

permalink: /kong-identity/
works_on:
    - konnect
search_aliases:
  - Kong IdP
  - Konnect IdP
breadcrumbs:
  - /konnect/

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

related_resources:
  - text: Configure the OIDC plugin with Kong Identity
    url: /how-to/configure-kong-identity-oidc/
  - text: Configure the Upstream OAuth plugin with Kong Identity
    url: /how-to/configure-kong-identity-upstream-oauth/
  - text: Configure the OAuth 2.0 Introspection plugin with Kong Identity
    url: /how-to/configure-kong-identity-oauth-introspection/

description: |
  Kong Identity enables you to use {{site.konnect_short_name}} to generate, authenticate and authorize API access. Kong Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. 

---

{:.success}
> **Get started:**
> * [Configure the OIDC plugin with Kong Identity](/how-to/configure-kong-identity-oidc/)
> * [Configure the Upstream OAuth plugin with Kong Identity](/how-to/configure-kong-identity-upstream-oauth/)
> * [Configure the OAuth 2.0 Introspection plugin with Kong Identity](/how-to/configure-kong-identity-oauth-introspection/)

Kong Identity enables you to use {{site.konnect_short_name}} to generate, authenticate, and authorize API access. 
Specifically, Kong Identity can be used for machine-to-machine authentication. 

You can use Kong Identity to:
* Create authorization servers per region
* Issue and validate access tokens
* Integrate secure authentication into your {{site.base_gateway}} APIs 

Kong Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. Kong Identity can be used with the following Kong plugins:
* [OpenID Connect plugin](/plugins/openid-connect/)
* [OAuth2.0 Introspection plugin](/plugins/oauth2-introspection/)
* [Upstream OAuth plugin](/plugins/upstream-oauth/)

## How Kong Identity works

Kong Identity allows you to create auth servers, claims, scopes, and clients in {{site.konnect_short_name}} using the [{{site.konnect_short_name}} API](/api/konnect/kong-identity/v1/#/). Each of these components plays a specific role in how access is managed:
* **Auth server:** Issue OAuth 2.0 and OpenID Connect tokens that you can use to authenticate a client (machine) with your Gateway Services. Each auth server is unique to your organization and [{{site.konnect_short_name}} region](/konnect-platform/geos/). We recommend creating different auth servers for different environments or subsidiaries.
* **Clients:** Represent machines that request tokens, such as microservices, mobile apps, or automation scripts.
* **Scopes:** Define what those clients are allowed to access. 
* **Claims:** Optional pieces of metadata, like user roles or environment tags, that can be included in tokens and forwarded to upstream services.

To use Kong Identity for authentication, you must configure one of the supported plugins (OpenID Connect, OAuth2.0 Introspection, or Upstream OAuth). These plugins determine how tokens are validated, introspected, or passed along to upstream services.

## Kong Identity client credential authentication flow

The following diagram shows how authentication works with Kong Identity:

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

## Kong Identity authorization code flow

In the authorization code flow:
1. (Optional) The client application displays the user consent page and authenticates the user (this part is handled outside {{site.base_gateway}}). When the user clicks **Authorize**, the client app calls the `/authorize` endpoint created by attaching the OAuth2 plugin to a service.

   {:.info}
   > If an app requires user authentication, the authorization step must happen outside of {{site.konnect_short_name}}.
   
3. The client makes a request that includes the client ID, secret, and scopes the user consented to.
4. The authorization server ({{site.base_gateway}} with OAuth2 plugin) validates the client credentials and returns an authorization code.
5. The client exchanges this code at the `/oauth/token` endpoint for access tokens.
6. The client uses the access token to call protected APIs.

## Kong Consumer Group plugin flow
In the consumer group plugin flow:
1. In **{{site.konnect_short_name}} > API Gateway > Consumers**, the client creates the consumer. Each user that needs access is represented as a consumer.

   {:.info}
   > If using OIDC, you don’t need to manually map credentials. The OIDC plugin automatically maps clients to consumers based on token claims.
2. The client defines the required Consumer Groups in {{site.konnect_short_name}}, and then applies the desired plugin at the consumer group scope.
3. The client assigns each consumer to the appropriate consumer group. Once assigned, the plugin configuration at the group level automatically applies to the consumer.

## Dynamic claim templates

You can configure dynamic claim templates to generate custom claims during runtime. These JWT claim values can be rendered as any of the following types:
* Strings 
* Integers
* Floats
* Booleans
* JSON object or arrays

The type is inferred from the value. 

JWT claim values can also be templated with contextual data and functions. Dynamic values must use `${}` as templating boundaries.

Claims support templating via the context passed to the client during the authentication, in the following format:

```json
{
  "AuthServer": {
    "ID": "uuid.UUID",
    "CreatedAt": "DateTime",
    "UpdatedAt": "DateTime",
    "Name": "string",
    "Description": "string",
    "Audience": "string",
    "SigningAlgorithm": "string",
    "Labels": {
      "key": "value"
    }
  },
  "Client": {
    "ID": "string",
    "CreatedAt": "DateTime",
    "UpdatedAt": "DateTime",
    "Name": "string",
    "Labels": {
      "key": "value"
    },
    "GrantTypes": [
      "string"
    ],
    "RedirectURIs": [
      "string"
    ],
    "LoginURI": "string",
    "ResponseTypes": [
      "string"
    ],
    "AllowAllScopes": true
  }
}
```

To test the templating, you can use the [`/v1/auth-servers/$authServerId/clients/$clientId/test-claim` endpoint](/api/konnect/kong-identity/v1/#/operations/testClaimForClient).

