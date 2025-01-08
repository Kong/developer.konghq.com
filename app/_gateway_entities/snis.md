---
title: SNIs
content_type: reference
entities:
  - sni

description: An SNI object represents a many-to-one mapping of hostnames to a certificate.

related_resources:
  - text: Certificates
    url: /gateway/entities/certificates
      
tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

api_specs:
    - text: Gateway Admin - EE
      url: '/api/gateway/admin-ee/#/operations/list-sni'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20Enterprise%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-EE%2Flatest%2Fkong-ee.yaml'
    - text: Gateway Admin - OSS
      url: '/api/gateway/admin-oss/#/operations/list-sni'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20OSS%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-OSS%2Flatest%2Fkong-oss.yaml'
    - text: Konnect Control Planes Config
      url: '/api/konnect/control-planes-config/#/operations/list-sni'
      insomnia_link: 'https://insomnia.rest/run/?label=Konnect%20Control%20Plane%20Config&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FKonnect%2Fcontrol-planes-config%2Fcontrol-planes-config.yaml'

schema:
    api: gateway/admin-ee
    path: /schemas/SNI
---

## What is an SNI?

An SNI (Server Name Indication) is used to map multiple hostnames to a [Certificate](/gateway/entities/certificates). It allows {{site.base_gateway}} to select which SSL/TLS Certificate to use based on the hostname in the client request. This feature ensures that multiple domains can be securely served through the same gateway.

## Schema

{% entity_schema %}

## Set up an SNI

{% entity_example %}
type: sni
data:
  name: example-sni
  certificate:
    id: 2e013e8-7623-4494-a347-6d29108ff68b
{% endentity_example %}