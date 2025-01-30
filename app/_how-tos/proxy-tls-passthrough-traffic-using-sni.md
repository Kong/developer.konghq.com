---
title: Proxy TLS passthrough traffic
content_type: how_to
related_resources:
  - text: SNI entity
    url: /gateway/entities/snis


products:
    - gateway

works_on:
    - on-prem
    - konnect

entities: 
  - certificate
  - sni
  - route
  - service

tldr:
    q: How do I set up {{site.base_gateway}} to proxy TLS passthrough traffic?
    a: Create a Route with the `tls_passthrough` protocol and add at least one SNI, set the protocol for the corresponding Gateway Service to `tcp`.
tools:
    - deck

prereqs:
  entities:
      services:
        - example-service
      routes:
        - example-route
    
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

@TODO
{{site.base_gateway}} can proxy TLS requests using the client's TLS SNI extension as a forwarding mechanism. This allows a TLS request to be accepted without needing to decrypt it. 


## 1. 