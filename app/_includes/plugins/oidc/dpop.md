Demonstrating Proof-of-Possession (DPoP) is an alternative technique to [mutual TLS client authentication with certificate-bound access tokens]({{ include.mtls_client_auth_anchor | default: "#mutual-tls-client-authentication" }}). Unlike mTLS, which binds the token to the mTLS client certificate, DPoP binds the token to a JSON Web Key (JWK) provided by the client.

{% include_cached plugins/oidc/diagrams/dpop.md %}

You can use DPoP without mTLS, and even with plain HTTP, although HTTPS is recommended for enhanced security.

When verification of the DPoP proof is enabled, {{ include.gateway }} removes the `DPoP` header and changes the token type from `dpop` to `bearer`.
This effectively downgrades the request to use a conventional bearer token, and lets an upstream without DPoP support work with the DPoP token without losing the protection of the key binding mechanism.

DPoP is compatible with the following authentication methods:

* [JWT access token authentication]({{ include.jwt_flow_anchor | default: "#jwt-access-token-authentication-flow" }})
* [Introspection authentication]({{ include.introspection_flow_anchor | default: "#introspection-authentication-flow" }})
* [Session authentication]({{ include.session_flow_anchor | default: "#session-authentication-workflow" }})

Session authentication is only compatible with DPoP when used along with one of the other supported authentication methods. If you configure multiple OpenID Connect {{ include.type }} instances with the `session` authentication method, configure a different [`config.session_secret`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-session-secret" }}) value on each for additional security. This avoids sessions being shared across {{ include.type }} instances and possibly bypassing the proof of possession validation.

To enable DPoP:
* Ensure that the IdP you're using has DPoP enabled.
* Use [`config.proof_of_possession_dpop`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-proof-of-possession-dpop" }}) to verify that the supplied access token is bound to the client, by checking its association with the JWT provided in the request.

{% unless include.hide_examples %}
See the [DPoP configuration example](/plugins/openid-connect/examples/dpop/) for more detail.
{% endunless %}
