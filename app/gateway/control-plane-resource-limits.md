---
title: "Default resource limits for control planes"
content_type: reference
layout: reference
breadcrumbs: 
  - /konnect/
products:
  - gateway
works_on:
  - konnect
tags:
  - control-plane
  - gateway-manager

description: In {{site.konnect_short_name}}, every control plane has a default resource limit per Gateway entity.

related_resources:
  - text: Gateway entities
    url: /gateway/entities/
---

In {{site.konnect_short_name}}, every API Gateway control plane has a default resource limit per [Gateway entity](/gateway/entities/).

If you need any of the {{site.konnect_short_name}} entity resource limits increased, contact Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com). 

<!--vale off-->
{% table %}
columns:
  - title: Resource name
    key: resource
  - title: Default resource limit
    key: limit
rows:
  - resource: Access Control List
    limit: 50000
  - resource: Asymmetric Key
    limit: 1000
  - resource: Asymmetric KeySet
    limit: 1000
  - resource: Basic Authentication
    limit: 50000
  - resource: Certificate Authority Certificate
    limit: 1000
  - resource: Certificate
    limit: 1000
  - resource: Consumer
    limit: 50000
  - resource: Consumer Group
    limit: 1000
  - resource: Consumer Group Member
    limit: 50000
  - resource: Consumer Group Rate Limiting Advanced Configuration
    limit: 1000
  - resource: Custom Plugins
    limit: 100
  - resource: Data Plane Client Certificate
    limit: 32
  - resource: DeGraphQL Route
    limit: 1000
  - resource: GraphQL Rate Limiting Cost Decoration
    limit: 1000
  - resource: Hash-based Message Authentication
    limit: 50000
  - resource: JSON Web Token
    limit: 50000
  - resource: "Key (API Key) Authentication"
    limit: 50000
  - resource: Mutual Transport Layer Security Authentication
    limit: 50000
  - resource: Plugin Configuration
    limit: 10000
  - resource: Route
    limit: 10000
  - resource: Control Planes
    limit: 100
  - resource: Server Name Indication (SNI)
    limit: 1000
  - resource: Service
    limit: 10000
  - resource: Target
    limit: 10000
  - resource: Upstream
    limit: 10000
  - resource: Vault
    limit: 1000
{% endtable %}
<!--vale on-->
