---
title: Configure HTTP logging over mTLS
permalink: /how-to/configure-mtls-for-http-log/
content_type: how_to

related_resources:
  - text: HTTP Log plugin
    url: /plugins/http-log/
  - text: Certificate entity
    url: /gateway/entities/certificate/
  - text: Logging plugins
    url: /plugins/?category=logging

plugins:
  - http-log

entities:
  - route
  - service
  - plugin
  - certificate

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
  skip_product: true

tags:
  - logging
  - security

search_aliases:
  - mtls
  - mutual tls
  - http log
  - log server

description: Learn how to configure the HTTP Log plugin to authenticate with a log server using mutual TLS.

tldr:
  q: How do I send HTTP logs to a log server over mTLS?
  a: |
    To send HTTP logs to a log server over mTLS, store the client certificate and private key as a Certificate entity in {{site.base_gateway}} and configure
    the HTTP Log plugin's `client_certificate` parameter to reference that entity by ID.
    Start {{site.base_gateway}} with `KONG_LUA_SSL_TRUSTED_CERTIFICATE` pointing to the CA that signed the log server's certificate.

cleanup:
  inline:
    - title: Clean up certificates and log server
      content: |
        Stop and remove the log server container, then delete the working directory:

        ```bash
        docker stop logserver && docker rm logserver
        rm -rf ~/http-log-mtls
        ```
      icon_url: /assets/icons/key.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Generate certificates

This guide uses three certificates:
* A CA certificate, used to sign the log server and client certificates
* A log server certificate, presented by the log server during the TLS handshake
* A client certificate, presented by {{site.base_gateway}} to the log server

1. Create a working directory and change into it:

   ```bash
   mkdir -p ~/http-log-mtls/certs && cd ~/http-log-mtls/certs
   ```

1. Generate a CA certificate:

   ```bash
   openssl req -new -x509 -nodes -days 365 \
     -subj '/CN=my-ca' \
     -keyout ca.key \
     -out ca.crt
   ```

1. Generate a log server certificate signed by the CA.
   The `subjectAltName` must match the hostname that {{site.base_gateway}} uses to reach the log server.
   In this guide, the log server runs as a Docker container on the same network as {{site.base_gateway}} under the hostname `logserver`:

   ```bash
   openssl genrsa -out logserver.key 2048

   openssl req -new -key logserver.key -out logserver.csr \
     -subj "/CN=logserver"

   cat > logserver.ext <<EOF
   authorityKeyIdentifier=keyid,issuer
   basicConstraints=CA:FALSE
   keyUsage = digitalSignature, keyEncipherment
   extendedKeyUsage = serverAuth
   subjectAltName = DNS:logserver
   EOF

   openssl x509 -req \
     -in logserver.csr \
     -CA ca.crt -CAkey ca.key -CAcreateserial \
     -out logserver.crt -days 365 -sha256 -extfile logserver.ext
   ```

1. Generate a client certificate for {{site.base_gateway}}:

   ```bash
   openssl genrsa -out client.key 2048

   openssl req -new -key client.key -out client.csr \
     -subj "/CN=kong-client"

   openssl x509 -req \
     -in client.csr \
     -CA ca.crt -CAkey ca.key -CAcreateserial \
     -out client.crt -days 365 -sha256
   ```

## Start {{site.base_gateway}}

The HTTP Log plugin verifies the log server's TLS certificate against a trusted CA.
Pass the CA certificate to {{site.base_gateway}} at startup so {{site.base_gateway}} can validate the log server's certificate during the mTLS handshake.

1. Export your credentials:

   ```bash
   export KONG_LICENSE_DATA='LICENSE-CONTENTS-GO-HERE'
   ```
   {: data-deployment-topology="on-prem" data-test-step="block" }

   ```bash
   export KONNECT_TOKEN='YOUR_KONNECT_PAT'
   ```
   {: data-deployment-topology="konnect" data-test-step="block" }

1. Start {{site.base_gateway}} using the quickstart script, mounting the CA certificate and configuring it as a trusted CA:

   ```bash
   curl -Ls https://get.konghq.com/quickstart | bash -s -- \
     -e KONG_LICENSE_DATA \
     -v "$(pwd)/ca.crt:/etc/ssl/certs/ca.crt" \
     -e KONG_LUA_SSL_TRUSTED_CERTIFICATE="/etc/ssl/certs/ca.crt, system"
   ```
   {: data-deployment-topology="on-prem" data-test-step="block" }

   ```bash
   curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN \
     -v "$(pwd)/ca.crt:/etc/ssl/certs/ca.crt" \
     -e KONG_LUA_SSL_TRUSTED_CERTIFICATE="/etc/ssl/certs/ca.crt, system" \
     --deck-output
   ```
   {: data-deployment-topology="konnect" data-test-step="block" }

   This mounts `ca.crt` into the container and tells {{site.base_gateway}} to trust it for outbound TLS connections.
   When {{site.base_gateway}} is ready, you'll see:

   <!--vale off-->
   ```
   Kong Gateway Ready
   ```
   {:.no-copy-code}
   <!--vale on-->

   Copy and paste the printed environment variable exports into your terminal to configure your session.
   {: data-deployment-topology="konnect" }

## Start the log server

For this tutorial, we're using an Nginx log server, and configuring it to require a client certificate from any connecting client.

1. Create a directory for the log server and copy the certificates into it:

   ```bash
   mkdir -p ~/http-log-mtls/logserver
   cp ~/http-log-mtls/certs/logserver.crt ~/http-log-mtls/logserver/
   cp ~/http-log-mtls/certs/logserver.key ~/http-log-mtls/logserver/
   cp ~/http-log-mtls/certs/ca.crt ~/http-log-mtls/logserver/
   ```

1. Create a configuration file for Nginx named `nginx.conf`:

   ```nginx
   cat <<'EOF' > ~/http-log-mtls/logserver/nginx.conf
   worker_processes auto;
   events {
     worker_connections 1024;
   }

   http {
     default_type application/json;

     log_format ingestion_format escape=json '$time_iso8601 | $remote_addr | $request_body';

     server {
       listen 443 ssl;
       server_name logserver;

       ssl_certificate     /etc/ssl/certs/logserver.crt;
       ssl_certificate_key /etc/ssl/certs/logserver.key;
       ssl_client_certificate /etc/ssl/certs/ca.crt;
       ssl_verify_client on;

       location /health {
         access_log off;
         return 200 '{"status":"ok"}';
         add_header Content-Type application/json;
       }

       location /v1/logs {
         limit_except POST {
           deny all;
        }

         client_body_in_single_buffer on;
         client_body_buffer_size 2m;

         proxy_pass http://127.0.0.1:65534 ;
         error_page 502 = @log_and_respond;
       }

       location @log_and_respond {
         access_log /var/log/nginx/ingested_logs.log ingestion_format;
         return 202 '{"status":"accepted"}';
         default_type application/json;
       }
     }
   }
   EOF
   ```
   {:.collapsible}

1. Create the `Dockerfile`:

   ```bash
   cat <<'EOF' > ~/http-log-mtls/logserver/Dockerfile
   FROM nginx:latest
   COPY logserver.crt /etc/ssl/certs/logserver.crt
   COPY logserver.key /etc/ssl/certs/logserver.key
   COPY ca.crt        /etc/ssl/certs/ca.crt
   COPY nginx.conf    /etc/nginx/nginx.conf
   EXPOSE 443
   CMD ["nginx", "-g", "daemon off;"]
   EOF
   ```

1. Build and start the log server on the same Docker network as {{site.base_gateway}}:

   ```bash
   cd ~/http-log-mtls/logserver
   docker build -t logserver .
   docker run -d --name logserver --net kong-quickstart-net -p 9443:443 logserver
   ```

1. Verify that the log server accepts a valid client certificate:

   ```bash
   curl -s --cacert ~/http-log-mtls/certs/ca.crt \
     --cert ~/http-log-mtls/certs/client.crt \
     --key ~/http-log-mtls/certs/client.key \
     --resolve logserver:9443:127.0.0.1 \
     https://logserver:9443/health
   ```

   You should receive:

   ```json
   {"status":"ok"}
   ```
   {:.no-copy-code}

## Add the client certificate to {{site.base_gateway}}

Store the client certificate and private key as a [Certificate](/gateway/entities/certificate/) entity so the HTTP Log plugin can reference it by ID.

Add the Certificate and export its ID:

```bash
export DECK_CLIENT_CERT_ID=$(curl -s -X POST http://localhost:8001/certificates \
  --data-urlencode "cert=$(cat ~/http-log-mtls/certs/client.crt)" \
  --data-urlencode "key=$(cat ~/http-log-mtls/certs/client.key)" | jq -r .id)
echo "Client Certificate ID: $DECK_CLIENT_CERT_ID"
```

## Create Service and Route

Configure an `example-service` and an `example-route`:

{% entity_examples %}
entities:
  services:
    - name: example-service
      url: https://httpbin.konghq.com
      routes:
        - name: example-route
          paths:
            - /anything
{% endentity_examples %}

## Configure the HTTP Log plugin

Enable the HTTP Log plugin on the Route and reference the Certificate entity:

{% entity_examples %}
entities:
  plugins:
    - name: http-log
      route: example-route
      config:
        http_endpoint: https://logserver/v1/logs
        ssl_verify: true
        client_certificate:
          id: ${client-cert-id}
        method: POST
        timeout: 10000
variables:
  client-cert-id:
    value: $CLIENT_CERT_ID
{% endentity_examples %}

In this configuration:
* `http_endpoint`: The HTTPS URL of the log server. In this example, {{site.base_gateway}} resolves the hostname `logserver` over the shared Docker network.
* `ssl_verify`: When `true`, {{site.base_gateway}} verifies the log server's certificate against the CA configured in `KONG_LUA_SSL_TRUSTED_CERTIFICATE`.
* `client_certificate`: References the Certificate entity containing the client certificate and private key that {{site.base_gateway}} presents to the log server.

## Validate the flow

Send a request through {{site.base_gateway}}:

{% validation request-check %}
url: /anything
display_headers: true
on_prem_url: https://localhost:8443
insecure: true
status_code: 200
{% endvalidation %}

You should get an HTTP `200` response.

Check the log server to confirm that it received the log entry:

```bash
docker exec logserver tail -n 5 /var/log/nginx/ingested_logs.log
```

You should see a JSON log entry containing the request data.
