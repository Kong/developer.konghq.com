---
title: Enable mutual TLS authentication on a Gateway Service with {{site.base_gateway}}
content_type: how_to
description: Use the Mutual TLS Authentication plugin to enable authentication on a Service.

related_resources:
  - text: Authentication
    url: /authentication/

products:
    - gateway

entities: 
  - service
  - consumer
  - route

plugins:
    - mtls-auth

tags:
  - authentication
  - mtls-auth

tools:
    - deck

works_on:
    - on-prem
    - konnect

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
tldr:
    q: How do I secure a service with mutual TLS authentication?
    a: ""

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

@todo: Finish/fix this

## 1. Add a CA Certificate
{% entity_examples %}
entities:
  ca_certificates:
    - cert: |
        -----BEGIN CERTIFICATE-----
        CERTIFICATE_CONTENT
        -----END CERTIFICATE-----

{% endentity_examples %}

## 2. Enable the mTLS plugin

{% entity_examples %}
entities:
  plugins:
  - name: mtls-auth
    service: example-service
    config:
      send_ca_dn: true
      ca_certificates:
      - ${cert}
variables:
  cert:
    value: $CA_CERTIFICATE_ID
{% endentity_examples %}

## 3. Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. For mutual TLS authentication, each Consumer needs a UUID.

{% entity_examples %}
entities:
  consumers:
    - username: alex
      mtls_auth_credentials:
        - id:
          subject_name:
{% endentity_examples %}

## 4. Validate

{% validation request-check %}
url: /anything
status_code: 200
{% endvalidation %}
