---
title: Certificates
content_type: reference
entities:
  - certificate

description: A certificate object represents a public certificate, and can be optionally paired with the corresponding private key.

related_resources:
  - text: Set up {{site.base_gateway}} to serve an SSL certificate for API requests
    url: /how-to/setup-gateway-to-serve-SSL-certificates

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config 
    - gateway/admin-oss

schema:
    api: gateway/admin-ee
    path: /schemas/Certificate

faqs:
  - q: What's the difference between the Certificate entity and the CA Certificate entity?
    a: Certificates handle SSL/TLS termination for encrypted requests and CA Certificates validate client or server certificates.
  - q: Is the Certificate entity used in {{site.konnect_short_name}} for data plane nodes as well?
    a: No, the data plane nodes use a [different certificate](/api/konnect/control-planes-config/).
---