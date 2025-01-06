---
title: Set up {{site.base_gateway}} to serve an SSL certificate for API requests
content_type: how_to
related_resources:
  - text: Certificate entity
    url: /gateway/entities/certificate

products:
    - gateway

works_on:
    - on-prem
    - konnect

entities: 
  - certificate
  - sni

tags:
    - networking

tldr:
    q: How do I set up {{site.base_gateway}} to serve an SSL certificate for API requests?
    a: Answer

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

<!--content notes:
- Use content from this KB: https://support.konghq.com/support/s/article/How-to-setup-Kong-to-serve-an-SSL-certificate-for-API-requests
-->
