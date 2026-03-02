---
title: 'TLS Metadata Headers'
name: 'TLS Metadata Headers'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Proxies TLS client certificate metadata to upstream services via an HTTP headers'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.0'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways

icon: tls-metadata-headers.png

categories:
  - security

tags:
  - security

search_aliases:
  - tls-metadata-headers
  - certificates

notes: | 
   **Serverless Gateways**: This plugin is not supported in serverless gateways because the 
   TLS handshake does not occur at the Kong layer in this setup. 
---

The TLS Metadata Header plugin detects client certificates in requests, extracts the TLS metadata (such as the URL-encoded client certificate), and injects this metadata into HTTP headers. It does not validate client certificates.

Here are some use cases where the TLS Metadata Header plugin can be helpful:
* Pass TLS client certificate metadata to an upstream service, enabling it to perform validation of the proxied certificate
* Use the extracted metadata to route requests differently based on the client’s certificate metadata (for example, different routes for different departments or services)
* Enforce access control based on certain attributes of the client certificate, like the client’s organization (extracted from the certificate's subject DN)
* Log or audit extracted metadata from client certificates

{:.warning}
> **Important:** This plugin **must** be used in conjunction with another plugin that requests a client certificate, such as the [mTLS Authentication](/plugins/mtls-auth/) or [TLS Handshake Modifier](/plugins/tls-handshake-modifier/) plugins. 

## How it works

The TLS Metadata Header plugin accesses the client certificate and extracts the following metadata:
* The certificate itself
* Serial number
* Issuer Distinguished Name (DN)
* Subject DN
* SHA1 fingerprint
* Full client certificate chain

If [`config.inject_client_cert_details`](./reference/#schema--config-inject-client-cert-details) is enabled, the TLS Metadata Header plugin injects the extracted TLS client certificate metadata into HTTP headers.

