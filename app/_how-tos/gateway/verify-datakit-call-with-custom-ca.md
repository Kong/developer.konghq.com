---
title: Verify a Datakit call node's TLS connection using a custom CA
permalink: /how-to/verify-datakit-call-with-custom-ca/
content_type: how_to

related_resources:
  - text: Datakit plugin
    url: /plugins/datakit/
  - text: CA Certificate entity
    url: /gateway/entities/ca-certificate/
  - text: Get started with Datakit
    url: /how-to/get-started-with-datakit/

plugins:
  - datakit

entities:
  - service
  - route
  - plugin
  - ca-certificate

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.16'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route

tags:
  - transformations
  - security

search_aliases:
  - ca_certificates
  - custom ca
  - private ca
  - tls verification

description: Learn how to configure the Datakit plugin's call node to verify TLS against a private certificate authority instead of the global trusted CA store.

tldr:
  q: How do I make a Datakit call node trust an internal service signed by my own private CA?
  a: |
    To make a Datakit `call` node trust an internal service signed by your own private CA, add the CA to {{site.base_gateway}} as a [CA Certificate](/gateway/entities/ca-certificate/) object, then set the Datakit plugin's `ca_certificates` field to that object's UUID.
    Any `call` node in the plugin instance verifies its outbound TLS connections against that CA instead of {{site.base_gateway}}'s global trusted CA store, so you can leave `ssl_verify` at its secure default of `true`.

cleanup:
  inline:
    - title: Clean up certificates and the internal service
      content: |
        Stop and remove the internal service container, then delete the working directory:

        ```bash
        docker stop internal-service && docker rm internal-service
        rm -rf ~/datakit-custom-ca
        ```
      icon_url: /assets/icons/key.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

The Datakit plugin's [`call` node](/plugins/datakit/#call-node) makes outbound HTTPS requests as part of the plugin's workflow, independent of any Service's TLS configuration.
By default, it verifies the server's certificate against {{site.base_gateway}}'s global trusted CA store (`lua_ssl_trusted_certificate`).

If a `call` node needs to reach an internal service signed by a private certificate authority, that global store often isn't an option:
* On {{site.konnect_short_name}} Dedicated Cloud Gateways, the global store is managed by {{site.konnect_short_name}}, so you can't add your own private CAs to it.
* Editing global {{site.base_gateway}} configuration to add a private CA affects every plugin and connection on the node.

This guide shows how to configure the Datakit plugin's `ca_certificates` field so a `call` node verifies its outbound TLS connection against your private CA.

## Generate certificates

In this guide, you generate two certificates:
* A CA certificate, used to sign the internal service's certificate and to configure trust in the Datakit plugin
* An internal service certificate, presented by the mock internal service during the TLS handshake

The internal service runs in its own Docker container, published to your host machine. {{site.base_gateway}} (which runs in its own container) reaches it via `host.docker.internal`, Docker's built-in DNS name for the host machine, so there's no custom Docker network to create or match.

1. Create a working directory and change into it:

   ```bash
   mkdir -p ~/datakit-custom-ca && cd ~/datakit-custom-ca
   ```

1. Generate a CA certificate:

   ```bash
   openssl req -new -x509 -nodes -days 365 \
     -subj '/CN=my-private-ca' \
     -keyout ca.key \
     -out ca.crt
   ```

1. Generate a certificate for the internal service, signed by the CA.
   The `subjectAltName` must include `host.docker.internal`, since that's the hostname the Datakit `call` node uses to reach your host machine from inside the {{site.base_gateway}} container:

   ```bash
   openssl genrsa -out internal-service.key 2048

   openssl req -new -key internal-service.key -out internal-service.csr \
     -subj "/CN=host.docker.internal"

   cat > internal-service.ext <<EOF
   authorityKeyIdentifier=keyid,issuer
   basicConstraints=CA:FALSE
   keyUsage = digitalSignature, keyEncipherment
   extendedKeyUsage = serverAuth
   subjectAltName = DNS:host.docker.internal
   EOF

   openssl x509 -req \
     -in internal-service.csr \
     -CA ca.crt -CAkey ca.key -CAcreateserial \
     -out internal-service.crt -days 365 -sha256 -extfile internal-service.ext
   ```

## Start the internal service

For this guide, use Nginx to simulate an internal service that only serves HTTPS with the certificate you just generated.

1. Create a directory for the service and copy the certificates into it:

   ```bash
   mkdir -p ~/datakit-custom-ca/internal-service
   cp ~/datakit-custom-ca/internal-service.crt ~/datakit-custom-ca/internal-service/
   cp ~/datakit-custom-ca/internal-service.key ~/datakit-custom-ca/internal-service/
   ```

1. Create a configuration file named `nginx.conf`:

   ```bash
   cat <<'EOF' > ~/datakit-custom-ca/internal-service/nginx.conf
   worker_processes auto;
   events {
     worker_connections 1024;
   }

   http {
     default_type application/json;

     server {
       listen 443 ssl;
       server_name host.docker.internal;

       ssl_certificate     /etc/ssl/certs/internal-service.crt;
       ssl_certificate_key /etc/ssl/certs/internal-service.key;

       location /author {
         default_type application/json;
         return 200 '{"author":"Example Author"}';
       }
     }
   }
   EOF
   ```
   {:.collapsible}

1. Create the `Dockerfile`:

   ```bash
   cat <<'EOF' > ~/datakit-custom-ca/internal-service/Dockerfile
   FROM nginx:latest
   COPY internal-service.crt /etc/ssl/certs/internal-service.crt
   COPY internal-service.key /etc/ssl/certs/internal-service.key
   COPY nginx.conf           /etc/nginx/nginx.conf
   EXPOSE 443
   CMD ["nginx", "-g", "daemon off;"]
   EOF
   ```

1. Build and start the internal service, publishing its port to your host machine:

   ```bash
   cd ~/datakit-custom-ca/internal-service
   docker build -t internal-service .
   docker run -d --name internal-service -p 9443:443 internal-service
   ```

1. Verify that the service is reachable and presents the expected certificate:

   ```bash
   curl -s --cacert ~/datakit-custom-ca/ca.crt \
     --resolve host.docker.internal:9443:127.0.0.1 \
     https://host.docker.internal:9443/author
   ```

   You should receive:

   ```json
   {"author":"Example Author"}
   ```
   {:.no-copy-code}

## Add the CA certificate to {{site.base_gateway}}

The Datakit plugin uses a {{site.base_gateway}} [CA Certificate](/gateway/entities/ca-certificate/) entity to verify the internal service's TLS certificate.

Add the CA certificate and export its ID:

```bash
export DECK_CA_CERT_ID=$(curl -s -X POST http://localhost:8001/ca_certificates \
    --data-urlencode "cert=$(cat ~/datakit-custom-ca/ca.crt)" | jq -r .id)
echo "CA Cert ID: $DECK_CA_CERT_ID"
```

## Configure the Datakit plugin

Using the `example-service` and `example-route` from the [prerequisites](#prerequisites), configure the Datakit plugin with a `call` node that reaches the internal service over HTTPS, and reference the CA Certificate object in `ca_certificates`:

{% entity_examples %}
entities:
  plugins:
    - name: datakit
      route: example-route
      config:
        ca_certificates:
          - ${ca-cert-id}
        nodes:
          - name: AUTHOR
            type: call
            url: https://host.docker.internal:9443/author
            ssl_verify: true
          - name: EXIT
            type: exit
            inputs:
              body: AUTHOR.body
            status: 200
variables:
  ca-cert-id:
    value: $CA_CERT_ID
{% endentity_examples %}

In this configuration:
* `ca_certificates`: A list of CA Certificate entity UUIDs. This is set at the top level of the plugin's `config`, so every `call` node in this plugin instance shares the same trust store.
* `AUTHOR`: A `call` node with `ssl_verify: true` (the default) that reaches the internal service. Its TLS certificate is verified against the CA Certificate object referenced in `ca_certificates`, instead of {{site.base_gateway}}'s global trusted CA store.
* `EXIT`: Returns the `AUTHOR` node's response body directly to the client.

## Validate the flow

Send a request through {{site.base_gateway}}:

{% validation request-check %}
url: /anything
display_headers: true
status_code: 200
{% endvalidation %}

You should get an HTTP `200` response with the internal service's response body:

```json
{"author":"Example Author"}
```
{:.no-copy-code}

This confirms that the `AUTHOR` node's TLS handshake succeeded using only the private CA referenced in `ca_certificates`. {{site.base_gateway}}'s global trusted CA store was never consulted for this request.

### Confirm the CA is being enforced

To see what happens when the referenced CA doesn't match the internal service's certificate, update the plugin to point at a CA that didn't sign it.

Generate an unrelated CA certificate:

```bash
openssl req -new -x509 -nodes -days 365 \
  -subj '/CN=unrelated-ca' \
  -keyout ~/datakit-custom-ca/unrelated-ca.key \
  -out ~/datakit-custom-ca/unrelated-ca.crt
```

Add it to {{site.base_gateway}} and export its ID:

```bash
export DECK_WRONG_CA_CERT_ID=$(curl -s -X POST http://localhost:8001/ca_certificates \
    --data-urlencode "cert=$(cat ~/datakit-custom-ca/unrelated-ca.crt)" | jq -r .id)
echo "Wrong CA Cert ID: $DECK_WRONG_CA_CERT_ID"
```

Update the Datakit plugin's `ca_certificates` to reference the unrelated CA instead:

{% entity_examples %}
entities:
  plugins:
    - name: datakit
      route: example-route
      config:
        ca_certificates:
          - ${wrong-ca-cert-id}
        nodes:
          - name: AUTHOR
            type: call
            url: https://host.docker.internal:9443/author
            ssl_verify: true
          - name: EXIT
            type: exit
            inputs:
              body: AUTHOR.body
            status: 200
variables:
  wrong-ca-cert-id:
    value: $WRONG_CA_CERT_ID
{% endentity_examples %}

Send the same request again:

{% validation request-check %}
url: /anything
display_headers: true
status_code: 500
{% endvalidation %}

You should get an HTTP `500` response, because the `AUTHOR` node's TLS certificate no longer chains to a CA in `ca_certificates`.
This confirms that {{site.base_gateway}} is enforcing the configured trust store rather than silently falling back to the global one.