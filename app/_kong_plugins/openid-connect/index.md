---
title: 'OpenID Connect'
name: 'OpenID Connect'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Integrate {{site.base_gateway}} with a third-party OpenID Connect provider'

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: openid-connect.png

categories:
  - authentication

search_aliases:
  - oidc
  - oauth2
  - openid-connect
  - idp
  - identity provider

tags:
  - authentication

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

examples_groups:
  - slug: authentication
    text: Authentication flows and grants
  - slug: client-auth
    text: Client authentication
  - slug: authorization
    text: Authorization
  - slug: providers
    text: Common provider configurations
  - slug: fapi
    text: Financial-grade API
  - slug: other
    text: Other examples

basic_examples: false

notes: |
  In Serverless gateways, only the `cookie` config session storage is supported.


faqs:
  - q: Why does the OIDC plugin not use cached tokens with the client credentials grant, and instead connects to the IdP on every request?
    a: |
      Token caching doesn't work if both `client_credentials` and `password` are set as auth methods in the [`config.auth_methods`](/plugins/openid-connect/reference/#schema--config-auth-methods) parameter, and credentials are sent using the `Authorization: Basic` header. 
      
      In this scenario, either authentication method could match, but the plugin prioritises the password grant, based on its [order of precedence](#authentication-flows-and-grants).
      To resolve this caching issue, make sure you only have the `client_credentials` method enabled.
  - q: Is it possible to avoid using a token from a cache that is almost expired?
    a: |
      Yes. You'll need to adjust the following settings:
      * Access token lifetime, configured in the IdP.
      * Max time-to-live for the OIDC plugin cache, configured using [`config.cache_ttl_max`](/plugins/openid-connect/reference/#schema--config-cache-ttl-max) and with [`config.cache_tokens`](/plugins/openid-connect/reference/#schema--config-cache-tokens) set to `true`.

      Set the max TTL on the Kong side based on the lifetime of the access token in the IdP. 
      
      For example, if the access token lifetime is 180 seconds and you want to get a new token 15 seconds before the access token expires,
      you would set `config.cache_ttl_max=165`.
  - q: Can one OIDC plugin support JWT token validation for multiple IdPs?
    a: |
      Yes, but since the OIDC plugin only accepts one issuer URL, this requires some extra configuration.

      You can verify tokens issued by multiple IdP using the [`extra_jwks_uris`](/plugins/openid-connect/reference/#schema--config-extra-jwks-uris) configuration option, with the following considerations:

      * Since the plugin only accepts a single issuer, any `iss` claim verification will fail for tokens that come from a different IdP than the one that was used in the issuer configuration option. Add all issuers as they appear in the `iss` claims of your tokens to the [`config.issuers_allowed`](/plugins/openid-connect/reference/#schema--config-issuers-allowed) setting.
      * If you make any changes to the `extra_jwks_uris` value, you have to clear the second level DB cache for the change to become effective.
      See [Delete a Discovery Cache Object](/plugins/openid-connect/api/#/operations/deleteDiscoveryCache).

      See the [Extra JWKs](/plugins/openid-connect/examples/extra-jwks/) configuration example for more detail.
  - q: How do I enable the Proof Key for Code Exchange (PKCE) extension to the authorization code flow in the OIDC plugin?
    a: |
      The OIDC plugin supports PKCE out of the box, so you don't need to configure anything. 
      When [`config.auth_methods`](/plugins/openid-connect/reference/#schema--config-auth-methods) is set to `authorization_code`, the plugin sends the required `code_challenge` parameter automatically with the authorization code flow request. 
      
      If the IdP connected to the plugin enforces PKCE, it will be used during the authorization code flow. 
      If the IdP doesn't support or enforce PCKE, it won't be used.
 
min_version:
  gateway: '1.0'
---

The OpenID Connect (OIDC) plugin lets you integrate {{site.base_gateway}} with an identity provider (IdP).
This plugin can be used to implement {{site.base_gateway}} as a proxying [OAuth 2.0](https://tools.ietf.org/html/rfc6749) resource server 
(RS) and as an OpenID Connect relying party (RP) between the client and the upstream service.

## What does OpenID Connect do?

OpenID Connect provides a way to form a **federation** with **identity providers (IdPs)**. 
Identity providers are third parties that store account credentials. 
If an identity provider authenticates a user to an application, the application trusts that provider and allows access to the user. This shifts the responsibility of authentication from the application to the identity provider. 

Besides delegating responsibility to an identity provider, OpenID Connect also makes single sign-on possible without storing any credentials on a user’s local machine.

## What does Kong’s OpenID Connect plugin do?

The OpenID Connect plugin enables you to integrate OpenID Connect with {{site.base_gateway}} without having to write custom integrations.
Instead of manually writing code for OpenID Connect within an upstream service, you can place {{site.base_gateway}} in front of the upstream service and have {{site.base_gateway}} handle authentication.
This separation lets developers focus on the business logic within their application, easily swap out upstream services while preserving authentication at the front door, and effortlessly spread the same authentication to new upstream services.

Unlike other authentication types like Key Auth and Basic Auth, with OpenID Connect you don't need to manage user credentials directly. 
Instead, you can offload the task to a trusted identity provider of your choice.

## Discovery cache
When you configure `config.issuer` in the OIDC plugin, {{site.base_gateway}} automatically retrieves the provider’s discovery metadata. The OIDC plugin stores the metadata as a discovery cache object and uses the cache avoid repeated fetches. This cache includes the discovery document endpoints, JWKS keys, and the token endpoint. 

{{site.base_gateway}} uses the discovery cache whenever validation needs issuer metadata. The cache behaves in the following way:
- Discovery data is stored in the **{{site.base_gateway}} database** when using DB mode, or in **worker memory** when using DB‑less mode.  
- The cache TTL (time-to-live) is managed by `config.cache_ttl`, which is set to 3600 seconds by default. You can also clear it manually using the relevant [DELETE endpoints in the Admin API](/plugins/openid-connect/api/#/operations/deleteAllDiscoveryCache/).  
- If a request requires discovery information that isn't in the cache, the plugin attempts to “rediscover” it using the value in `config.issuer`. After a rediscovery occurs, no further rediscovery attempts are made until the time period defined in `config.rediscovery_lifetime` has elapsed, which helps avoid excessive requests to the identity provider.  
- If a JWT can't be validated due to missing discovery data, and a rediscovery request returns a non‑2xx status code, the plugin falls back to using any sufficient discovery information that remains in the cache.

### Manually clear discovery cache

To manually clear discovery cache entries, you can use the Admin API DELETE endpoints for the OpenID Connect plugin. These endpoints let you:
* Delete a JWKS
* Delete all caches or a specific cache

Refer to the [OIDC API reference](/plugins/openid-connect/api/) for details.

## Supported flows and grants

The OpenID Connect plugin suits many different use cases and extends other plugins 
such as [JWT](/plugins/jwt/) (JSON Web Token), [ACL](/plugins/acl/), and [0Auth 2.0](/plugins/oauth2/).
The most common use case is the [authorization code flow](#authorization-code-flow).

### Authentication flows and grants

The OIDC plugin supports several types of credentials and grants.

You can configure multiple auth grants or flows on the plugin.
The plugin searches for credentials in the following order of precedence:

1. [Session authentication](#session-authentication-workflow)
2. [JWT access token authentication](#jwt-access-token-authentication-flow)
3. [Kong OAuth token authentication](#kong-oauth-token-authentication-flow)
4. [Introspection authentication](#introspection-authentication-flow)
5. [User info authentication](#user-info-authentication-flow)
6. [Refresh token grant](#refresh-token-grant-workflow)
7. [Password grant](#password-grant-workflow) (username and password)
8. [Client credentials grant](#client-credentials-grant-workflow)
9. [Authorization code flow](#authorization-code-flow) (with client secret or PKCE)

Once it finds a set of credentials, the plugin stops searching, and won't look for any further credential types.
This precedence order is hardcoded and can't be changed.

Multiple grants may share the same credentials. For example, both the password and client credentials grants can use 
basic authentication through the `Authorization` header.

#### Session authentication workflow

The OpenID Connect plugin can issue a session cookie that can be used for further session authentication. 
To make OpenID Connect issue a session cookie, you need to first authenticate with one of the other grants or flows that this plugin supports. 
For example, the [authorization code flow](#authorization-code-flow) demonstrates session authentication when it uses the redirect login action.

The session authentication portion of the flow works like this:

{% include_cached plugins/oidc/diagrams/session.md %}

Set up session auth:
* [Plugin configuration example](/plugins/openid-connect/examples/session-auth/)
* [Session auth tutorial with Keycloak](/how-to/configure-oidc-with-session-auth/)

#### JWT access token authentication flow

For legacy reasons, the stateless `JWT Access Token` authentication is named `bearer` (see [`config.auth_methods`](/plugins/openid-connect/reference/#schema--config-auth-methods)). 
Stateless authentication means that the signature verification uses the identity provider to publish public keys and the standard claims verification (such as `exp` or expiry). 
The client may receive the token directly from the identity provider or by other means.

{% include_cached plugins/oidc/diagrams/jwt-access-token.md %}

Set up JWT access token auth:
* [Plugin configuration example](/plugins/openid-connect/examples/jwt-access-token/)
* [JWT access token auth tutorial with Keycloak](/how-to/configure-oidc-with-jwt-auth/)

#### Kong OAuth token authentication flow

The OpenID Connect plugin can verify the tokens issued by the [OAuth 2.0 plugin](/plugins/oauth2/).
This is very similar to third party identity provider issued [JWT access token authentication](#jwt-access-token-authentication-flow) or [introspection authentication](#introspection-authentication-flow):

{% include_cached plugins/oidc/diagrams/kong-oauth2.md %}

Set up Kong OAuth2 token auth:
* [Plugin configuration example](/plugins/openid-connect/examples/kong-oauth-token/)
* [Kong OAuth token tutorial with Keycloak](/how-to/configure-oidc-with-kong-oauth2/)

#### Introspection authentication flow

As with [JWT access token authentication](#jwt-access-token-authentication-flow), 
the introspection authentication relies on a bearer token that the client has already gotten from somewhere. 
The difference between introspection and stateless JWT authentication is that the plugin needs to call the introspection endpoint of the identity provider to find out whether the token is valid and active. 
This makes it possible to issue opaque tokens to the clients.

{% include_cached plugins/oidc/diagrams/introspection.md %}

Set up introspection auth:
* [Plugin configuration example](/plugins/openid-connect/examples/introspection-auth/)
* [Introspection auth tutorial with Keycloak](/how-to/configure-oidc-with-introspection/)

#### User info authentication flow

The user info authentication uses OpenID Connect standard user info endpoint to verify the access token.
In most cases, you would use [introspection authentication](#introspection-authentication-flow) instead of user info, as introspection is meant for retrieving information from the token itself, whereas the user info endpoint is meant for retrieving information about the user to whom the token was given. 
The flow is almost identical to introspection authentication:

{% include_cached plugins/oidc/diagrams/user-info.md %}

Set up user info auth:
* [Plugin configuration example](/plugins/openid-connect/examples/user-info-auth/)
* [User info auth tutorial with Keycloak](/how-to/configure-oidc-with-user-info-auth/)

#### Refresh token grant workflow

The refresh token grant can be used when the client has a refresh token available. 
There is a caveat with this: in general, identity providers only allow the refresh token grant to be executed with the same client that originally got the refresh token, and if there is a mismatch, it may not work. 
The mismatch is likely when the OpenID Connect plugin is configured to use one client, and the refresh token is retrieved with another. 

The grant itself is very similar to the [password grant](#password-grant-workflow) and
the [client credentials grant](#client-credentials-grant-workflow):

{% include_cached plugins/oidc/diagrams/refresh-token.md %}

Set up refresh token auth:
* [Plugin configuration example](/plugins/openid-connect/examples/refresh-token/)
* [Refresh token auth tutorial with Keycloak](/how-to/configure-oidc-with-refresh-token/)

#### Password grant workflow

Password grant is a **legacy** authentication grant. 
This is a less secure way of authenticating end users than the authorization code flow, because, for example, the passwords are shared with third parties.

{% include_cached plugins/oidc/diagrams/password.md %}

Set up password grant auth:
* [Plugin configuration example](/plugins/openid-connect/examples/password/)
* [Password grant tutorial with Keycloak](/how-to/configure-oidc-with-password-grant/)

#### Client credentials grant workflow

The client credentials grant is very similar to the [password grant](#password-grant-workflow).
The most important difference is that the plugin itself doesn't try to authenticate, and instead 
forwards the credentials passed by the client to the identity server's token endpoint.

{% include_cached plugins/oidc/diagrams/client-credentials.md %}

Set up client credentials grant auth:
* [Plugin configuration example](/plugins/openid-connect/examples/client-credentials/)
* [Client credentials grant tutorial with Keycloak](/how-to/configure-oidc-with-client-credentials/)

#### Authorization code flow

The authorization code flow is the three-legged OAuth/OpenID Connect flow.
The sequence diagram below describes the participants and their interactions
for this usage scenario, including the use of session cookies:

{% include_cached plugins/oidc/diagrams/auth-code.md %}

{:.info}
> If using PKCE, the identity provider *must* contain the `code_challenge_methods_supported` object 
in the `/.well-known/openid-configuration` issuer discovery endpoint response, as required by 
[RFC 8414](https://www.rfc-editor.org/rfc/rfc8414.html).
If it's not included, the PKCE `code_challenge` query parameter won't be sent.

Set up the auth code flow:
* [Plugin configuration example](/plugins/openid-connect/examples/authorization-code/)
* [Authorization code tutorial with Keycloak](/how-to/configure-oidc-with-auth-code-flow/)
* [Configure OpenID Connect with the authorization code flow and Okta](/how-to/configure-oidc-with-auth-code-flow-and-okta/)

### Authorization

The OpenID Connect plugin has several options for performing coarse-grained authorization:

1. [Claims-based authorization](#claims-based-authorization)
2. [ACL plugin authorization](#acl-plugin-authorization)
3. [Consumer authorization](#consumer-authorization)

#### Claims-based authorization

Claims-based authorization uses a pair of options to manage claims verification during authorization.
The pair can be any of:

1. [`config.scopes_claim`](/plugins/openid-connect/reference/#schema--config-scopes-claim) and 
[`config.scopes_required`](/plugins/openid-connect/reference/#schema--config-scopes-required)
2. [`config.audience_claim`](/plugins/openid-connect/reference/#schema--config-audience-claim) and 
[`config.audience_required`](/plugins/openid-connect/reference/#schema--config-audience-required)
3. [`config.groups_claim`](/plugins/openid-connect/reference/#schema--config-groups-claim) and 
[`config.groups_required`](/plugins/openid-connect/reference/#schema--config-groups-required)
4. [`config.roles_claim`](/plugins/openid-connect/reference/#schema--config-roles-claim) and 
[`config.roles_required`](/plugins/openid-connect/reference/#schema--config-roles-required)

In each parameter pair, the `*_claim` parameter points to a source, and the `*_required` parameter defines a set of claims values to check against.

Claims-based auth adheres to the following rules:
* You can validate a maximum of 4 claims at the same time
* You can [traverse an array or object for the claim name](#claim-type)
* You can validate multiple values of the same claim [using `OR` and `AND` logic](#claim-requirements)

Both the claim type and the required claim content take an array of string elements.

Set up claims-based auth:
* [Plugin configuration example](/plugins/openid-connect/examples/claims-based-auth/)
* [Claims-based auth tutorial with Keycloak](/how-to/configure-oidc-with-claims-based-auth/)

##### Claim type

For the claim type (for example, `config.groups_claim`), the array is a list of JSON objects listed in nested order. 
The plugin uses the order of the items in the array to look up data in a JSON payload.

The value of a claim can be:

* A space-separated string (common for scope claims)
* An JSON array of strings (common for groups claims)
* A simple value, such as a string

For example, let's look at the following sample payload, where `groups` is nested inside `user`:

```json
{
    "user": {
        "name": "alex",
        "groups": [
            "employee",
            "marketing"
        ]
    }
}
```

In this case, you would use `config.groups_claim` to traverse to the groups you need, where `groups` is the JSON object that contains the list of groups:

```yaml
config:
  groups_claim:
  - user
  - groups
```

##### Claim requirements

The `config.*_required` parameters (for example, `config.groups_required`) are arrays that allow logical `AND`/`OR` types of checks:

* `AND`: Space-separated values

  This claim has to have both `employee` AND `marketing`:

  ```yaml
  config:
    groups_required:
    - employee marketing
  ```

  In an Admin API request, it would look like this:

  ```sh
  --data 'config.scopes_required=employee marketing'
  ```

* `OR`: Values in separate array indices

  This claim has to have either `employee` OR `marketing`:

  ```yaml
  config:
    groups_required:
    - employee
    - marketing
  ```

  In an Admin API request, it would look like this:
  ```sh
  --data 'config.scopes_required=employee' \
  --data 'config.scopes_required=marketing'
  ```

#### ACL plugin authorization

The OpenID Connect plugin can be integrated with the [ACL plugin](/plugins/acl/), which provides access control functionality in the form of allow and deny lists.

You can also pair ACL-based authorization with {{site.base_gateway}} Consumer authorization.

Set up ACL auth:
* [Plugin configuration example](/plugins/openid-connect/examples/acl-auth/)
* [Session auth tutorial with Keycloak](/how-to/configure-oidc-with-acl-auth/)

#### Consumer authorization

You can use {{site.base_gateway}} [Consumers](/gateway/entities/consumer/) for authorization and dynamically map claim values to Consumers. 
This means that we restrict the access to only those that do have a matching Consumer. 
Consumers can have ACL groups attached to them and be further authorized with the [ACL plugin](/plugins/acl/).

Set up Consumer auth:
* [Plugin configuration example](/plugins/openid-connect/examples/consumer-auth/)
* [Consumer auth tutorial with Keycloak](/how-to/configure-oidc-with-consumers/)

### Client authentication

#### Mutual TLS client authentication

The OpenID Connect plugin supports mutual TLS (mTLS) client authentication with the IdP. 
When mTLS authentication is enabled, {{site.base_gateway}} establishes mTLS connections with the IdP using the configured client certificate.
You can use mTLS client authentication with the following IdP endpoints and corresponding flows:

* `token`
  * [Authorization Code Flow](#authorization-code-flow)
  * [Password Grant](#password-grant-workflow)
  * [Refresh Token Grant](#refresh-token-grant-workflow)
* `introspection`
  * [Introspection Authentication flow](#introspection-authentication-flow)
* `revocation`
  * [Session Authentication](#session-auth-workflow)

For all these endpoints and for the flows supported, the plugin uses mTLS client authentication as the authentication method when communicating with the IdP, for example, to fetch the token from the token endpoint.

## Financial-grade API (FAPI) {% new_in 3.7 %}

The OpenID Connect plugin supports various features of the FAPI standard, aimed to protect APIs that expose high-value and sensitive data.

{% table %}
columns:
  - title: Specification
    key: spec
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - spec: "Pushed authorization requests (PAR)"
    description:
      With PAR enabled, {{site.base_gateway}} (as the OAuth client) sends the payload of an authorization request to the IdP. 
      As a result, it obtains a `request_uri` value. 
      The client uses this value in a call to the authorization endpoint as a reference to obtain the authorization request payload data.
      <br><br>
      Use [`config.pushed_authorization_request_endpoint`](./reference/#schema--config-pushed-authorization-request-endpoint) to enable PAR.
    example: --
  - spec: "JWT-secured authorization requests (JAR)"
    description:
      With JAR enabled, when sending requests to the authorization endpoint, {{site.base_gateway}} provides request parameters in a JSON Web Token (JWT) instead of using a query string. 
      This allows for request data to be signed with JSON Web Signature (JWS).
      <br><br>
      Use [`config.require_signed_request_object`](./reference/#schema--config-require-signed-request-object) to enable JAR.
    example: --
  - spec: "JWT-secured authorization response mode (JARM)"
    description: |
      With JARM enabled, {{site.base_gateway}} requests the authorization server to return the authorization response parameters encoded in a JWT, which allows the response data to be signed with JSON Web Signature (JWS).
      <br><br>
      Set [`config.response_mode`](./reference/#schema--config-response-mode) to any of the following values: `query.jwt`, `form_post.jwt`, `fragment.jwt`, `jwt` to enable JARM.
    example: --
  - spec: "Certificate-bound access tokens"
    description: |
      Certificate-bound access tokens allow binding tokens to clients. 
      This guarantees the authenticity of the token by verifying whether the sender is authorized to use the token for accessing protected resources.
      <br><br>
      Set [`config.proof_of_possession_mtls`](./reference/#schema--config-proof-of-possession-mtls) to `strict` and [`config.client_id`](./reference/#schema--config-client-id) to `cert-bound` to enable cert-bound access tokens.
    example: "[Set up certificate-bound access tokens](/plugins/openid-connect/examples/cert-bound-access-tokens/)"

  - spec: "Mutual TLS (mTLS) client authentication with certificate-bound access tokens"
    description: |
      When mTLS client authentication is enabled, {{site.base_gateway}} establishes mTLS connections with the IdP using the configured X.509 certificate as client credentials.
      <br><br>
      If the authorization server is configured to bind the client certificate with the issued access token, {{site.base_gateway}} can validate the access token using mTLS proof of possession.
      <br><br>
      Set [`config.client_auth`](./reference/#schema--config-client-auth) to `tls_client_auth` and provide a certificate at [`config.tls_client_auth_cert_id`](./reference/#schema--config-tls-client-auth-cert-id) to enable mTLS auth.
    example: |
      [Set up mTLS client authentication](/plugins/openid-connect/examples/mtls-client-auth/)
      <br><br>
      [Set up certificate-bound access tokens](/plugins/openid-connect/examples/cert-bound-access-tokens/)
  - spec: "Demonstrating proof-of-possession (DPoP)"
    description: |
      Demonstrating Proof of Possession (DPoP) is an application-level mechanism for proving the sender's ownership of OAuth access and refresh tokens. 
      With DPoP, a client can prove the possession of a public/private key pair associated with a token by using a header. 
      The header contains a signed JWT that includes a reference to the associated access token.
      <br><br>
      When DPoP is enabled, {{site.base_gateway}} validates the DPoP header in the request to ensure that the sender is authorized to use the access token.
      <br><br>
      Set [`config.proof_of_possession_dpop`](./reference/#schema--config-proof-of-possession-dpop) to `strict` to enable DPoP.
    example: "[Demonstrating Proof-of-Possession](/plugins/openid-connect/examples/dpop/)"
{% endtable %}

### Certificate-bound access tokens

One of the main vulnerabilities of OAuth is bearer tokens. With OAuth, presenting a valid bearer token is enough proof to access a resource.
This can create problems since the client presenting the token isn't validated as the legitimate user that the token was issued to.

Certificate-bound access tokens can solve this problem by binding tokens to clients. 
This ensures the legitimacy of the token because the it requires proof that the sender is authorized to use a particular token to access protected resources. 

Certificate-bound access tokens are supported by the following auth methods:

* [JWT Access Token authentication](#jwt-access-token-authentication-flow)
* [Introspection authentication](#introspection-authentication-flow)
* [Session authentication](#session-authentication-workflow)

Session authentication is only compatible with certificate-bound access tokens when used along with one of the other supported authentication methods:

* When the configuration option [`config.proof_of_possession_auth_methods_validation`](/plugins/openid-connect/reference/#schema--config-proof-of-possession-auth-methods-validation) is set to `false` and other non-compatible methods are enabled, if a valid session is found, the proof of possession validation will only be performed if the session was originally created using one of the compatible methods. 
* If multiple `openid-connect` plugins are configured with the `session` auth method, we strongly recommend configuring different values of [`config.session_secret`](/plugins/openid-connect/reference/#schema--config-session-secret) across plugin instances for additional security. This avoids sessions being shared across plugins and possibly bypassing the proof of possession validation.

To enable certificate-bound access for OpenID Connect:
* Ensure that the auth server (IdP) that you're using is set up to generate OAuth 2.0 Mutual TLS certificate-bound access tokens.
* Use the [`proof_of_possession_mtls`](/plugins/openid-connect/reference/#schema--config-proof-of-possession-mtls) configuration option to ensure that the supplied access token belongs to the client by verifying its binding with the client certificate provided in the request.

See the [cert-bound configuration example](/plugins/openid-connect/examples/cert-bound-access-tokens/) for more detail and [Configure OpenID Connect with cert-bound access tokens](/how-to/configure-oidc-with-cert-bound-tokens/) for a complete tutorial.

### Demonstrating Proof-of-Possession (DPoP)

Demonstrating Proof-of-Possession (DPoP) is an alternative technique to the [mutual TLS certificate-bound access tokens](#mutual-tls-client-authentication). Unlike its alternative, which binds the token to the mTLS client certificate, it binds the token to a JSON Web Key (JWK) provided by the client.

{% include_cached plugins/oidc/diagrams/dpop.md %}

You can use the Demonstrating Proof-of-Possession option without mTLS, and even with plain HTTP, although HTTPS is recommended for enhanced security.

When verification of the DPoP proof is enabled, {{site.base_gateway}} removes the `DPoP` header and changes the token type from `dpop` to `bearer`.
This effectively downgrades the request to use a conventional bearer token, and allows an OAuth2 upstream without DPoP support to work with the DPoP token without losing the protection of the key binding mechanism.

DPoP is compatible with the following authentication methods:

* [JWT Access Token authentication](#jwt-access-token-authentication-flow)
* [Introspection authentication](#introspection-authentication-flow)
* [Session authentication](#session-authentication-workflow)

Session authentication is only compatible with DPoP when used along with one of the other supported authentication methods. If multiple `openid-connect` plugins are configured with the `session` authentication method, we strongly recommend configuring different values of [`config.session_secret`](/plugins/openid-connect/reference/#schema--config-session-secret) across plugin instances for additional security. This avoids sessions being shared across plugins and possibly bypassing the proof of possession validation.

To enable DPoP for OpenID Connect:
* Ensure that the auth server (IdP) that you're using has DPoP enabled.
* Use the [`config.proof_of_possession_dpop`](/plugins/openid-connect/reference/#schema--config-proof-of-possession-dpop) configuration option to ensure that the supplied access token is bound to the client by verifying its association with the JWT provided in the request.

See the [DPoP configuration example](/plugins/openid-connect/examples/dpop/) for more detail.

## Debugging the OIDC plugin

If you have issues with the OIDC plugin, try the following debugging methods:

1. Set the {{site.base_gateway}} [log level](/gateway/configuration/#log-level) to `debug`, and check the {{site.base_gateway}} `error.log`. 
You can filter the log with the keyword `openid-connect`.

2. Set the OpenID Connect plugin to display errors by setting [`config.display_errors`](./reference/#schema--config-display-errors) to true.

3. Temporarily disable the OpenID Connect plugin verifications by setting the following parameters to `false`:
  * [`config.verify_nonce`](./reference/#schema--config-verify-nonce)
  * [`config.verify_claims`](./reference/#schema--config-verify-claims)
  * [`config.verify_signature`](./reference/#schema--config-verify-signature)

4. Check what kinds of tokens the OpenID Connect plugin can receive by reviewing the following parameter configurations, and ensure that your token type is allowed:
  * [`config.login_action`](./reference/#schema--config-login-action)
  * [`config.login_tokens`](./reference/#schema--config-login-tokens)
  * [`config.login_methods`](./reference/#schema--config-login-methods)

5. Session-related issues are often caused by large cookies. Try storing the session data in `Redis` or `memcache`, as that will make the session cookie much smaller. Set this up using [`config.session_storage`](./reference/#schema--config-session-storage).

6. Try to eliminate indirection in the form of other gateways, load balancers, NATs, and so on, in front of {{site.base_gateway}}, as that makes it easier to find out where the problem is. 
If one of these other applications is causing issues, looking into using the following:
  * [Port maps](/gateway/configuration/#port-maps)
  * [`X-Forwarded-*` headers](/gateway/configuration/#trusted-ips)

## Supported identity providers

The plugin has been tested with several OpenID Connect providers:

- [Auth0](https://auth0.com/docs/protocols/openid-connect-protocol)
- [Amazon AWS Cognito](https://curity.io/resources/learn/openid-connect-overview/)
- [Connect2id](https://connect2id.com/products/server)
- [Curity](https://curity.io/resources/learn/openid-connect-overview/)
- [Dex](https://dexidp.io/docs/openid-connect/)
- [Gluu](https://gluu.org/docs/ce/api-guide/openid-connect-api/)
- [Google](https://developers.google.com/identity/protocols/oauth2/openid-connect)
- [IdentityServer](https://duendesoftware.com/)
- [Keycloak](http://www.keycloak.org/documentation.html)
- [Microsoft Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc)
- [Microsoft Active Directory Federation Services](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/development/ad-fs-openid-connect-oauth-concepts)
- [Microsoft Live Connect](https://docs.microsoft.com/en-us/advertising/guides/authentication-oauth-live-connect)
- [Okta](https://developer.okta.com/docs/api/resources/oidc.html)
- [OneLogin](https://developers.onelogin.com/openid-connect)
- [OpenAM](https://backstage.forgerock.com/docs/openam/13.5/admin-guide/#chap-openid-connect)
- [PayPal](https://developer.paypal.com/docs/log-in-with-paypal/integrate/)
- [PingFederate](https://www.pingidentity.com/en/platform/capabilities/authentication-authority/pingfederate.html)
- [Salesforce](https://help.salesforce.com/articleView?id=sf.sso_provider_openid_connect.htm&type=5)
- [WSO2](https://is.docs.wso2.com/en/latest/guides/authentication/standard-based-login/add-oidc-idp-login/)
- [Yahoo!](https://developer.yahoo.com/oauth2/guide/openid_connect/)

As long as your provider supports OpenID Connect standards, the plugin should
work, even if it is not specifically tested against it.
