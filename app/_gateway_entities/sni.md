---
title: SNIs
content_type: reference
entities:
  - sni

description: An SNI object represents a many-to-one mapping of hostnames to a certificate.

related_resources:
  - text: Certificates
    url: /gateway/entities/certificate/
      
tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

api_specs:
    - gateway/admin-oss
    - gateway/admin-ee
    - konnect/control-planes-config

schema:
    api: gateway/admin-ee
    path: /schemas/SNI
---

## What is an SNI?

An SNI (Server Name Indication) is used to map multiple hostnames to a [Certificate](/gateway/entities/certificate/). It allows {{site.base_gateway}} to select which SSL/TLS Certificate to use based on the hostname in the client request. This feature ensures that multiple domains can be securely served through the same gateway.

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