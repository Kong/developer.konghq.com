---
title: Enable OIDC for Kong Manager
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
    
products:
  - gateway

entities:
  - admin
  - rbac

works_on:
  - on-prem


tags:
  - authentication
  - kong-manager

tldr: 
  q: How do I authenticate users in Kong Manager using my own identity provider?
  a: |
    {{site.base_gateway}} offers the ability to bind authentication for Kong Manager admins to an organization’s OpenID Connect Identity Provider using the OpenID Connect Plugin.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---


@todo

Source: https://docs.konghq.com/gateway/latest/kong-manager/auth/oidc/configure/