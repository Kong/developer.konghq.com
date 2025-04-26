---
title: "Using SSL certificates in {{site.base_gateway}}"
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

The following table shows how to configure client certificates in {{site.base_gateway}}:

<!--vale off-->
{% table %}
columns:
  - title: Use Case
    key: use_case
  - title: Description
    key: description
  - title: Method
    key: method
rows:
  - use_case: Global client certificate
    description: Send a single cert globally with all upstream proxy requests.
    method: |
      Set `client_ssl_cert` and `client_ssl_cert_key` in `kong.conf` or as environment variables.
  - use_case: Service-level client certificate
    description: Configure Gateway Services to send individual client certificates to their upstream applications.
    method: |
      Upload the certificate and private key to a Certificate entity, then pass the entity's ID to a Gateway Service. See the [how-to guide for setting up client certificates for a Service](/how-to/client-cert-for-service/).
{% endtable %}
<!--vale on-->


## CA certificates

The following table shows how to configure CA certificates in {{site.base_gateway}}:

<!--vale off-->
{% table %}
columns:
  - title: Use Case
    key: use_case
  - title: Description
    key: description
  - title: Method
    key: method
rows:
  - use_case: Global CA certificate
    description: |
      Import a CA root certificate to cover verification of all upstream server certificates.
    method: |
      Set the `nginx_proxy_proxy_ssl_trusted_certificate` parameter in `kong.conf`, or as an environment variable. 
      <br><br> 
      If you want to disable or enable verification of upstream server certificates globally, you can also set the `nginx_proxy_proxy_tls_verify` option.
  - use_case: Service-level CA certificate
    description: |
      Define individual CA root certificates for each Gateway Service.
    method: |
      Upload the certificate and private key to a CA Certificate entity, then pass the entity's ID to a Gateway Service. 
      See the [how-to guide for setting up CA certificates for a Service](/how-to/ca-cert-for-server-on-service/).
  - use_case: Verify client certificates
    description: |
      Verify client certificates by passing CA certificates to the [mTLS Auth](/plugins/mtls-auth/) plugin.
    method: |
      Upload the certificate and private key to a [CA Certificate entity](/gateway/entities/ca-certificate/), then pass the entity's ID to the plugin via its `ca_certificates` parameter.
  - use_case: Verify client certificates sent in headers
    description: |
      Verify client certificates sent in headers by passing CA certificates to the [Header Cert Auth](/plugins/header-cert-auth/) plugin.
    method: |
      Upload the certificate and private key to a [CA Certificate entity](/gateway/entities/ca-certificate/), then pass the entity's ID to the plugin via its `ca_certificates` parameter.
{% endtable %}
<!--vale on-->
 
## Server certificates

The following table shows how to configure server certificates in {{site.base_gateway}}:

<!--vale off-->
{% table %}
columns:
  - title: Use Case
    key: use_case
  - title: Description
    key: description
  - title: Method
    key: method
rows:
  - use_case: Server certificates for SNIs
    description: |
      Standard certificates that {{site.base_gateway}} presents if a specific domain is requested when a TLS handshake is attempted at the proxy.
    method: |
      Upload certificates for SNIs using the [Certificates](/gateway/entities/certificate/) entity, then create an [SNI](/gateway/entities/sni/) using the ID of the Certificate.
{% endtable %}
<!--vale on-->


## Configuring SSL connections through kong.conf

You can directly upload certificates and keys to {{site.base_gateway}} through configuration in `kong.conf`.

All of the following parameters can also be set via [environment variables](/gateway/manage-kong-conf/).

<!--vale off-->
{% kong_config_table %}
config:
  - name: ssl_cert
  - name: ssl_cert_key
  - name: admin_gui_ssl_cert
  - name: admin_gui_ssl_cert_key
  - name: admin_ssl_cert
  - name: admin_ssl_cert_key
  - name: client_ssl_cert
  - name: client_ssl_cert_key
  - name: status_ssl_cert
  - name: status_ssl_cert_key
  - name: lua_ssl_trusted_certificate
directives:
  - name: nginx_proxy_proxy_ssl_trusted_certificate
    description: |
      Path to a PEM file that can hold multiple CA Root certificates for verifying all upstream server certificates.
{% endkong_config_table %}
<!--vale on-->

{{site.base_gateway}} also provides many customization settings for SSL connections. See the [Kong Configuration Reference](/gateway/configuration/) for all available options.
