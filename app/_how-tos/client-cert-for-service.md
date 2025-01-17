---
title: Define a client certificate on a Service
content_type: how_to

entities: 
  - certificate
  - service

related_resources:
  - text: Define global CA certificate
    url: /how-to/global-ca-cert-for-server/
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
  q: How do I define client certificates for Service-level SSL connections?
  a: Define a Certificate entity in {{site.base_gateway}}, and set the ID of that entity via the `certificate` parameter of a Gateway Service.

prereqs:
  inline:
    - title: Client certificate and private key
      content: |
        Prepare your certificates and keys on the host where {{site.base_gateway}} is running. 
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
@to-do


<!--
From this page: https://support.konghq.com/support/s/article/How-to-define-SSL-Certificates-and-where-you-can-use-them
How to define a Client Certificate to send to an upstream > Define a Client Certificate per service
-->