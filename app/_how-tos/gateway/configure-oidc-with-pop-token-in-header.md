---
title: Configure OpenID Connect with mTLS Proof-of-Possession via header
permalink: /how-to/configure-oidc-with-pop-token-in-header/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: About mTLS PoP via header with OIDC
    url: /plugins/openid-connect/#mtls-proof-of-possession-via-http-header
  - text: About certificate-bound access tokens with OIDC
    url: /plugins/openid-connect/#certificate-bound-access-tokens
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect

entities:
  - route
  - service
  - plugin
  - ca-certificate

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.15'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-clean-service
    routes:
      - headers-route

tags:
  - authentication
  - openid-connect
search_aliases:
  - oidc
  - pop
  - proof-of-possession
  - mtls

description: Learn how to configure the OpenID Connect plugin to validate mTLS Proof-of-Possession tokens when TLS is terminated by a WAF or proxy before {{site.base_gateway}}.

tldr:
  q: How do I validate mTLS Proof-of-Possession tokens when TLS is terminated before {{site.base_gateway}}?
  a: |
    In deployments where a WAF or load balancer terminates TLS before {{site.base_gateway}}, the client certificate can't be read from the TLS handshake.
    Configure the OpenID Connect plugin with `proof_of_possession_mtls: strict` and `proof_of_possession_mtls_from_header` pointing to the HTTP header your WAF or proxy injects the client certificate into.
    The plugin validates the certificate against a trusted CA and verifies that its thumbprint matches the `cnf.x5t#S256` claim bound in the access token.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Generate salt token

{% include how-tos/steps/deck-salt-token.md %}

## Generate certificates

In this how-to guide, you need the following certificates:
* A CA certificate, used to sign client certificates and to configure trust in Keycloak and {{site.base_gateway}}
* A client certificate, used by the API consumer to obtain an mTLS-bound access token
* A Keycloak server certificate, used to run Keycloak with HTTPS

1. Create a working directory and run the following steps from it:

   ```sh
   mkdir -p ~/oidc-pop/certs && cd ~/oidc-pop/certs
   ```

1. Generate a CA certificate:

   ```sh
   openssl genrsa -out ca.key 4096

   openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
     -out ca.crt \
     -subj "/C=US/ST=State/L=City/O=MyOrg/CN=My Root CA"
   ```

1. Generate a client certificate for the API consumer:

   ```sh
   openssl genrsa -out client.key 2048

   openssl req -new -key client.key -out client.csr \
     -subj "/C=US/ST=State/L=City/O=ClientOrg/CN=api-client"

   openssl x509 -req \
     -in client.csr \
     -CA ca.crt -CAkey ca.key -CAcreateserial \
     -out client.crt -days 365 -sha256
   ```

1. Generate a Keycloak server certificate:

   ```sh
   openssl genrsa -out keycloak.key 2048

   openssl req -new -key keycloak.key -out keycloak.csr \
     -subj "/C=US/ST=State/L=City/O=MyOrg/CN=localhost"

   cat > keycloak.ext <<EOF
   authorityKeyIdentifier=keyid,issuer
   basicConstraints=CA:FALSE
   keyUsage = digitalSignature, keyEncipherment
   extendedKeyUsage = serverAuth
   subjectAltName = DNS:localhost
   EOF

   openssl x509 -req \
     -in keycloak.csr \
     -CA ca.crt -CAkey ca.key -CAcreateserial \
     -out keycloak.crt -days 365 -sha256 -extfile keycloak.ext
   ```

## Configure Keycloak

1. Start Keycloak in Docker with both HTTP and HTTPS enabled.
   The `KC_HOSTNAME` environment variable pins the issuer URL to `http://localhost:8080` so that {{site.base_gateway}} can reach it over the shared Docker network, while the client still uses HTTPS with mTLS on port 9443 to obtain a certificate-bound token:

   ```sh
   docker run -d \
     -p 127.0.0.1:8080:8080 \
     -p 9443:9443 \
     --network kong-quickstart-net \
     -v "$(pwd):/opt/keycloak/ssl" \
     -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
     -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
     -e KC_HOSTNAME=http://localhost:8080 \
     --name keycloak \
     quay.io/keycloak/keycloak start-dev \
     --https-port=9443 \
     --https-certificate-file=/opt/keycloak/ssl/keycloak.crt \
     --https-certificate-key-file=/opt/keycloak/ssl/keycloak.key \
     --https-trust-store-file=/opt/keycloak/ssl/ca.crt \
     --https-trust-store-type=PEM \
     --https-client-auth=request
   ```

1. Open the Keycloak admin console at `http://localhost:8080/admin/master/console/`.

1. In the sidebar, open **Clients**, then click **Create client**.

1. Configure the client:
{% capture "keycloak-client" %}
<!--vale off-->
{% table %}
columns:
  - title: Section
    key: section
  - title: Settings
    key: settings
rows:
  - section: "**General settings**"
    settings: |
      * Client type: **OpenID Connect**
      * Client ID: any unique name, for example `kong`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure **Service accounts roles** is checked
  - section: "**Login settings**"
    settings: "**Valid redirect URIs**: `http://localhost:8000/*`"
{% endtable %}
<!--vale on-->
{% endcapture %}
{{ keycloak-client | indent: 3 }}

1. Click the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.
1. Click the **Advanced** tab.
1. In the **Advanced settings** section, enable **OAuth 2.0 Mutual TLS Certificate Bound Access Tokens Enabled**.
1. Click **Save** at the bottom of the Advanced settings section.

1. Export your client credentials and Keycloak issuer.
   `DECK_ISSUER` uses `localhost` because that's the pinned issuer in tokens.
   `DECK_JWKS_ENDPOINT` uses the `keycloak` container name because {{site.base_gateway}} fetches the JWKS from inside Docker:

   ```sh
   export DECK_ISSUER='http://localhost:8080/realms/master'
   export DECK_JWKS_ENDPOINT='http://keycloak:8080/realms/master/protocol/openid-connect/certs'
   export DECK_CLIENT_ID='kong'
   export DECK_CLIENT_SECRET='<your-client-secret>'
   ```

## Add the CA certificate to {{site.base_gateway}}

The OpenID Connect plugin uses a {{site.base_gateway}} [CA Certificate](/gateway/entities/ca-certificate/) entity to validate the client certificate presented in the header.

Add the CA certificate to {{site.base_gateway}} and export its ID:

```sh
export DECK_CA_CERT_ID=$(curl -s -X POST http://localhost:8001/ca_certificates \
    --data-urlencode "cert=$(cat ca.crt)" | jq -r .id)
echo "CA Cert ID: $DECK_CA_CERT_ID"
```

## Configure the OpenID Connect plugin

Using the Keycloak and {{site.base_gateway}} configuration from the previous steps, enable the OpenID Connect plugin on the Route `headers`:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      route: headers
      config:
        issuer: ${issuer}
        jwks_endpoint: ${jwks-endpoint}
        auth_methods:
          - bearer
        proof_of_possession_mtls: strict
        proof_of_possession_auth_methods_validation: true
        proof_of_possession_mtls_from_header:
          certificate_header_name: x-client-cert
          certificate_header_format: base64_encoded
          ca_certificates:
            - ${ca-cert-id}
          ssl_verify: true
          secure_source: false
        cache_tokens_salt: ${salt-token}
variables:
  issuer:
    value: $ISSUER
  jwks-endpoint:
    value: $JWKS_ENDPOINT
  ca-cert-id:
    value: $CA_CERT_ID
  salt-token:
    value: $TOKEN_SALT
{% endentity_examples %}

In this example:
* `issuer`: Validates the `iss` claim in incoming tokens.
  Set this to the pinned issuer URL (`http://localhost:8080/realms/master`), which matches the `iss` claim Keycloak embeds in all tokens regardless of which port they were issued on.
* `jwks_endpoint`: The URL {{site.base_gateway}} uses to fetch the JWKS for token signature verification.
  This uses the container name `keycloak` so that {{site.base_gateway}} can reach Keycloak over the shared Docker network without TLS.
* `auth_methods`: Tells the plugin to accept bearer token authentication.
* `proof_of_possession_mtls`: Setting this to `strict` ensures that all bearer tokens are validated for mTLS Proof-of-Possession.
  Requests without a valid certificate-bound token are rejected.
* `proof_of_possession_auth_methods_validation`: Ensures that only authentication methods compatible with PoP can be used when PoP is enabled.
* `proof_of_possession_mtls_from_header`: Tells the plugin to read the client certificate from the `x-client-cert` HTTP header instead of the TLS layer.
  * `certificate_header_name`: The name of the HTTP header containing the client certificate.
  * `certificate_header_format`: The encoding of the certificate in the header. `base64_encoded` means the certificate bytes are base64-encoded (for example, from a DER-encoded certificate).
  * `ca_certificates`: A list of CA Certificate entity UUIDs that the plugin uses to validate the certificate in the header.
  * `ssl_verify`: Validates the certificate chain against the configured CA certificates.
  * `secure_source`: When set to `true` (default), the plugin only reads the certificate header if the client IP is in {{site.base_gateway}}'s trusted IP list.
    For this tutorial, we're setting this to `false` to accept the header from any source. 
    In production, you would leave it as `true` and configure the WAF or load balancer IP in [{{site.base_gateway}}'s trusted IPs](/gateway/configuration/#trusted-ips).

## Validate the flow

Let's check that client certificates are being read from the headers.

### Get mTLS-bound access token

Request an access token from Keycloak's token endpoint while presenting the client certificate.
Keycloak binds the certificate thumbprint to the token in the `cnf.x5t#S256` claim.

```sh
export TOKEN=$(curl -s -X POST "https://localhost:9443/realms/master/protocol/openid-connect/token" \
  --cacert ca.crt \
  --key client.key \
  --cert client.crt \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$DECK_CLIENT_ID" \
  -d "client_secret=$DECK_CLIENT_SECRET" | jq -r .access_token)
echo $TOKEN
```

To confirm the token contains the certificate thumbprint, decode it:

```sh
echo $TOKEN | cut -d'.' -f2 | tr -- '-_' '+/' | awk '{print $0"=="}' | base64 --decode 2>/dev/null | jq .cnf
```

The output should include a `x5t#S256` claim with the SHA-256 thumbprint of the client certificate:

```json
{
  "x5t#S256": "<base64-encoded-thumbprint>"
}
```
{:.no-copy-code}

### Send request to {{site.base_gateway}} with certificate in header

Base64-encode the client certificate:

```sh
BASE64_CERT=$(openssl x509 -in client.crt -outform DER | base64 | tr -d '\n')
```

Pass it in the `x-client-cert` header along with the access token:

```sh
curl -s http://localhost:8000/headers \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-client-cert: $BASE64_CERT"
```

You should get an HTTP `200` response.
{{site.base_gateway}} reads the certificate from the header, validates it against the configured CA, and confirms that its thumbprint matches the `cnf.x5t#S256` claim in the token before proxying the request.

### Verify rejection without certificate in header

Send the same request without the `x-client-cert` header:

```sh
curl -si http://localhost:8000/headers \
  -H "Authorization: Bearer $TOKEN"
```

You should get an HTTP `401 Unauthorized` response, confirming that the PoP validation is enforced.
