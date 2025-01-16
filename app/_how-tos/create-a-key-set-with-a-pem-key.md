---
title: Create a Key Set with a PEM Key
content_type: how_to

entities: 
  - key
  - key-set

related_resources:
  - text: Key entity
    url: /gateway/entities/key
  - text: Key Set entity
    url: /gateway/entities/key-set

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

tldr:
  q: How do I create a PEM key and add it to a Key Set?
  a: Create a Key Set with the `/key-sets` endpoint, then create a Key and configure the `set.id` or `set.name` parameter to point to the Key Set. 

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

based on: https://docs.konghq.com/gateway/latest/reference/key-management/#create-a-key-using-the-pem-format-and-associate-with-a-key-set