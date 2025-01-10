---
title: 
content_type: how_to
related_resources:
  - text: CA Certificate entity
    url: /gateway/entities/ca-certificate
  - text: Certificate entity
    url: /gateway/entities/certificate

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
---

@todo

<!--
From this page: https://support.konghq.com/support/s/article/How-to-define-SSL-Certificates-and-where-you-can-use-them
How to define CA Root Certificates to verify upstream server certificates > Define a CA Root on a specific service
-->