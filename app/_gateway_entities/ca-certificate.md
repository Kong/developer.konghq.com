---
title: CA Certificates
content_type: reference
entities:
  - ca-certificate

description: A CA certificate object represents a trusted certificate authority. These objects are used by {{site.base_gateway}} to verify the validity of a client or server certificate.

related_resources:
  - text: Certificate entity
    url: /gateway/entities/certificate
  - text: Mutual TLS Authentication plugin
    url: /plugins/mtls-auth

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
    path: /schemas/CA-Certificate

---

## What is a CA Certificate?

A CA certificate object represents a trusted certificate authority. These objects are used by {{site.base_gateway}} to verify the validity of a client or server certificate.

## Use cases

## Schema

{% entity_schema %}

## Set up a CA Certificate

{% entity_example %}
type: ca_certificate
data:
    name: my_group
{% endentity_example %}
