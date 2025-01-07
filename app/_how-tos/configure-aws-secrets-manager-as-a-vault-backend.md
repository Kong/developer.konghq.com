---
title: Configure AWS Secrets Manager as a vault backend
content_type: how_to
related_resources:
  - text: Rotate secrets in AWS Secrets Manager with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-aws-secrets-manager   

products:
    - gateway

tier: enterprise

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:

entities: 
  - vault

tags:
    - security

tldr:
    q: How do I 
    a: 

tools:
    - deck

prereqs:

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

Use content from https://docs.konghq.com/gateway/latest/kong-enterprise/secrets-management/backends/aws-sm/ 