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
    a: Generate a custom certificate/key pair using a Certificate Authority (CA) you create. Create a key for your desired host (`kong.lan`) and a CSR, setting the common name to match the hostname. Create a `kong.lan.ext` file and use the file to create a certificate signed with our CA. Then, upload the certificate and key to {{site.base_gateway}} and create an `kong.lan` SNI entity.

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

min_version:
    gateway: '3.4'
---

@todo

<!--content notes:
- Use content from this KB: https://support.konghq.com/support/s/article/How-to-setup-Kong-to-serve-an-SSL-certificate-for-API-requests
-->
