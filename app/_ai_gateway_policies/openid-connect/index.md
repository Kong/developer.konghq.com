---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
description: Integrate {{site.ai_gateway_name}} with a third-party OpenID Connect provider
---
The OpenID Connect (OIDC) Policy lets you integrate {{site.ai_gateway}} with an identity provider (IdP). To make it work with {{site.ai_gateway}}, you don't attach it directly to an {{site.ai_gateway}}. Instead you reference it in your [AI Identity Provider](/ai-gateway/ai-identity-provider/) entity configuration. The resulting configuration is whas we call OpenID Connect (OIDC) Policy in this page.

You can use this Policy to implement {{site.ai_gateway}} as a proxying [OAuth 2.0](https://tools.ietf.org/html/rfc6749) resource server 
(RS) and as an OpenID Connect relying party (RP) between the client and the upstream service.

## What does OpenID Connect do?

OpenID Connect provides a way to form a **federation** with **identity providers (IdPs)**. 
Identity providers are third parties that store account credentials. 
If an identity provider authenticates a user to an application, the application trusts that provider and allows access to the user. This shifts the responsibility of authentication from the application to the identity provider. {{site.konnect_short_name}} provides [{{site.identity}}](/identity/), a managed {{site.ai_gateway}} native IdP provider.

Besides delegating responsibility to an identity provider, OpenID Connect also makes single sign-on possible without storing any credentials on a user’s local machine.

## What does Kong’s OpenID Connect Policy do?

The OpenID Connect Policy enables you to integrate OpenID Connect with {{site.ai_gateway}} without having to write custom integrations.
Instead of manually writing code for OpenID Connect within an upstream service, you can place {{site.ai_gateway}} in front of the upstream service and have {{site.ai_gateway}} handle authentication.
This separation lets developers focus on the business logic within their application, easily swap out upstream services while preserving authentication at the front door, and effortlessly spread the same authentication to new upstream services.

Unlike other authentication types like Key Auth and Basic Auth, with OpenID Connect you don't need to manage user credentials directly. 
Instead, you can offload the task to a trusted identity provider of your choice.

## Discovery cache
When you configure `config.issuer` in the OIDC Policy, {{site.ai_gateway}} automatically retrieves the provider’s discovery metadata. The OIDC Policy stores the metadata as a discovery cache object and uses the cache avoid repeated fetches. This cache includes the discovery document endpoints, JWKS keys, and the token endpoint. 

{{site.ai_gateway}} uses the discovery cache whenever validation needs issuer metadata. The cache behaves in the following way:
- Discovery data is stored in the **{{site.ai_gateway}} database**.  
- The cache TTL (time-to-live) is managed by `config.cache_ttl`, which is set to 3600 seconds by default.
- If a request requires discovery information that isn't in the cache, the Policy attempts to “rediscover” it using the value in `config.issuer`. After a rediscovery occurs, no further rediscovery attempts are made until the time period defined in `config.rediscovery_lifetime` has elapsed, which helps avoid excessive requests to the identity provider.  
- If a JWT can't be validated due to missing discovery data, and a rediscovery request returns a non‑2xx status code, the Policy falls back to using any sufficient discovery information that remains in the cache.

## Supported flows and grants

The OpenID Connect Policy suits many different use cases and extends other Policies 
such as [JWT](/ai-gateway/policies/jwt/) (JSON Web Token), [ACL](/ai-gateway/policies/acl/), and [0Auth 2.0](/ai-gateway/policies/oauth2/).
The most common use case is the [authorization code flow](#authorization-code-flow).

### Authentication flows and grants

The OIDC Policy supports several types of credentials and grants.

You can configure multiple auth grants or flows on the Policy.
The Policy searches for credentials in the following order of precedence:

1. [Session authentication](#session-authentication-workflow)
2. [JWT access token authentication](#jwt-access-token-authentication-flow)
3. [Kong OAuth token authentication](#kong-oauth-token-authentication-flow)
4. [Introspection authentication](#introspection-authentication-flow)
5. [User info authentication](#user-info-authentication-flow)
6. [Refresh token grant](#refresh-token-grant-workflow)
7. [Password grant](#password-grant-workflow) (username and password)
8. [Client credentials grant](#client-credentials-grant-workflow)
9. [Authorization code flow](#authorization-code-flow) (with client secret or PKCE)

Once it finds a set of credentials, the Policy stops searching, and won't look for any further credential types.
This precedence order is hardcoded and can't be changed.

Multiple grants may share the same credentials. For example, both the password and client credentials grants can use 
basic authentication through the `Authorization` header.

#### Session authentication workflow

The OpenID Connect Policy can issue a session cookie that can be used for further session authentication. 
To make OpenID Connect issue a session cookie, you need to first authenticate with one of the other grants or flows that this Policy supports. 
For example, the [authorization code flow](#authorization-code-flow) demonstrates session authentication when it uses the redirect login action.

#### JWT access token authentication flow

For legacy reasons, the stateless `JWT Access Token` authentication is named `bearer` (see [`config.auth_methods`](/ai-gateway/policies/openid-connect/reference/#schema--config-auth-methods)). 
Stateless authentication means that the signature verification uses the identity provider to publish public keys and the standard claims verification (such as `exp` or expiry).

Set up JWT access token auth:
* [JWT access token auth tutorial with Keycloak](/how-to/configure-oidc-with-jwt-auth/)

#### Kong OAuth token authentication flow

The OpenID Connect Policy can verify the tokens issued by the [OAuth 2.0 Policy](/ai-gateway/policies/oauth2/).
This is very similar to third party identity provider issued [JWT access token authentication](#jwt-access-token-authentication-flow) or [introspection authentication](#introspection-authentication-flow).

Set up Kong OAuth2 token auth:
* [Kong OAuth token tutorial with Keycloak](/how-to/configure-oidc-with-kong-oauth2/)

#### Introspection authentication flow

As with [JWT access token authentication](#jwt-access-token-authentication-flow), 
the introspection authentication relies on a bearer token that the client has already gotten from somewhere. 
The difference between introspection and stateless JWT authentication is that the Policy needs to call the introspection endpoint of the identity provider to find out whether the token is valid and active. 
This makes it possible to issue opaque tokens to the clients.

Set up introspection auth:
* [Introspection auth tutorial with Keycloak](/how-to/configure-oidc-with-introspection/)

#### User info authentication flow

The user info authentication uses OpenID Connect standard user info endpoint to verify the access token.
In most cases, you would use [introspection authentication](#introspection-authentication-flow) instead of user info, as introspection is meant for retrieving information from the token itself, whereas the user info endpoint is meant for retrieving information about the user to whom the token was given. 
The flow is almost identical to introspection authentication.

Set up user info auth:
* [User info auth tutorial with Keycloak](/how-to/configure-oidc-with-user-info-auth/)

#### Refresh token grant workflow

The refresh token grant can be used when the client has a refresh token available. 
There is a caveat with this: in general, identity providers only allow the refresh token grant to be executed with the same client that originally got the refresh token, and if there is a mismatch, it may not work. 
The mismatch is likely when the OpenID Connect Policy is configured to use one client, and the refresh token is retrieved with another. 

The grant itself is very similar to the [password grant](#password-grant-workflow) and
the [client credentials grant](#client-credentials-grant-workflow).

Set up refresh token auth:
* [Refresh token auth tutorial with Keycloak](/how-to/configure-oidc-with-refresh-token/)

#### Password grant workflow

Password grant is a **legacy** authentication grant. 
This is a less secure way of authenticating end users than the authorization code flow, because, for example, the passwords are shared with third parties.

Set up password grant auth:
* [Password grant tutorial with Keycloak](/how-to/configure-oidc-with-password-grant/)

#### Client credentials grant workflow

The client credentials grant is very similar to the [password grant](#password-grant-workflow).
The most important difference is that the Policy itself doesn't try to authenticate, and instead 
forwards the credentials passed by the client to the identity server's token endpoint.

Set up client credentials grant auth:
* [Client credentials grant tutorial with Keycloak](/how-to/configure-oidc-with-client-credentials/)

#### Authorization code flow

{:.info}
> If using PKCE, the identity provider *must* contain the `code_challenge_methods_supported` object 
in the `/.well-known/openid-configuration` issuer discovery endpoint response, as required by 
[RFC 8414](https://www.rfc-editor.org/rfc/rfc8414.html).
If it's not included, the PKCE `code_challenge` query parameter won't be sent.

Set up the auth code flow:
* [Authorization code tutorial with Keycloak](/how-to/configure-oidc-with-auth-code-flow/)
* [Configure OpenID Connect with the authorization code flow and Okta](/how-to/configure-oidc-with-auth-code-flow-and-okta/)

### Authorization

The OpenID Connect Policy has several options for performing coarse-grained authorization:

1. [Claims-based authorization](#claims-based-authorization)
2. [ACL Policy authorization](#acl-policy-authorization)
3. [AI Consumer authorization](#ai-consumer-authorization)
4. [AI Consumer Group authorization](#ai-consumer-group-authorization)

#### Claims-based authorization

Claims-based authorization uses a pair of options to manage claims verification during authorization.
The pair can be any of:

1. [`config.scopes_claim`](/ai-gateway/policies/openid-connect/reference/#schema--config-scopes-claim) and 
[`config.scopes_required`](/ai-gateway/policies/openid-connect/reference/#schema--config-scopes-required)
2. [`config.audience_claim`](/ai-gateway/policies/openid-connect/reference/#schema--config-audience-claim) and 
[`config.audience_required`](/ai-gateway/policies/openid-connect/reference/#schema--config-audience-required)
3. [`config.groups_claim`](/ai-gateway/policies/openid-connect/reference/#schema--config-groups-claim) and 
[`config.groups_required`](/ai-gateway/policies/openid-connect/reference/#schema--config-groups-required)
4. [`config.roles_claim`](/ai-gateway/policies/openid-connect/reference/#schema--config-roles-claim) and 
[`config.roles_required`](/ai-gateway/policies/openid-connect/reference/#schema--config-roles-required)

In each parameter pair, the `*_claim` parameter points to a source, and the `*_required` parameter defines a set of claims values to check against.

Claims-based auth adheres to the following rules:
* You can validate a maximum of 4 claims at the same time
* You can [traverse an array or object for the claim name](#claim-type)
* You can validate multiple values of the same claim [using `OR` and `AND` logic](#claim-requirements)

Both the claim type and the required claim content take an array of string elements.

Set up claims-based auth:
* [Claims-based auth tutorial with Keycloak](/how-to/configure-oidc-with-claims-based-auth/)

##### Claim type

For the claim type (for example, `config.groups_claim`), the array is a list of JSON objects listed in nested order. 
The Policy uses the order of the items in the array to look up data in a JSON payload.

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

* `OR`: Values in separate array indices

  This claim has to have either `employee` OR `marketing`:

  ```yaml
  config:
    groups_required:
    - employee
    - marketing
  ```

#### ACL Policy authorization

The OpenID Connect Policy can be integrated with the [ACL Policy](/ai-gateway/policies/acl/), which provides access control functionality in the form of allow and deny lists.

You can also pair ACL-based authorization with AI Consumer authorization.

Set up ACL auth:
* [ACL auth tutorial with Keycloak](/how-to/configure-oidc-with-acl-auth/)

#### AI Consumer authorization

You can use [AI Consumers](/ai-gateway/entities/ai-consumer/) for authorization and dynamically map claim values to AI Consumers. 
This means that we restrict the access to only those that do have a matching AI Consumer. 
AI Consumers can have ACL groups attached to them and be further authorized with the [ACL Policy](/ai-gateway/policies/acl/).

Set up AI Consumer auth:
* [AI Consumer auth tutorial with Keycloak](/how-to/configure-oidc-with-consumers/)

#### AI Consumer Group authorization

You can use [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) for authorization and dynamically map claim values to AI Consumer Groups. 
This means that we restrict the access to only those that do have a matching AI Consumer Group. 

Set up AI Consumer Group auth:
* [AI Consumer Group auth tutorial with Keycloak](/how-to/configure-oidc-with-consumer-groups/)

### Client authentication

#### Mutual TLS client authentication

The OpenID Connect Policy supports mutual TLS (mTLS) client authentication with the IdP. 
When mTLS authentication is enabled, {{site.ai_gateway}} establishes mTLS connections with the IdP using the configured client certificate.
You can use mTLS client authentication with the following IdP endpoints and corresponding flows:

* `token`
  * [Authorization Code Flow](#authorization-code-flow)
  * [Password Grant](#password-grant-workflow)
  * [Refresh Token Grant](#refresh-token-grant-workflow)
* `introspection`
  * [Introspection Authentication flow](#introspection-authentication-flow)
* `revocation`
  * [Session Authentication](#session-authentication-workflow)

For all these endpoints and for the flows supported, the Policy uses mTLS client authentication as the authentication method when communicating with the IdP, for example, to fetch the token from the token endpoint.

## Financial-grade API (FAPI)

The OpenID Connect Policy supports various features of the FAPI standard, aimed to protect APIs that expose high-value and sensitive data.

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
      With PAR enabled, {{site.ai_gateway}} (as the OAuth client) sends the payload of an authorization request to the IdP. 
      As a result, it obtains a `request_uri` value. 
      The client uses this value in a call to the authorization endpoint as a reference to obtain the authorization request payload data.
      <br><br>
      Use [`config.pushed_authorization_request_endpoint`](./reference/#schema--config-pushed-authorization-request-endpoint) to enable PAR.
    example: --
  - spec: "JWT-secured authorization requests (JAR)"
    description:
      With JAR enabled, when sending requests to the authorization endpoint, {{site.ai_gateway}} provides request parameters in a JSON Web Token (JWT) instead of using a query string. 
      This allows for request data to be signed with JSON Web Signature (JWS).
      <br><br>
      Use [`config.require_signed_request_object`](./reference/#schema--config-require-signed-request-object) to enable JAR.
    example: --
  - spec: "JWT-secured authorization response mode (JARM)"
    description: |
      With JARM enabled, {{site.ai_gateway}} requests the authorization server to return the authorization response parameters encoded in a JWT, which allows the response data to be signed with JSON Web Signature (JWS).
      <br><br>
      Set [`config.response_mode`](./reference/#schema--config-response-mode) to any of the following values: `query.jwt`, `form_post.jwt`, `fragment.jwt`, `jwt` to enable JARM.
    example: --
  - spec: "Certificate-bound access tokens"
    description: |
      Certificate-bound access tokens allow binding tokens to clients. 
      This guarantees the authenticity of the token by verifying whether the sender is authorized to use the token for accessing protected resources.
      <br><br>
      Set [`config.proof_of_possession_mtls`](./reference/#schema--config-proof-of-possession-mtls) to `strict` and [`config.client_id`](./reference/#schema--config-client-id) to `cert-bound` to enable cert-bound access tokens.

  - spec: "Mutual TLS (mTLS) client authentication with certificate-bound access tokens"
    description: |
      When mTLS client authentication is enabled, {{site.ai_gateway}} establishes mTLS connections with the IdP using the configured X.509 certificate as client credentials.
      <br><br>
      If the authorization server is configured to bind the client certificate with the issued access token, {{site.ai_gateway}} can validate the access token using mTLS proof of possession.
      <br><br>
      Set [`config.client_auth`](./reference/#schema--config-client-auth) to `tls_client_auth` and provide a certificate at [`config.tls_client_auth_cert_id`](./reference/#schema--config-tls-client-auth-cert-id) to enable mTLS auth.
  - spec: "Demonstrating proof-of-possession (DPoP)"
    description: |
      Demonstrating Proof of Possession (DPoP) is an application-level mechanism for proving the sender's ownership of OAuth access and refresh tokens.
      With DPoP, a client can prove the possession of a public/private key pair associated with a token by using a header.
      The header contains a signed JWT that includes a reference to the associated access token.
      <br><br>
      When DPoP is enabled, {{site.ai_gateway}} validates the DPoP header in the request to ensure that the sender is authorized to use the access token.
      <br><br>
      Set [`config.proof_of_possession_dpop`](./reference/#schema--config-proof-of-possession-dpop) to `strict` to enable DPoP.
  - spec: | 
      mTLS Proof-of-Possession via HTTP header
    description: |
      In enterprise deployments where TLS is terminated at a WAF or load balancer before {{site.ai_gateway}},
      the downstream connection carries no client certificate.
      <br><br>
      {{site.ai_gateway}} can read the certificate from an HTTP header injected by the WAF or proxy and validate its thumbprint against the `cnf.x5t#S256` claim bound in the access token.
      <br><br>
      Set [`config.proof_of_possession_mtls`](./reference/#schema--config-proof-of-possession-mtls) to `strict` and configure [`config.proof_of_possession_mtls_from_header`](./reference/#schema--config-proof-of-possession-mtls-from-header) with the header name and a trusted CA certificate.
    example: |
      [How-to: Configure OpenID Connect with mTLS Proof-of-Possession via header](/how-to/configure-oidc-with-pop-token-in-header/)
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

* When the configuration option [`config.proof_of_possession_auth_methods_validation`](/ai-gateway/policies/openid-connect/reference/#schema--config-proof-of-possession-auth-methods-validation) is set to `false` and other non-compatible methods are enabled, if a valid session is found, the proof of possession validation will only be performed if the session was originally created using one of the compatible methods. 
* If multiple `openid-connect` policies are configured with the `session` auth method, we strongly recommend configuring different values of [`config.session_secret`](/ai-gateway/policies/openid-connect/reference/#schema--config-session-secret) across policy instances for additional security. This avoids sessions being shared across policies and possibly bypassing the proof of possession validation.

To enable certificate-bound access for OpenID Connect:
* Ensure that the auth server (IdP) that you're using is set up to generate OAuth 2.0 Mutual TLS certificate-bound access tokens.
* Use the [`proof_of_possession_mtls`](/ai-gateway/policies/openid-connect/reference/#schema--config-proof-of-possession-mtls) configuration option to ensure that the supplied access token belongs to the client by verifying its binding with the client certificate provided in the request.

[Configure OpenID Connect with cert-bound access tokens](/how-to/configure-oidc-with-cert-bound-tokens/) for a complete tutorial.

### mTLS Proof-of-Possession via HTTP header

Many enterprise deployments terminate TLS at a WAF or Layer-7 proxy before traffic reaches {{site.ai_gateway}}.
In these environments, the TLS connection between the proxy and {{site.ai_gateway}} carries no client certificate, which prevents the standard mTLS PoP flow from working.

You can enable the OIDC Policy to validate mTLS Proof-of-Possession (PoP) via a header.
When configured, the Policy reads the client certificate from an HTTP header injected by the WAF or proxy, validates it against a trusted CA, and verifies that its thumbprint matches the `cnf.x5t#S256` claim bound in the access token.

To enable mTLS PoP via header:
* Configure your IdP to generate OAuth 2.0 mTLS certificate-bound access tokens.
* Configure your WAF or L7 proxy to inject the client certificate into a known HTTP header.
* Set [`config.proof_of_possession_mtls`](/ai-gateway/policies/openid-connect/reference/#schema--config-proof-of-possession-mtls) to `strict` and configure [`config.proof_of_possession_mtls_from_header`](/ai-gateway/policies/openid-connect/reference/#schema--config-proof-of-possession-mtls-from-header) with the header name, expected certificate format, and a trusted CA certificate.

See [Configure OpenID Connect with mTLS Proof-of-Possession via header](/how-to/configure-oidc-with-pop-token-in-header/) for a complete tutorial.

### Demonstrating Proof-of-Possession (DPoP)

Demonstrating Proof-of-Possession (DPoP) is an alternative technique to the [mutual TLS certificate-bound access tokens](#mutual-tls-client-authentication). Unlike its alternative, which binds the token to the mTLS client certificate, it binds the token to a JSON Web Key (JWK) provided by the client.

You can use the Demonstrating Proof-of-Possession option without mTLS, and even with plain HTTP, although HTTPS is recommended for enhanced security.

When verification of the DPoP proof is enabled, {{site.ai_gateway}} removes the `DPoP` header and changes the token type from `dpop` to `bearer`.
This effectively downgrades the request to use a conventional bearer token, and allows an OAuth2 upstream without DPoP support to work with the DPoP token without losing the protection of the key binding mechanism.

DPoP is compatible with the following authentication methods:

* [JWT Access Token authentication](#jwt-access-token-authentication-flow)
* [Introspection authentication](#introspection-authentication-flow)
* [Session authentication](#session-authentication-workflow)

Session authentication is only compatible with DPoP when used along with one of the other supported authentication methods. If multiple `openid-connect` policies are configured with the `session` authentication method, we strongly recommend configuring different values of [`config.session_secret`](/ai-gateway/policies/openid-connect/reference/#schema--config-session-secret) across policy instances for additional security. This avoids sessions being shared across policies and possibly bypassing the proof of possession validation.

To enable DPoP for OpenID Connect:
* Ensure that the auth server (IdP) that you're using has DPoP enabled.
* Use the [`config.proof_of_possession_dpop`](/ai-gateway/policies/openid-connect/reference/#schema--config-proof-of-possession-dpop) configuration option to ensure that the supplied access token is bound to the client by verifying its association with the JWT provided in the request.

## Multi-IdP support

If your APIs serve clients that authenticate with different identity providers, the OIDC Policy can validate tokens from multiple issuers at the gateway layer, so backends don't need per-IdP logic.

You can implement this in one of the following ways:

* **Trusted issuers registry**: Configure the OIDC Policy with a list of trusted issuers and their JWKS endpoints using [`config.issuers_allowed`](/ai-gateway/policies/openid-connect/reference/#schema--config-issuers-allowed) and [`config.extra_jwks_uris`](/ai-gateway/policies/openid-connect/reference/#schema--config-extra-jwks-uris).
{{site.ai_gateway}} validates incoming tokens against the appropriate public keys and forwards them to the backend as-is.
This works best when token formats are consistent across IdPs.

* **Token exchange**: Configure the OIDC Policy to swap incoming tokens for a canonical token from one trusted issuer using [`config.token_exchange`](/ai-gateway/policies/openid-connect/reference/#schema--config-token-exchange).
The backend always receives tokens from a single issuer regardless of which IdP the client used.
This works best when backends must trust one issuer, or when you need to normalize scopes and claims across IdPs.

For a detailed comparison, configuration parameters, and examples, see [Multi-IdP token validation at the gateway layer](/ai-gateway/policies/openid-connect/multi-idp/).

## Token exchange

The [OAuth 2.0 Token Exchange](https://oauth.net/2/token-exchange/) (RFC 8693) is an extension to the OAuth 2.0 framework that allows exchanging an existing security token for a new one. 
The RFC defines a protocol approach to support scenarios where a client can exchange a token for a new token by interacting with the authorization server. 
This is particularly useful in complex environments like microservices or cross-domain federations. 

{:.info}
> **Note**: The OpenID Connect Policy only supports exchanging access tokens.

### Why use token exchange?

Token exchange can be used in several critical use cases:

* **Downscoping**: A service receives a powerful token but only needs a subset of those permissions to call an upstream service. 
It exchanges the powerful token for one with fewer scopes to maintain the Principle of Least Privilege.
* **Internal vs. external tokens**: Converting an external opaque token or a third-party token (like a SAML assertion) into an internal JWT that the microservices understand.
* **Impersonation and delegation**: Allowing a service to act on behalf of a user. 
For example, a frontend service needs to trade its token for a new token with specific scopes to call a backend service.
* **Privacy**: Removing sensitive user information from a token before passing it to an upstream service.

{:.info}
> Because token exchange allows for the creation of new tokens, trust models are vital. 
The trust model must strictly define which clients are allowed to exchange tokens and which scopes they are permitted to elevate or downgrade to prevent security flaws like privilege escalations.

### How token exchange works

In a typical [OAuth flow](#kong-oauth-token-authentication-flow), a token is obtained to access a resource. 
However, in a token exchange, a client already has a token (the "subject token"). 
{{site.ai_gateway}} acts as the gatekeeper that decides which incoming tokens are eligible for exchange and facilitates the token exchange using its own client credentials. 
The subject token is presented to the authorization server to get a different token (the "requested token") that is better suited for accessing the resource.

The OpenID Connect Policy performs the following checks on the incoming token before triggering the exchange:
1. Checks the incoming subject token meets the following criteria:
  * The issuer (`iss` claim) matches a configured trusted issuer (`subject_token_issuers`).
  * The token is not expired (`exp` claim).
  * The token is not used before its time (`nbf` claim).
  * If [`verify_signature`](/ai-gateway/policies/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-verify-signature) is enabled for the issuer, {{site.ai_gateway}} cryptographically verifies the token signature before sending the exchange request to the IdP.
1. If the `subject_token_issuer` and `target_issuer` are different, token exchange is triggered.
1. If the `subject_token_issuer` and `target_issuer` are the same, the configured conditions are evaluated to determine whether to trigger token exchange.
1. {{site.ai_gateway}} uses its client credentials to trigger the exchange.

Afterwards, the rest of the OpenID Connect Policy flow continues on the exchanged token.

Depending on the use case, {{site.ai_gateway}} can exchange the token either with the same authorization server that issued the initial subject token, or exchange tokens between different authorization servers.

Set up token exchange:
* [How-to: Configure OIDC with token exchange](/how-to/configure-oidc-with-token-exchange/)

#### Key terms

The token exchange flow uses the following terms:

* **Subject token**: The input token representing the identity/authorization being exchanged.
* **Subject token issuer**: The authorization server that issued the initial token (subject token).
* **Target issuer**: The authorization server protecting the resources (APIs/services).
* **Conditions**: Conditions under which to trigger token exchange. 
Conditions look for the presence or absence of two claims: `scopes` and `audience`. 

### Subject token signature verification

By default, {{site.ai_gateway}} validates the `iss`, `exp`, and `nbf` claims of an incoming subject token but doesn't verify its cryptographic signature before sending the exchange request to the IdP.
The IdP performs its own signature check, so validation happens eventually.

Enabling signature verification in {{site.ai_gateway}} adds an earlier check that rejects tokens with invalid signatures before they reach the IdP.
This reduces unnecessary round-trips to the IdP and keeps {{site.ai_gateway}}'s security posture consistent with other authentication flows.

You can configure this setting per issuer on each entry in [`config.token_exchange.subject_token_issuers`](/ai-gateway/policies/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers):

* [`config.token_exchange.subject_token_issuers[].verify_signature`](/ai-gateway/policies/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-verify-signature): Set to `true` to enable signature verification for that issuer.
Defaults to `false` for backward compatibility.
We recommend enabling this for all subject token issuers to prevent tokens with invalid signatures from consuming IdP resources.
* [`config.token_exchange.subject_token_issuers[].jwks_uri`](/ai-gateway/policies/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-jwks-uri): An optional explicit JWKS endpoint for fetching the signing keys for this issuer.
If not set, {{site.ai_gateway}} resolves the JWKS URI from OIDC discovery using the issuer URL.
Set this when the issuer doesn't publish a discovery document or when you want to pin to a specific key endpoint.

## Multiple clients

You can configure the OIDC Policy with multiple client IDs ([`config.client_id`](./reference/#schema--config-client-id)) and 
client secrets ([`config.client_secret`](./reference/#schema--config-client-secret)), where the ID and client pairs correspond based on their locations in the array.

For example:

```yaml
config:
  issuer: example-issuer-url
  client_id:
    - my-first-client
    - my-second-client
  client_secret:
    - first-client-secret
    - second-client-secret
```

When making a request, you can specify which client to target to use by including a client ID argument.
For example, after configuring the Policy with two client IDs and client secrets, you can target a client by name:

```sh
curl -X GET "http://localhost:8000?client_id=my-second-client"
```

Or by its index value (starting with 1):

```sh
curl -X GET "http://localhost:8000?client_id=2"
```

{{site.ai_gateway}} will look for the client ID in the following locations, in order of precedence:
1. If [`config.client_arg`](./reference/#schema--config-client-arg) is set, {{site.ai_gateway}} checks for that value in the following order: in the request header, URI argument, and body.
1. If `config.client_arg` is not set, {{site.ai_gateway}} checks for a `client_id` in the following order: in the request header, URI argument, and body.
1. If no client is found in either of those places, {{site.ai_gateway}} uses the first client ID and client secret pair.

{:.info}
> **Note:** Configuring multiple clients is not possible with the client credentials grant, as the Policy always uses the client ID passed directly from the client.

## Using cloud authentication with Redis

{% include_cached /md/ai-gateway/v2/redis-cloud-auth.md %}

{% include_cached /md/ai-gateway/v2/redis-cloud-providers.md %}

## Debugging the OIDC Policy

If you have issues with the OIDC Policy, try the following debugging methods:

1. Check the {{site.ai_gateway}} [log level](/ai-gateway/configuration/#log-level) to `debug`, and check the {{site.ai_gateway}} `error.log`. 
You can filter the log with the keyword `openid-connect`.

2. Set the OpenID Connect Policy to display errors by setting [`config.display_errors`](./reference/#schema--config-display-errors) to true.

3. Temporarily disable the OpenID Connect Policy verifications by setting the following parameters to `false`:
  * [`config.verify_nonce`](./reference/#schema--config-verify-nonce)
  * [`config.verify_claims`](./reference/#schema--config-verify-claims)
  * [`config.verify_signature`](./reference/#schema--config-verify-signature)

4. Check what kinds of tokens the OpenID Connect Policy can receive by reviewing the following parameter configurations, and ensure that your token type is allowed:
  * [`config.login_action`](./reference/#schema--config-login-action)
  * [`config.login_tokens`](./reference/#schema--config-login-tokens)
  * [`config.login_methods`](./reference/#schema--config-login-methods)

5. Session-related issues are often caused by large cookies. Try storing the session data in `Redis` or `memcache`, as that will make the session cookie much smaller. Set this up using [`config.session_storage`](./reference/#schema--config-session-storage).

6. Try to eliminate indirection in the form of other gateways, load balancers, NATs, and so on, in front of {{site.ai_gateway}}, as that makes it easier to find out where the problem is. 
If one of these other applications is causing issues, looking into using the following:
  * [Port maps](/ai-gateway/configuration/#port-maps)
  * [`X-Forwarded-*` headers](/ai-gateway/configuration/#trusted-ips)

## Supported identity providers

The Policy has been tested with several OpenID Connect providers:

- [Kong Identity](/identity/)
- [Auth0](https://auth0.com/docs/protocols/openid-connect-protocol)
- [{{ site.amazon }} AWS Cognito](https://aws.amazon.com/cognito/dev-resources/)
- [Connect2id](https://connect2id.com/products/server)
- [Curity](https://curity.io/resources/learn/openid-connect-overview/)
- [Dex](https://dexidp.io/docs/openid-connect/)
- [Gluu](https://docs-4.gluu.org/gluu-server/admin-guide/openid-connect/)
- [{{ site.google}}](https://developers.google.com/identity/protocols/oauth2/openid-connect)
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

As long as your provider supports OpenID Connect standards, the Policy should
work, even if it is not specifically tested against it.