---
title: Map URIs into GraphQL queries with DeGraphQL
content_type: how_to

related_resources:
  - text: GraphQL plugins
    url: /plugins/?terms=graphql

products:
  - gateway

works_on:
  - on-prem
  - konnect

plugins: 
  - degraphql

entities:
  - service
  - route
  - plugin

tools:
  - deck


tags:
  - graphql

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
