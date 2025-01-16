---
title: Define a CA certificate on a Service to verify server certificates
content_type: how_to

entities: 
  - ca-certificate
  - service

related_resources:
  - text: Define a client certificate on a Service
    url: /how-to/client-cert-for-service/
  - text: SSL certificates reference
    url: /gateway/ssl-certificates/

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck
tldr:
  q: How do I define CA Certificates to verify upstream server certificates for a specific Gateway Service?
  a: Define a CA Certificate entity in {{site.base_gateway}}, and set the ID of that entity via the `ca_certificate` parameter of a Gateway Service.

prereqs:
  inline:
    - title: PEM-encoded CA certificate
      content: |
        {{site.base_gateway}} accepts PEM-encoded CA certificates signed by a central certificate authority (CA).
        Prepare your CA certificates on the host where {{site.base_gateway}} is running. 
      icon_url: /assets/icons/file.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
  gateway: '3.4'
---

@todo