---
title: Define a global CA Certificate to verify server certificates
content_type: how_to

entities: 
  - ca_certificate

related_resources:
  - text: Define Service-level CA Certificate
    url: /how-to/ca-cert-for-server-on-service/
  
products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

tldr:
  q: How do I define CA Certificates to verify all upstream server certificates?
  a: Define a global CA Certificate entity in {{site.base_gateway}} and set the ID of that entity in the `kong.conf` parameter `NGINX_PROXY_PROXY_SSL_TRUSTED_CERTIFICATE`.
---

@todo

<!--
From this page: https://support.konghq.com/support/s/article/How-to-define-SSL-Certificates-and-where-you-can-use-them
How to define CA Root Certificates to verify upstream server certificates > Define a CA Root Certificate globally
-->