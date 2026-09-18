Many enterprise deployments terminate TLS at a WAF or Layer-7 proxy before traffic reaches {{ include.gateway }}.
In these environments, the TLS connection between the proxy and {{ include.gateway }} carries no client certificate, which prevents the standard mTLS proof-of-possession flow from working.

{{ include.gateway }} can validate mTLS proof-of-possession (PoP) through a header instead.
When configured, it reads the client certificate from an HTTP header injected by the WAF or proxy, validates it against a trusted CA, and verifies that its thumbprint matches the `cnf.x5t#S256` claim bound in the access token.

To enable mTLS PoP via header:
* Configure your IdP to generate OAuth 2.0 mTLS certificate-bound access tokens.
* Configure your WAF or L7 proxy to inject the client certificate into a known HTTP header.
* Set [`config.proof_of_possession_mtls`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-proof-of-possession-mtls" }}) to `strict` and configure `config.proof_of_possession_mtls_from_header` with the header name, expected certificate format, and a trusted CA certificate.

{% unless include.hide_examples %}
See the [mTLS PoP via header example](/plugins/openid-connect/examples/mtls-pop-from-header/) and [Configure OpenID Connect with mTLS Proof-of-Possession via header](/how-to/configure-oidc-with-pop-token-in-header/) for a complete tutorial.
{% endunless %}
