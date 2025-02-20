---
title: 'TLS Metadata Headers'
name: 'TLS Metadata Headers'

content_type: plugin

publisher: kong-inc
description: 'Proxies TLS client certificate metadata to upstream services via HTTP headers'
tier: enterprise


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

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

search_aliases:
  - tls-metadata-headers
  - certificates
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

The following explains how the TLS Metadata Headers plugin works:

1. A client sends a request with a TLS certificate.
2. The Gateway Service that proxies the client request has either the mTLS Authentication or TLS Handshake Modifier plugin enabled, making the client certificate available to other plugins.
3. The TLS Metadata Header plugin, configured on the same Gateway Service, accesses the client certificate and extracts metadata such as the certificate itself, serial number, issuer Distinguished Name (DN), subject DN, and SHA1 fingerprint. It also retrieves the full client certificate chain.
4. If `inject_client_cert_details` is enabled, the TLS Metadata Header plugin injects the extracted TLS client certificate metadata into HTTP headers.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    actor C as Client
    participant M as mTLS Authentication <br> or TLS Handshake Modifier plugin
    participant T as TLS Metadata Header <br> plugin
    participant H as Upstream <br> service

    C->>M: Sends request with <br>TLS certificate
    M->>M: Makes client certificate <br>available to other plugins
    M->>T: Extracts metadata
    T->>T: Checks if inject_client_cert_details <br>is enabled
    alt inject_client_cert_details is enabled
        T->>H: Injects metadata into HTTP headers
    else inject_client_cert_details is disabled
        T->>T: Does nothing
    end
{% endmermaid %}

<!--vale on-->

