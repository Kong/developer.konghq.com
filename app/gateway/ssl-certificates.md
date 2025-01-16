---
title: SSL Certificates reference
description: How to define SSL Certificates and where you can use them.
content_type: reference
layout: reference
products:
   - gateway

works_on:
   - on-prem
   - konnect

related_resources:
  - text: Certificate entity
    url: /gateway/entities/certificate/
  - text: CA Certificate entity
    url: /gateway/entities/certificate/
  - text: SNI entity
    url: /gateway/entities/sni/
  - text: Gateway Service entity
    url: /gateway/entities/service/
  - text: Configuration reference
    url: /gateway/configuration/
  - text: Define a client certificate on a Service
    url: /how-to/client-cert-for-service/
  - text: Define Service-level CA certificate
    url: /how-to/ca-cert-for-server-on-service/

plugins:
  - mtls-auth
  - header-cert-auth

---

{{site.base_gateway}} uses three types of certificates:
* Client certificates: Used to verify a client as a consumer of a service
* Server certificates: Used to verify that a server is the hostname it claims to be
* CA Root certificates: Used to verify that client and server certificates are authentic

## Client certificates

Use Case | Description | Method 
---------|-------------|-------
Global client certificate | Send a single cert globally with all upstream proxy requests. | Set `client_ssl_cert` and `client_ssl_cert_key` in `kong.conf` or as environment variables.
Service-level client certificate | Configure Gateway Services to send individual client certificates to their upstream applications. | Upload the certificate and private key to a Certificate entity, then pass the entity's ID to a Gateway Service. See the [how-to guide for setting up client certificates for a Service](/how-to/client-cert-for-service/).

## CA certificates

Use Case | Description | Method 
---------|-------------|-------
Global CA certificate | Import a CA root certificate to cover verification of all upstream server certificates. | Set the `nginx_proxy_proxy_ssl_trusted_certificate` parameter in `kong.conf`, or as an environment variable. <br> If you want to disable or enable verification of upstream server certificates globally, you can also set the `nginx_proxy_proxy_tls_verify` option.
Service-level CA certificate | Define individual CA root certificates for each Gateway Service. | Upload the certificate and private key to a CA Certificate entity, then pass the entity's ID to a Gateway Service. See the [how-to guide for setting up CA certificates for a Service](/how-to/ca-cert-for-server-on-service/).
Verify client certificates | Verify client certificates by passing CA certificates to the [mTLS Auth](/plugins/mtls-auth/) plugin. | Upload the certificate and private key to a CA Certificate entity, then pass the entity's ID to the plugin via its `ca_certificates` parameter.
Verify client certificates sent in headers | Verify client certificates sent in headers by passing CA certificates to the [Header Cert Auth](/plugins/header-cert-auth/) plugin. | Upload the certificate and private key to a CA Certificate entity, then pass the entity's ID to the plugin via its `ca_certificates` parameter.
 
## Server certificates

Use Case | Description | Method 
---------|-------------|-------
Server certificates for SNIs | Standard certificates that {{site.base_gateway}} presents if a specific domain is requested when a TLS handshake is attempted at the proxy. | Upload certificates for SNIs using the [Certificates](/gateway/entities/certificates/) entity, then create an [SNI](/gateway/entities/sni/) using the ID of the Certificate.

## Configuring SSL connections through kong.conf

You can directly upload certificates and keys to {{site.base_gateway}} through configuration in `kong.conf`:

Parameter | Environment variable | Type | Description
----------|----------------------|------|------------ 
`ssl_cert` | `KONG_SSL_CERT` | Server cert |  Contains the contents or path to a certificate you want your proxy to present as a server certificate.
`ssl_cert_key` | `KONG_SSL_CERT_KEY` | Private key | Contains the contents or path to a private key for the certificate set via the `ssl_cert` parameter.
`admin_gui_ssl_cert` | `KONG_ADMIN_GUI_SSL_CERT` | Server cert | Contains the contents or path to a certificate you want your Kong Manager GUI to present as a server certificate.
`admin_gui_ssl_cert_key` | `KONG_ADMIN_GUI_SSL_CERT_KEY` | Private key  | Contains the contents or path to a private key for the certificate set via the `admin_gui_ssl_cert` parameter.
`admin_ssl_cert` | `KONG_ADMIN_SSL_CERT` |  Server cert | Contains the contents or path to a certificate you want your Admin API to present as a server certificate.
`admin_ssl_cert_key` | `KONG_ADMIN_SSL_CERT_KEY` | Private key  | Contains the contents or path to a private key for the certificate set via the `admin_ssl_cert` parameter.
`client_ssl_cert` | `KONG_CLIENT_SSL_CERT` | Client cert | Contains the contents or path to a certificate you want your Kong instance to serve as a client certificate to ALL upstreams.
`client_ssl_cert_key` | `KONG_CLIENT_SSL_CERT_KEY` | Private key  | Contains the contents or path to a private key for the certificate set via the `client_ssl_cert` parameter.
`status_ssl_cert` | `KONG_STATUS_SSL_CERT` | Server cert | Contains the contents or path to a certificate you want your Status Endpoint to server as a server certificate.
`status_ssl_cert_key` | `KONG_STATUS_SSL_CERT_KEY` | Private key  | Contains the contents or path to a private key for the certificate set via the `status_ssl_cert` parameter.
`lua_ssl_trusted_certificate` | `KONG_LUA_SSL_TRUSTED_CERTIFICATE` | CA cert | Contains the paths to CA root certificates used for verifying Lua cosocket connections. Any time that {{site.base_gateway}} uses Lua to create SSL connections, it'll use the CA root certs at this path to verify any certificates sent.
`nginx_proxy_proxy_ssl_trusted_certificate` | `KONG_NGINX_PROXY_PROXY_SSL_TRUSTED_CERTIFICATE` | CA cert | Contains the path to a PEM file that can hold multiple CA Root certificates for verifying all upstream server certificates.

{{site.base_gateway}} also provides many customization settings for SSL connections. See the [Kong Configuration Reference](/gateway/configuration/) for all available options.

