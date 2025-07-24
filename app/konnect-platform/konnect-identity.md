---
title: "{{site.konnect_short_name}} Identity"
content_type: reference
layout: reference
tech_preview: true

products:
    - konnect-platform

permalink: /konnect-identity/
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
  - text: Configure the OIDC plugin with {{site.konnect_short_name}} Identity
    url: /how-to/configure-konnect-identity-oidc/
  - text: Configure the Upstream OAuth plugin with {{site.konnect_short_name}} Identity
    url: /how-to/configure-konnect-identity-upstream-oauth/
  - text: Configure the OAuth 2.0 Introspection plugin with {{site.konnect_short_name}} Identity
    url: /how-to/configure-konnect-identity-oauth-introspection/

description: |
  {{site.konnect_short_name}} Identity enables you to use {{site.konnect_short_name}} to generate, authenticate and authorize API access. {{site.konnect_short_name}} Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. 

faqs:
  - q: How do I retrieve my client’s secret again?
    a: |
      To retrieve your client secret, you must access the credentials stored in the Service or plugin configuration. 
      If the secret wasn't saved securely by the client application, you may need to generate a new secret through the {{site.konnect_short_name}} API or relevant client management interface.

---

{:.success}
> **Get started:**
> * [Configure the OIDC plugin with {{site.konnect_short_name}} Identity](/how-to/configure-konnect-identity-oidc/)
> * [Configure the Upstream OAuth plugin with {{site.konnect_short_name}} Identity](/how-to/configure-konnect-identity-upstream-oauth/)
> * [Configure the OAuth 2.0 Introspection plugin with {{site.konnect_short_name}} Identity](/how-to/configure-konnect-identity-oauth-introspection/)

{{site.konnect_short_name}} Identity enables you to use {{site.konnect_short_name}} to generate, authenticate, and authorize API access. Specifically, {{site.konnect_short_name}} Identity can be used for machine-to-machine authentication. 

{{site.konnect_short_name}} Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. {{site.konnect_short_name}} Identity can be used with the following Kong plugins:
* [OpenID Connect plugin](/plugins/openid-connect/)
* [OAuth2.0 Introspection plugin](/plugins/oauth2-introspection/)
* [Upstream OAuth plugin](/plugins/upstream-oauth/)

## How {{site.konnect_short_name}} Identity works

{{site.konnect_short_name}} Identity allows you to create auth servers, claims, scopes, and clients in {{site.konnect_short_name}} using the [{{site.konnect_short_name}} API](/api/konnect/kong-identity/v1/#/). Each of these components plays a specific role in how access is managed:
* **Auth server:** Issue OAuth 2.0 and OpenID Connect tokens that you can use to authenticate a client (machine) with your Gateway Services. Each auth server is unique to your organization and [{{site.konnect_short_name}} region](/konnect-platform/geos/). We recommend creating different auth servers for different environments or subsidiaries.
* **Clients:** Represent machines that request tokens, such as microservices, mobile apps, or automation scripts.
* **Scopes:** Define what those clients are allowed to access. 
* **Claims:** Optional pieces of metadata, like user roles or environment tags, that can be included in tokens and forwarded to upstream services.

To use {{site.konnect_short_name}} Identity for authentication, you must configure one of the supported plugins (OpenID Connect, OAuth2.0 Introspection, or Upstream OAuth). These plugins determine how tokens are validated, introspected, or passed along to upstream services.

## {{site.konnect_short_name}} Identity authentication flow

The following diagram shows how authentication works with {{site.konnect_short_name}} Identity:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client Application
    participant idsvc as {{site.konnect_short_name}} Identity Service
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

In the authorization code flow:
1. The client application displays the user consent page and authenticates the user (this part is handled outside {{site.base_gateway}}).
2. When the user clicks **Authorize**, the client app calls the `/authorize` endpoint created by attaching the OAuth2 plugin to a service.
3. The request includes the client ID, secret, and scopes the user consented to.
4. The authorization server ({{site.base_gateway}} with OAuth2 plugin) validates the client credentials and returns an authorization code.
5. The client exchanges this code at the `/accesstoken` endpoint for access tokens.
6. The access token is used to call protected APIs.
7. When the API call is made, the introspection plugin validates the token with the Identity Provider (IdP), identifies the associated consumer, and adds `x-consumer-*` headers to the upstream request.

<!--
For Consumer Group-scoped plugins:
- Create a consumer per client in the respective control plane.
- No need to migrate the client credential to a consumer credential.
- The OIDC plugin maps clients to consumers using claims.
- Create the required consumer groups and apply the plugin at the consumer group scope.
- Add each consumer to the appropriate consumer group in the control plane.
-->

## Dynamic claim templates

You can configure dynamic custom claims with dynamic claim templating to generate claims during runtime. These JWT claim values can be rendered as multiple types: 
* Strings 
* Integers
* Floats
* Booleans
* JSON object or arrays

The type is inferred from the value. Moreover, JWT claims values can be templated with contextual data and functions. Dynamic values must use `${}` as templating boundaries.

Claims support templating via the context passed to the client during the authentication. The context is represented by the following format:

```json
{
	"AuthServer":{
	ID:               uuid.UUID
	CreatedAt:        DateTime
	UpdatedAt:        Datetime
	Name:             string
	Description:      string
	Audience:         string
	SigningAlgorithm: string
	Labels:           map[string]string
},
"Client":{
ID:             string
	CreatedAt:      Datetime
	UpdatedAt:      Datetime
	Name:           string
	Labels: 	   map[string]string
	GrantTypes:     []string
	RedirectURIs:   []string
	LoginURI:       string
	ResponseTypes:  []string
	AllowAllScopes: bool
	AllowScopeIDs:  []string

}
}
```

To test the templating, you can use the [`/v1/auth-servers/$authServerId/clients/$clientId/test-claim` endpoint](/api/konnect/kong-identity/v1/#/operations/testClaimForClient).

