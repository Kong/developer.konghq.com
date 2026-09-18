One of the main vulnerabilities of OAuth is bearer tokens.
With OAuth, presenting a valid bearer token is enough proof to access a resource.
This can create problems, since the client presenting the token isn't validated as the legitimate user the token was issued to.

Certificate-bound access tokens solve this problem by binding tokens to clients.
This ensures the legitimacy of the token, because it requires proof that the sender is authorized to use a particular token to access protected resources.

Certificate-bound access tokens are supported by the following auth methods:

* [JWT access token authentication]({{ include.jwt_flow_anchor | default: "#jwt-access-token-authentication-flow" }})
* [Introspection authentication]({{ include.introspection_flow_anchor | default: "#introspection-authentication-flow" }})
* [Session authentication]({{ include.session_flow_anchor | default: "#session-authentication-workflow" }})

Session authentication is only compatible with certificate-bound access tokens when used along with one of the other supported authentication methods:

* When [`config.proof_of_possession_auth_methods_validation`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-proof-of-possession-auth-methods-validation" }}) is set to `false` and other non-compatible methods are enabled, and a valid session is found, {{ include.gateway }} only performs the proof of possession validation if the session was originally created using one of the compatible methods.
* If you configure multiple OpenID Connect {{ include.type }} instances with the `session` auth method, configure a different [`config.session_secret`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-session-secret" }}) value on each for additional security. This avoids sessions being shared across {{ include.type }} instances and possibly bypassing the proof of possession validation.

To enable certificate-bound access tokens:
* Ensure that the IdP you're using is set up to generate OAuth 2.0 mutual TLS certificate-bound access tokens.
* Use [`config.proof_of_possession_mtls`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-proof-of-possession-mtls" }}) to verify that the supplied access token belongs to the client, by checking its binding with the client certificate provided in the request.

{% unless include.hide_examples %}
See the [cert-bound configuration example](/plugins/openid-connect/examples/cert-bound-access-tokens/) for more detail and [Configure OpenID Connect with cert-bound access tokens](/how-to/configure-oidc-with-cert-bound-tokens/) for a complete tutorial.
{% endunless %}
