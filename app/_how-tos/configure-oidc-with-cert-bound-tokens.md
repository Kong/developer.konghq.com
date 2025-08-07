---
title: Configure OpenID Connect with cert-bound access tokens
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authorization options
    url: /plugins/openid-connect/#authorization
  - text: ACL authorization in OIDC
    url: /plugins/openid-connect/#acl-plugin-authorization
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
    - title: Set up Keycloak
      include_content: prereqs/auth/oidc/keycloak-password
      icon_url: /assets/icons/keycloak.svg

tags:
  - authorization
  - openid-connect
search_aliases:
  - oidc

description: Configure the OpenID Connect and ACL plugins together to apply auth flows to ACL allow or deny lists.

tldr:
  q: How do I integrate my IdP with ACL allow or deny lists?
  a: Using the OpenID Connect and ACL plugins, set up any type of authentication (the password grant, in this guide) and enable authorization through ACL groups.

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

## Drafting grounds

```sh
#!/bin/bash

# Generate root CA private key
openssl genrsa -out rootCA.key 4096

# Create root CA certificate
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=Root CA"

# Generate server private key
openssl genrsa -out kong.example.com.key 2048

# Create server CSR
openssl req -new -key kong.example.com.key -out kong.example.com.csr -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=kong.example.com"

# Create server.ext file for SANs
cat > kong.example.com.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = kong.example.com
EOF

# Sign server CSR with root CA
openssl x509 -req -in kong.example.com.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out kong.example.com.crt -days 365 -sha256 -extfile kong.example.com.ext

# Clean up
rm kong.example.com.csr
rm rootCA.srl

echo "Root CA and server key pair generated successfully."
```

```sh
mkdir -p ~/oidc/certs && cd ~/oidc/certs
bash ~/gen_certs.sh
```
```sh
export PKCS12_PASSWORD='YOUR-PASSWORD'
export KEYSTORE_PASS='YOUR-PASSWORD'
```

```sh
openssl pkcs12 -export \
  -in kong.example.com.crt \
  -inkey kong.example.com.key \
  -certfile rootCA.crt \
  -out kong-keystore.p12 \
  -name kong \
  -passout pass:$PKCS12_PASSWORD
```

```sh
keytool -importkeystore \
  -deststorepass $KEYSTORE_PASS \
  -destkeypass $KEYSTORE_PASS \
  -destkeystore kong-keystore.jks \
  -srckeystore kong-keystore.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass $PKCS12_PASSWORD \
  -alias kong
```

client cert generate:

```sh
openssl genrsa -out client.key 2048

openssl req -new -key client.key -out client.csr \
  -subj "/C=US/ST=State/L=City/O=ClientOrg/OU=Dev/CN=client-app"
```

```sh
cat > client.ext <<EOF
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

```

```sh
openssl x509 -req \
  -in client.csr \
  -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
  -out client.crt -days 365 -sha256 -extfile client.ext

```

server cert generate:

```sh
openssl genrsa -out keycloak.key 2048

openssl req -new -key keycloak.key -out keycloak.csr \
  -subj "/C=US/ST=State/L=City/O=ClientOrg/OU=Dev/CN=localhost"

cat > keycloak.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
EOF

openssl x509 -req \
  -in keycloak.csr \
  -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
  -out keycloak.crt -days 365 -sha256 -extfile keycloak.ext
```

Fixed thing maybe?
```
in /oidc/certs
keytool -import -alias rootca \
  -keystore keycloak-truststore.p12 \
  -storetype PKCS12 \
  -file rootCA.crt \
  -storepass "$PKCS12_PASSWORD"

keytool -list -keystore keycloak-truststore.p12 -storepass "$PKCS12_PASSWORD"
```

## Keycloak

```
docker run \
  -p 9443:9443 \
  -v $(pwd)/oidc/certs:/opt/keycloak/ssl \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak \
  start \
  --https-port=9443 \
  --https-certificate-file=/opt/keycloak/ssl/keycloak.crt \
  --https-certificate-key-file=/opt/keycloak/ssl/keycloak.key \
  --https-trust-store-file=/opt/keycloak/ssl/keycloak-truststore.p12 \
  --https-trust-store-password=$PKCS12_PASSWORD \
  --https-client-auth=request \
  --hostname=https://localhost:9443 \
  --hostname-admin=https://localhost:9443
```



https://localhost:9443/admin/master/console/

Do steps 1-3 in https://developer.konghq.com/how-to/configure-oidc-with-auth-code-flow/#set-up-keycloak

step 4:
* general settings same
* capability config: Client authentication to on and authorization is on
* Make sure that Standard flow, Direct access grants, and Service accounts roles are checked. (same)

Set up keys and credentials
In your client, open the Credentials tab.
Set Client Authenticator to X509 Certificate.
Subject DN is `C=US, ST=State, L=City, O=ClientOrg, OU=Dev, CN=client-app`

**Advanced** tab.
In Advanced settings, enable **OAuth 2.0 Mutual TLS Certificate Bound Access Tokens Enabled**.


```
cd ~/oidc/certs
```
```
curl -s \
  --location --request POST 'https://localhost:9443/realms/master/protocol/openid-connect/token' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'client_id=kong' \
  --data-urlencode 'grant_type=client_credentials' \
  --cert client.crt \
  --key client.key \
  --cacert rootCA.crt | jq -r .access_token
```


Copy the Client Secret.
Switch to the Users menu and add a user.
Open the user’s Credentials tab and add a password. Be sure to disable Temporary Password.
In this guide, we’re going to use an example user named alex with the password doe.

## Enable the OpenID Connect plugin

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin. In this example, we're using the simple password grant with authenticated groups.

Enable the OpenID Connect plugin on the `example-service` Service:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        client_id:
            - ${client-id}
        client_secret: 
            - ${client-secret}
        auth_methods:
            - bearer
        proof_of_possession_mtls: strict

variables:
  issuer:
    value: $ISSUER
  client-id:
    value: $CLIENT_ID
  client-secret:
    value: $CLIENT_SECRET
{% endentity_examples %}

In this example:
* `issuer`, `client ID`, `client secret`, and `client auth`: Settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* `auth_methods`: Specifies that the plugin should use the password grant, for easy testing.
* `authenticated_groups_claim`: Looks for a groups claim in an ACL.

{% include_cached plugins/oidc/client-auth.md %}

## Validate the OpenID Connect plugin configuration

Request the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
{% endvalidation %}

You should get an HTTP `200` response with an `X-Authenticated-Groups` header:

```
"X-Authenticated-Groups": "openid, email, profile"
```
{:.no-copy-code}

## Enable the ACL plugin and verify

Let's try denying access to the `openid` group first:

{% entity_examples %}
entities:
  plugins:
    - name: acl
      service: example-service
      config:
        deny:
        - openid
{% endentity_examples %}

Try to access the `/anything` Route:

{% validation request-check %}
url: /anything
method: GET
status_code: 403
user: "alex:doe"
display_headers: true
{% endvalidation %}

You should get a `403 Forbidden` error code with the message `You cannot consume this service`.

Now let's allow access to the `openid` group:

{% entity_examples %}
entities:
  plugins:
    - name: acl
      service: example-service
      config:
        allow:
        - openid
{% endentity_examples %}

And try accessing the `/anything` Route again:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
{% endvalidation %}

This time, you should get a `200` response.
