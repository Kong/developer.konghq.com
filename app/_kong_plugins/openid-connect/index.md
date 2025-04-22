---
title: 'OpenID Connect'
name: 'OpenID Connect'

content_type: plugin

publisher: kong-inc
description: 'Integrate Kong with a third-party OpenID Connect provider'

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
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
---

The OpenID Connect (OIDC) plugin lets you integrate {{site.base_gateway}} with an identity provider (IdP).
This plugin can be used to implement Kong as a proxying [OAuth 2.0](https://tools.ietf.org/html/rfc6749) resource server 
(RS) and as an OpenID Connect relying party (RP) between the client and the upstream service.

## What does OpenID Connect do?

OpenID Connect provides a way to form a **federation** with **identity providers (IdPs)**. 
Identity providers are third parties that store account credentials. 
If an identity provider authenticates a user to an application, the application trusts that provider and allows access to the user. This shifts the responsibility of authentication from the application to the identity provider. 

Besides delegating responsibility to an identity provider, OpenID Connect also makes single sign-on possible without storing any credentials on a user’s local machine.

## What does Kong’s OpenID Connect plugin do?

The OpenID Connect plugin enables you to integrate OpenID Connect with {{site.base_gateway}} without having to write custom integrations.
Instead of manually writing code for OpenID Connect within a service, you can place {{site.base_gateway}} in front of the upstream service and have {{site.base_gateway}} handle authentication.
This separation lets developers focus on the business logic within their application, easily swap out services while preserving authentication at the front door, and effortlessly spread the same authentication to new services.

Unlike other authentication types like Key Auth and Basic Auth, with OpenID Connect you don't need to manage user credentials directly. 
Instead, you can offload the task to a trusted identity provider of your choice.

## Supported flows and grants

The OpenID Connect plugin suits many different use cases and extends other plugins 
such as [JWT](/plugins/jwt/) (JSON Web Token), [ACL](/plugins/acl/), and [0Auth 2.0](/plugins/oauth2/).
The most common use case is the [authorization code flow](#authorization-code-flow).

### Authentication flows and grants

The OIDC plugin supports several types of credentials and grants.
When this plugin is configured with multiple grants or flows, there is a hardcoded search
order for the credentials:

1. [Session authentication](#session-authentication-workflow)
2. [JWT access token authentication](#jwt-access-token-authentication-flow)
3. [Kong OAuth token authentication](#kong-oauth-token-auth-flow)
4. [Introspection authentication](#introspection-authentication-flow)
5. [User info authentication](#user-info-authentication-flow)
6. [Refresh token grant](#refresh-token-grant-workflow)
7. [Password grant](#password-grant-workflow) (username and password)
8. [Client credentials grant](#client-credentials-grant-workflow)
9. [Authorization code flow](#authorization-code-flow) (with client secret or PKCE)

Once it finds a set of credentials, the plugin stops searching, and won't look for any further credential types.

Multiple grants may share the same credentials. For example, both the password and client credentials grants can use 
basic authentication through the `Authorization` header.

#### Authorization code flow

The authorization code flow is the three-legged OAuth/OpenID Connect flow.
The sequence diagram below describes the participants and their interactions
for this usage scenario, including the use of session cookies:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: HTTP request
    kong->>client: Redirect mobile app to IDP 
    deactivate kong
    activate idp
    client->>idp: Request access and authentication<br>with client parameter
    Note left of idp: /auth<br>response_type=code,<br>scope=openid
    idp->>client: Login (ask for consent)
    client->>idp: /auth with user credentials (grant consent)
    idp->>client: Return authorization code and redirect
    Note left of idp: short-lived authcode
    activate kong
    client->>kong: HTTP redirect with authorization code
    deactivate client
    kong->>kong: Verify authorization code flow
    kong->>idp: Request ID token, access token, and refresh token
    Note left of idp: /token<br>client_id:client_secret<br>authcode
    idp->>idp: Authenticate client (Kong)<br>and validate authcode
    idp->>kong: Returns tokens
    Note left of idp: ID token, access token, and refresh token
    deactivate idp
    kong->>kong: Validate tokens
    Note right of kong: Cryptographic<br>signature validation,<br>expiry check<br>(OIDC Standard JWT validation)
    activate client
    kong->>client: Redirect with session cookie<br>having session ID (SID)
    Note left of kong: sid: cryptorandom bytes <br>(128 bits)<br>& HMAC protected
    client->>kong: Authenticated request with session cookie
    deactivate client
    kong->>kong: Verify session cookie
    Note right of kong: Retrieve encrypted tokens<br>from session store (redis)
    activate httpbin
    kong->>httpbin: Backend service request with tokens
    Note right of idp: Access token and ID token
    httpbin->>kong: Backend service response
    deactivate httpbin
    activate client
    kong->>client: HTTP response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

{:.info}
> If using PKCE, the identity provider *must* contain the `code_challenge_methods_supported` object 
in the `/.well-known/openid-configuration` issuer discovery endpoint response, as required by 
[RFC 8414](https://www.rfc-editor.org/rfc/rfc8414.html).
If it's not included, the PKCE `code_challenge` query parameter won't be sent.

#### Client credentials grant workflow

The client credentials grant is very similar to the [password grant](#password-grant-workflow).
The most important difference is that the plugin itself doesn't try to authenticate, and instead 
forwards the credentials passed by the client to the identity server's token endpoint.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with<br>basic authentication
    deactivate client
    kong->>kong: load basic<br>authentication credentials
    activate idp
    kong->>idp: IdP/token<br>with client credentials
    deactivate kong
    idp->>idp: authenticate client
    activate kong
    idp->>kong: return tokens
    deactivate idp
    kong->>kong: verify tokens
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

#### Introspection authentication flow

As with [JWT access token authentication](#jwt-access-token-authentication-flow), 
the introspection authentication relies on a bearer token that the client has already gotten from somewhere. 
The difference between introspection and stateless JWT authentication is that the plugin needs to call the introspection endpoint of the identity provider to find out whether the token is valid and active. 
This makes it possible to issue opaque tokens to the clients.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with access token
    deactivate client
    kong->>kong: load access token
    activate idp
    kong->>idp: IdP/introspect with <br/>client credentials and access token
    deactivate kong
    idp->>idp: authenticate client <br/>and introspect access token
    activate kong
    idp->>kong: return introspection response
    deactivate idp
    kong->>kong: verify introspection response
    activate httpbin
    kong->>httpbin: request with <br/>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

#### JWT access token authentication flow

For legacy reasons, the stateless `JWT Access Token` authentication is named `bearer` (see [`config.auth_methods`](/plugins/openid-connect/reference/)). 
Stateless authentication means that the signature verification uses the identity provider to publish public keys and the standard claims verification (such as `exp` or expiry). 
The client may receive the token directly from the identity provider or by other means.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with<br>access token
    deactivate client
    kong->>kong: load access token
    kong->>kong: verify signature
    kong->>kong: verify claims
    activate httpbin
    kong->>httpbin: request with<br>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

#### Kong OAuth token auth flow

The OpenID Connect plugin can verify the tokens issued by the [OAuth 2.0 plugin](/plugins/oauth2/).
This is very similar to third party identity provider issued [JWT access token authentication](#jwt-access-token-authentication-flow) or [introspection authentication](#introspection-authentication-flow):

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with<br>access token
    deactivate client
    kong->>kong: load access token
    kong->>kong: verify kong<br>oauth token
    activate httpbin
    kong->>httpbin: request with<br>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

#### Refresh token grant workflow

The refresh token grant can be used when the client has a refresh token available. 
There is a caveat with this: in general, identity providers only allow the refresh token grant to be executed with the same client that originally got the refresh token, and if there is a mismatch, it may not work. 
The mismatch is likely when the OpenID Connect plugin is configured to use one client, and the refresh token is retrieved with another. 

The grant itself is very similar to the [password grant](#password-grant-workflow) and
the [client credentials grant](#client-credentials-grant-workflow):

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with<br>refresh token
    deactivate client
    kong->>kong: load refresh token
    activate idp
    kong->>idp: IdP/token with<br>client credentials and<br>refresh token
    deactivate kong
    idp->>idp: authenticate client and<br>verify refresh token
    activate kong
    idp->>kong: return tokens
    deactivate idp
    kong->>kong: verify tokens
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

#### Session authentication workflow

The OpenID Connect plugin can issue a session cookie that can be used for further session authentication. 
To make OpenID Connect issue a session cookie, you need to first authenticate with one of the other grants or flows that this plugin supports. 
For example, the [authorization code flow](#authorization-code-flow) demonstrates session authentication when it uses the redirect login action.

The session authentication portion of the flow works like this:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with<br>session cookie
    deactivate client
    kong->>kong: load session cookie
    kong->>kong: verify session
    activate httpbin
    kong->>httpbin: request with<br>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

#### User info authentication flow

The user info authentication uses OpenID Connect standard user info endpoint to verify the access token.
In most cases, you would use [introspection authentication](#introspection-authentication-flow) instead of user info, as introspection is meant for retrieving information from the token itself, whereas the user info endpoint is meant for retrieving information about the user to whom the token was given. 
The flow is almost identical to introspection authentication:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with<br>access token
    deactivate client
    kong->>kong: load access token
    activate idp
    kong->>idp: IdP/userinfo<br>with client credentials<br>and access token
    deactivate kong
    idp->>idp: authenticate client and<br>verify token
    activate kong
    idp->>kong: return user info <br>response
    deactivate idp
    kong->>kong: verify response<br>status code (200)
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

#### Password grant workflow

Password grant is a **legacy** authentication grant. 
This is a less secure way of authenticating end users than the authorization code flow, because, for example, the passwords are shared with third parties.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: service with<br>basic authentication
    deactivate client
    kong->>kong: load <br>basic authentication<br>credentials
    activate idp
    kong->>idp: IdP/token with<br>client credentials and<br>password grant
    deactivate kong
    idp->>idp: authenticate client and<br>verify password grant
    activate kong
    idp->>kong: return tokens
    deactivate idp
    kong->>kong: verify tokens
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

### Authorization

The OpenID Connect plugin has several options for performing coarse-grained authorization:

1. Claims-based authorization
2. ACL plugin authorization
3. Consumer authorization

#### Claims-based authorization

The following option pairs can be configured to manage claims verification during authorization:

1. `config.scopes_claim` and `config.scopes_required`
2. `config.audience_claim` and `config.audience_required`
3. `config.groups_claim` and `config.groups_required`
4. `config.roles_claim` and `config.roles_required`

For example, the first configuration option, `config.scopes_claim`, points to a source, from which the value is retrieved and checked against the value of the second configuration option, `config.scopes_required`.

#### ACL plugin authorization

The OpenID Connect plugin can be integrated with the [ACL plugin](/plugins/acl/), which provides access control functionality in the form of allow and deny lists.

You can also pair ACL-based authorization with Kong Consumer authorization.

#### Consumer authorization

You can use Kong [Consumers](/gateway/entities/consumer/) for authorization and dynamically map claim values to Consumers. 
This means that we restrict the access to only those that do have a matching Consumer. 
Consumers can have ACL groups attached to them and be further authorized with the [ACL plugin](/plugins/acl/).

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

See the [cert-bound configuration example](/plugins/openid-connect/examples/cert-bound-access-tokens/) for more detail.

### Demonstrating Proof-of-Possession (DPoP)

Demonstrating Proof-of-Possession (DPoP) is an alternative technique to the [mutual TLS certificate-bound access tokens](#mutual-tls-client-authentication). Unlike its alternative, which binds the token to the mTLS client certificate, it binds the token to a JSON Web Key (JWK) provided by the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant upstream as Upstream <br>(backend service,<br> e.g. httpbin)
    participant idp as Authentication Server <br>(e.g. Keycloak)
    activate client
    client->>client: generate key pair
    client->>idp: POST /oauth2/token<br>DPoP:$PROOF
    deactivate client
    activate idp
    idp-->>client: DPoP bound access token ($AT)
    activate client
    deactivate idp
    client->>kong: GET https://example.com/resource<br>Authorization: DPoP $AT<br>DPoP: $PROOF
    activate kong
    deactivate client
    kong->>kong: validate $AT and $PROOF
    kong->>upstream: proxied request <br> GET https://example.com/resource<br>Authorization: Bearer $AT
    deactivate kong
    activate upstream
    upstream-->>kong: upstream response
    deactivate upstream
    activate kong
    kong-->>client: response
    deactivate kong
{% endmermaid %}
<!--vale on-->

You can use the Demonstrating Proof-of-Possession option without mTLS, and even with plain HTTP, although HTTPS is recommended for enhanced security.

When verification of the DPoP proof is enabled, {{site.base_gateway}} removes the `DPoP` header and changes the token type from `dpop` to `bearer`.
This effectively downgrades the request to use a conventional bearer token, and allows an OAuth2 upstream without DPoP support to work with the DPoP token without losing the protection of the key binding mechanism.

DPoP is compatible with the following authentication methods:

* [JWT Access Token authentication](#jwt-access-token-authentication-flow)
* [Introspection authentication](#introspection-authentication-flow)
* [Session authentication](#session-authentication-workflow)

Session authentication is only compatible with DPoP when used along with one of the other supported authentication methods:
* If multiple `openid-connect` plugins are configured with the `session` authentication method, we strongly recommend configuring different values of [`config.session_secret`](/plugins/openid-connect/reference/#schema--config-session-secret) across plugin instances for additional security. This avoids sessions being shared across plugins and possibly bypassing the proof of possession validation.

To enable DPoP for OpenID Connect:
* Ensure that the auth server (IdP) that you're using has DPoP enabled.
* Use the [`config.proof_of_possession_dpop`](/plugins/openid-connect/reference/#schema--config-proof-of-possession-dpop) configuration option to ensure that the supplied access token is bound to the client by verifying its association with the JWT provided in the request.

See the [DPoP configuration example](/plugins/openid-connect/examples/dpop/) for more detail.

## Debugging the OIDC plugin

If you have issues with the OIDC plugin, try the following debugging methods:

1. Set the {{site.base_gateway}} [log level](/gateway/configuration/#log-level) to `debug`, and check the Kong `error.log`. 
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
