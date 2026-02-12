---
title: Configure OpenID Connect with cert-bound access tokens
permalink: /how-to/configure-oidc-with-cert-bound-tokens/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authorization options
    url: /plugins/openid-connect/#authorization
  - text: About certificate-bound access tokens with OIDC
    url: /plugins/openid-connect/#certificate-bound-access-tokens
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect
  - tls-handshake-modifier

entities:
  - route
  - service
  - plugin

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.4'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline: 
    - title: DNS hostname
      content: |
        In this tutorial, you'll need a DNS hostname that you can use for your Keycloak server. You'll need to replace the hostname in any commands in this tutorial with your own hostname. 
      icon_url: /assets/icons/code.svg
    - title: Java
      content: |
        To complete this tutorial, you need [Java 11.0.12 or later installed](https://www.java.com/download/manual.jsp).
        
        Java is required because we're using keytool to create the CA JKS keystore with your root certificates.
      icon_url: /assets/icons/java.svg

tags:
  - authorization
  - openid-connect
search_aliases:
  - oidc

description: Learn how to configure certificate-bound access token authentication with OpenID Connect and TLS Handshake Modifier.

tldr:
  q: How do I configure certificate-bound access token authentication with OpenID Connect?
  a: |
    Certificate-bound access tokens allow binding tokens to clients. This guarantees the authenticity of the token by verifying whether the sender is authorized to use the token for accessing protected resources.

    You can configure certificate-bound access token authentication with OpenID Connect by mounting your certificates into an IdP, like Keycloak, and configuring the IdP with a client and mTLS authentication. Then, configure the TLS Handshake Modifier plugin with `config.tls_client_certificate` set to `REQUEST` and the OIDC plugin with your IdP issuer, `config.proof_of_possession_mtls` set to `strict`, and enable `config.proof_of_possession_auth_methods_validation`. Generate an access token and pass it in a request. 

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

## Generate certificates

In this tutorial, you'll need various certificates such as:
* CA certificate store
* Client certificate
* Server certificate

1. Make an `/oidc/certs` directory to store the certificates and run the following steps from that directory:
   ```sh
   mkdir -p ~/oidc/certs && cd ~/oidc/certs
   ```
1. Run the following to help you generate a CA certificate:
{% capture "gen-certs" %}
```sh
openssl genrsa -out rootCA.key 4096

openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 \
  -out rootCA.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=Root CA"

echo "Root CA certificate (rootCA.crt) generated successfully."
```
{% endcapture %}
{{ gen-certs | indent: 3 }}
1. Export the passwords you want to use for your PKCS#12 and keystore. Both must be at least six characters:
   ```sh
   export PKCS12_PASSWORD='YOUR-PASSWORD'
   export KEYSTORE_PASS='YOUR-PASSWORD'
   ```
1. Generate the client certificate:
{% capture "client-cert" %}
```sh
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
  -subj "/C=US/ST=State/L=City/O=ClientOrg/OU=Dev/CN=client-app"

cat > client.ext <<EOF
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl x509 -req \
  -in client.csr \
  -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
  -out client.crt -days 365 -sha256 -extfile client.ext
```
{% endcapture %}
{{ client-cert | indent: 3 }}

1. Generate the server certificate:

   {:.danger}
   > **Important:** In this tutorial, use your DNS hostname in place of `your.hostname`.
{% capture "server-cert" %}
```sh
openssl genrsa -out keycloak.key 2048

openssl req -new -key keycloak.key -out keycloak.csr \
  -subj "/C=US/ST=State/L=City/O=ClientOrg/OU=Dev/CN=your.hostname"

cat > keycloak.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = your.hostname
EOF

openssl x509 -req \
  -in keycloak.csr \
  -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
  -out keycloak.crt -days 365 -sha256 -extfile keycloak.ext
```
{% endcapture %}
{{ server-cert | indent: 3 }}
This is used to authenticate with Keycloak and to consume the API with access token. The generated CN must adhere to the pre-defined pattern for Keycloak validation.
1. Build a PKCS#12 keystore file:
   ```sh
   openssl pkcs12 -export \
     -in keycloak.crt \
     -inkey keycloak.key \
     -certfile rootCA.crt \
     -out keycloak-keystore.p12 \
     -name keycloak \
     -passout pass:$PKCS12_PASSWORD
   ```
1. Import the root certificates to the `.p12` file:
{% capture "import-root" %}
```sh
keytool -importkeystore \
  -deststorepass $KEYSTORE_PASS \
  -destkeypass $KEYSTORE_PASS \
  -destkeystore keycloak-keystore.jks \
  -srckeystore keycloak-keystore.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass $PKCS12_PASSWORD \
  -alias keycloak
```
{% endcapture %}
{{ import-root | indent: 3 }}

1. Configure Keycloak to trust certificates signed by the CA:
{% capture "keycloak-trust" %}
```sh
keytool -import -alias rootca \
  -keystore keycloak-truststore.p12 \
  -storetype PKCS12 \
  -file rootCA.crt \
  -storepass "$PKCS12_PASSWORD"

keytool -list -keystore keycloak-truststore.p12 -storepass "$PKCS12_PASSWORD"
```
{% endcapture %}
{{ keycloak-trust | indent: 3 }}
Type `y` when prompted to trust the certificate. The Keycloak server presents this certificate to the client.

## Configure Keycloak

{:.warning}
> **Important:** You must run the following in a *new* terminal window because Keycloak's container is started in the foreground.

1. In a new terminal window, export your trust store password and hostname:
   ```sh
   export PKCS12_PASSWORD='YOUR-PASSWORD'
   export HOSTNAME='YOUR-KEYCLOAK-HOSTNAME'
   ```

1. Then, start Keycloak in Docker:
   
   {:.danger}
   > **Important:** In this tutorial, use your DNS hostname in place of `your.hostname`.
{% capture "keycloak-docker" %}
```sh
docker run \
  -p 9443:9443 \
  --network kong-quickstart-net \
  -v $(pwd)/oidc/certs:/opt/keycloak/ssl \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  --name keycloak \
  quay.io/keycloak/keycloak \
  start \
  --https-port=9443 \
  --https-certificate-file=/opt/keycloak/ssl/keycloak.crt \
  --https-certificate-key-file=/opt/keycloak/ssl/keycloak.key \
  --https-trust-store-file=/opt/keycloak/ssl/keycloak-truststore.p12 \
  --https-trust-store-password=$PKCS12_PASSWORD \
  --https-client-auth=request \
  --hostname=your.hostname
```
{% endcapture %}
{{ keycloak-docker | indent: 3 }}

1. Open the Keycloak admin console.
   The default URL of the console is `https://your.hostname:9443/admin/master/console/`.
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
      * Enable **Client authentication**
      * Enable **Authorization**
      * Select **Standard flow**, **Direct access grants**, and **Service accounts roles** 
{% endtable %}
<!--vale on-->
{% endcapture %}
{{ keycloak-client | indent: 3 }}
1. Click the **Credentials** tab.
1. Select "X509 Certificate" from the **Client Authenticator** dropdown menu.
1. Enter `CN=client-app, OU=Dev, O=ClientOrg, L=City, ST=State, C=US` in the **Subject DN** field.
1. Click **Save** and agree to the change.
1. Click the **Advanced** tab.
1. In Advanced settings, enable **OAuth 2.0 Mutual TLS Certificate Bound Access Tokens Enabled**.
1. Click **Save** at the bottom of the Advanced settings section.
1. Export your issuer:
   ```sh
   export DECK_ISSUER='https://your.hostname:9443/realms/master'
   ```
   
   {:.danger}
   > **Important:** In this tutorial, use your DNS hostname in place of `your.hostname`.

## Enable TLS handshake plugin

Configure the [TLS Handshake Modifier](/plugins/tls-handshake-modifier/) plugin to request that the client to send a client certificate:
{% entity_examples %}
entities:
  plugins:
    - name: tls-handshake-modifier
      route: example-route
      config:
        tls_client_certificate: REQUEST
{% endentity_examples %}

Alternatively, you can use the [Mutual TLS Authentication](/plugins/mtls-auth/) plugin instead.

## Enable the OpenID Connect plugin

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin. 

Enable the OpenID Connect plugin on the `example-service` Service:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      route: example-route
      config:
        issuer: ${issuer}
        auth_methods:
        - bearer
        proof_of_possession_mtls: strict
        proof_of_possession_auth_methods_validation: on

variables:
  issuer:
    value: $ISSUER
{% endentity_examples %}

In this example:
* `issuer`: Settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* `proof_of_possession_mtls`: By setting this to `strict`, it ensures all tokens are verified.
* `proof_of_possession_auth_methods_validation`: Ensures that only the `auth_methods` that are compatible with Proof of Possession (PoP) can be configured when PoP is enabled.

## Generate the access token

Now, you can generate your access token to authenticate with certificate-bound authentication.

Navigate to the `/oidc/certs` you created previously and generate the access token:
```
curl -s --location --request POST 'https://your.hostname:9443/realms/master/protocol/openid-connect/token' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'client_id=kong' \
  --data-urlencode 'grant_type=client_credentials' \
  --cert client.crt \
  --key client.key \
  --cacert rootCA.crt | jq -r .access_token
```

{:.danger}
> **Important:** In this tutorial, use your DNS hostname in place of `your.hostname`.

Export the access token:
```sh
export ACCESS_TOKEN='YOUR-ACCESS-TOKEN'
```

The access token, by default, expires in 60 seconds. If you want to extend the expiration, you can configure this in the Keycloak Advanced settings for the client by adjusting the **Access Token Lifespan** settings.

## Validate the OpenID Connect plugin configuration

Request the Service with the Keycloak access token:

```sh
curl -isk \
  -X GET "https://localhost:8443/anything" \
  -H "Authorization:Bearer $ACCESS_TOKEN" \
  --cert client.crt \
  --key client.key
```

You should get an HTTP `200` response.