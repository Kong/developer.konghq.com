---
title: How to configure a Kong service to perform upstream MTLS
content_type: support
description: Configure a Kong service for upstream MTLS by setting a client certificate and CA certificate at the service level or globally.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure a Kong service to perform mutual TLS with an upstream?
  a: |
    Upstream MTLS needs a client certificate to present and a CA certificate to verify the upstream.
    Per service, upload the client cert and set `config.client_certificate`, and upload the CA cert and set `config.ca_certificates`. To apply globally instead, use `KONG_CLIENT_SSL_CERT` / `KONG_CLIENT_SSL_CERT_KEY` and `KONG_NGINX_PROXY_PROXY_SSL_TRUSTED_CERTIFICATE`.
related_resources: []
---

## Overview

How can Kong services be configured to negotiate MTLS with an upstream?

## Steps

MTLS with an upstream service requires several components:

- The ability to provide a client certificate with the proxied request.
- The ability to verify the upstream's presented server certificate.

1. Set up the client certificate (service level).

   a) Install the client certificate into Kong Manager's Certificates section or via the Admin API. See the Certificate API documentation.

   Example:

   ```bash
   curl -X POST \
     http://localhost:8001/certificates \
     -H 'Content-Type: multipart/form-data' \
     -F cert=@./client-cert.pem \
     -F key=@./client-cert.key \
     -H "kong-admin-token:admin"
   ```

   If installing the certificate via CLI / Admin API, a successful response will include a certificate object id. Kong Manager will also show this ID and allow it to be retrieved.

   b) Use the certificate ID obtained in step 1, and enter it into the `config.client_certificate` field in the service. See the Service API documentation.

   Whenever a request is proxied to that service, the certificate associated with that id will be used as a client certificate.

   Further reading: Why do I have to add the private key with my client certificate?

2. Set up the CA certificate (service level).

   a) Install the CA certificate as in the previous step 1a, except use the CA Certificates API this time.

   Example:

   ```bash
   curl -X POST \
     http://localhost:8001/ca_certificates \
     -H 'Content-Type: multipart/form-data' \
     -F cert=@./ca-cert.pem \
     -H "kong-admin-token:admin"
   ```

   Note: You only need to add the certificate(s) for CA Certs. Private keys are not required / accepted.

   b) As with step 1b, use the CA certificate object id and enter it into the `config.ca_certificates` field in the service.

   When Kong does TLS negotiation with the upstream service, the CA Cert associated with that id will be used to verify the upstream server cert.

3. Set up the client certificate (global).

   Nginx can use 2 directives to set a global client certificate which will attach to all services.

   `KONG_CLIENT_SSL_CERT` and `KONG_CLIENT_SSL_CERT_KEY` can be used to indicate the path of the certificate and key that will be used with client certificate negotiation.

4. Set up the CA certificate (global).

   Nginx can use a directive to set a CA cert to verify all upstream server certificates without needing to modify all service configs.

   `KONG_NGINX_PROXY_PROXY_SSL_TRUSTED_CERTIFICATE` contains the path to a PEM file that can hold multiple CA Root certificates for verifying ALL upstream server certificates.

Further reading: Defining SSL certs and where to use them
