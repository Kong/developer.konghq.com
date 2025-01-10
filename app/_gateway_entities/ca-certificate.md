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

<!--This is being worked on in https://github.com/Kong/developer.konghq.com/pull/220-->