---
title: Set up authenticated group mapping in Kong Manager with OIDC
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: Kong Manager
    url: /gateway/kong-manager/
  - text: Kong Manager Configuration
    url: /gateway/kong-manager/configuration/
    
products:
  - gateway

entities:
  - rbac

works_on:
  - on-prem


tags:
  - authentication
  - kong-manager

tldr: 
  q: When using OIDC for authentication, how do map automatically map Kong Managers users to groups?
  a: |
   Using the OpenID Connect plugin (OIDC), you can map identity provider (IdP) groups to {{site.base_gateway}} roles. Adding a user in this way gives them access to {{site.base_gateway}} based on their group in the IdP.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

@todo

source: https://docs.konghq.com/gateway/latest/kong-manager/auth/oidc/mapping/