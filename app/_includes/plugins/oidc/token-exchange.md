The [OAuth 2.0 Token Exchange](https://oauth.net/2/token-exchange/) (RFC 8693) is an extension to the OAuth 2.0 framework that allows exchanging an existing security token for a new one. 
The RFC defines a protocol approach to support scenarios where a client can exchange a token for a new token by interacting with the authorization server. 
This is particularly useful in complex environments like microservices or cross-domain federations. 

{:.info}
> **Note**: Only access tokens can be exchanged with the OIDC {{ include.type }}.

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

In a typical OAuth flow, a token is obtained to access a resource. 
However, in a token exchange, a client already has a token (the "subject token"). 
{{ include.gateway }} decides which incoming tokens are eligible for exchange and facilitates the token exchange using its own client credentials. 
The subject token is presented to the authorization server to get a different token (the "requested token") that is better suited for accessing the resource.

{% include_cached /plugins/oidc/diagrams/token-exchange.md gateway_label=include.gateway_label %}

Before triggering the exchange, the OIDC {{ include.type }} performs the following checks on the incoming token:
1. Checks the incoming subject token meets the following criteria:
  * The issuer (`iss` claim) matches a configured trusted issuer (`subject_token_issuers`).
  * The token is not expired (`exp` claim).
  * The token is not used before its time (`nbf` claim).
  * {% new_in 3.15 %} If [`verify_signature`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-verify-signature" }}) is enabled for the issuer, {{ include.gateway }} cryptographically verifies the token signature before sending the exchange request to the IdP.
1. If the `subject_token_issuer` and `target_issuer` are different, token exchange is triggered.
1. If the `subject_token_issuer` and `target_issuer` are the same, the configured conditions are evaluated to determine whether to trigger token exchange.
1. {{ include.gateway }} uses its client credentials to trigger the exchange.

Afterwards, the OIDC {{ include.type }} continues processing the exchanged token through the rest of its flow.

Depending on the use case, {{ include.gateway }} can exchange the token either with the same authorization server that issued the initial subject token, or exchange tokens between different authorization servers.

{% unless include.hide_examples %}
Set up token exchange:
* [Example: Cross-domain token exchange](/plugins/openid-connect/examples/token-exchange-cross-domain/)
* [Example: Token transformation](/plugins/openid-connect/examples/token-exchange-transformation/)
* [Example: Token exchange with an actor token](/plugins/openid-connect/examples/token-exchange-actor-token/)
* [How-to: Configure OIDC with token exchange](/how-to/configure-oidc-with-token-exchange/)
{% endunless %}

#### Key terms

The token exchange flow uses the following terms:

* **Subject token**: The input token representing the identity/authorization being exchanged.
* **Subject token issuer**: The authorization server that issued the initial token (subject token).
* **Target issuer**: The authorization server protecting the resources (APIs/services).
* **Conditions**: Conditions under which to trigger token exchange. 
Conditions look for the presence or absence of two claims: `scopes` and `audience`. 

### Subject token signature verification {% new_in 3.15 %}

By default, {{ include.gateway }} validates the `iss`, `exp`, and `nbf` claims of an incoming subject token but doesn't verify its cryptographic signature before sending the exchange request to the IdP.
The IdP performs its own signature check, so validation happens eventually.

Enabling signature verification in {{ include.gateway }} adds an earlier check that rejects tokens with invalid signatures before they reach the IdP.
This reduces unnecessary round-trips to the IdP and keeps {{ include.gateway }}'s security posture consistent with other authentication flows.

You can configure this setting per issuer on each entry in [`config.token_exchange.subject_token_issuers`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers" }}):

* [`config.token_exchange.subject_token_issuers[].verify_signature`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-verify-signature" }}): Set to `true` to enable signature verification for that issuer.
Defaults to `false` for backward compatibility.
We recommend enabling this for all subject token issuers to prevent tokens with invalid signatures from consuming IdP resources.
* [`config.token_exchange.subject_token_issuers[].jwks_uri`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-jwks-uri" }}): An optional explicit JWKS endpoint for fetching the signing keys for this issuer.
If not set, {{ include.gateway }} resolves the JWKS URI from OIDC discovery using the issuer URL.
Set this when the issuer doesn't publish a discovery document or when you want to pin to a specific key endpoint.

### Actor tokens {% new_in 3.16 %}

An actor token represents the identity of the party acting on behalf of the subject in a token exchange, as defined by [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693#name-actor-token-and-actor-toke).
This is useful for delegation scenarios, such as an AI agent or backend service that needs to identify itself separately from the user (the subject) it's acting for.
Some identity providers require an actor token to be present for certain token exchange grants.

Configure [`config.token_exchange.request.actor_token`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-token-exchange-request-actor-token" }}) to include an actor token in the exchange request.

Use [`config.token_exchange.request.actor_token.type`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-token-exchange-request-actor-token-type" }}) to set the token type identifier sent as `actor_token_type`.
This defaults to `urn:ietf:params:oauth:token-type:access_token`.

{% unless include.hide_examples %}
See the [actor token example](/plugins/openid-connect/examples/token-exchange-actor-token/) for more details.
{% endunless %}
