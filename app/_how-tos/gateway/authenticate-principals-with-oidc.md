---
title: Authenticate Principals with the OIDC plugin
permalink: /how-to/authenticate-principals-with-oidc/
content_type: how_to
breadcrumbs:
  - /identity/
related_resources:
  - text: Authentication
    url: /gateway/authentication/

description: Use the OIDC plugin to allow Principals to authenticate.
products:
    - gateway
    - identity

plugins:
  - key-auth
works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.15'
entities: 
  - plugin
  - service
  - route
  - principal

tags:
    - authentication

tools:
    - deck

tldr:
  q: How do I authenticate Principals with OIDC?
  a: |
    SUMMARY HERE

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Kong Identity directory
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---
