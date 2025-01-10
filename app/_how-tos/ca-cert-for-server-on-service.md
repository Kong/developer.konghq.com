---
title: Define a CA Certificate on a Service to verify server certificates
content_type: how_to

entities: 
  - ca_certificate

related_resources:
  - text: Define global CA Certificate
    url: /how-to/global-ca-cert-for-server/

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
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

@todo

<!--
From this page: https://support.konghq.com/support/s/article/How-to-define-SSL-Certificates-and-where-you-can-use-them
How to define CA Root Certificates to verify upstream server certificates > Define a CA Root on a specific service
-->