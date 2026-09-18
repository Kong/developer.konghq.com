If your APIs serve clients that authenticate with different identity providers, the OIDC {{ include.type }} can validate tokens from multiple issuers at the gateway layer, so backends don't need per-IdP logic.

You can implement this in one of the following ways:

* **Trusted issuers registry**: Configure the OIDC {{ include.type }} with a list of trusted issuers and their JWKS endpoints using [`config.issuers_allowed`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-issuers-allowed" }}) and [`config.extra_jwks_uris`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-extra-jwks-uris" }}).
{{ include.gateway }} validates incoming tokens against the appropriate public keys and forwards them to the backend as-is.
This works best when token formats are consistent across IdPs.

* **Token exchange** {% new_in 3.14 %}: Configure the OIDC {{ include.type }} to swap incoming tokens for a canonical token from one trusted issuer using [`config.token_exchange`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-token-exchange" }}).
The backend always receives tokens from a single issuer regardless of which IdP the client used.
This works best when backends must trust one issuer, or when you need to normalize scopes and claims across IdPs.

{% unless include.hide_examples %}
For a detailed comparison, configuration parameters, and examples, see [Multi-IdP token validation at the gateway layer](/plugins/openid-connect/multi-idp/).
{% endunless %}
