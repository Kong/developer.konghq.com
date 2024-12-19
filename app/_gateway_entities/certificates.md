---
title: Certificates
content_type: reference
entities:
  - consumer-group

description: A certificate object represents a public certificate, and can be optionally paired with the corresponding private key.

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

related_resources:
    - text: Create rate limiting tiers with {{site.base_gateway}}
      url: /how-to/add-rate-limiting-tiers-with-kong-gateway/

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config 
    - gateway/admin-oss

faqs:
  - q: What's the difference between the Certificate entity and the CA Certificate entity?
    a: The Certificate entity contains server certificates that aren't signed by a certificate authority (CA).
  - q: Is the Certificate entity used in {{site.konnect_short_name}} for data plane nodes as well?
    a: No, the data plane nodes use a [different certificate](/api/konnect/control-planes-config/).
---

## What is a Certificate?

A Certificate object represents a public certificate, which is used to validate the sender's authorization and name. It can optionally be paired with the corresponding private key to initiate secure connections and encrypt sensitive data. 

{{site.base_gateway}} can use Certificates in the following ways:
* Handle [SSL/TLS termination](https://docs.konghq.com/kubernetes-ingress-controller/latest/guides/services/tls/) for encrypted requests
* Use as a trusted CA store when validating peer certificate of client or Service
* Tie a certificate and key pair to one or more hostnames using the associated SNI object

## Schema

{% entity_schema %}

## Set up a Certificate

{% entity_example %}
type: certificate
data:
    cert: -----BEGIN CERTIFICATE-----\ncertificate-content\n-----END CERTIFICATE-----
    key: -----BEGIN PRIVATE KEY-----\nprivate-key-content\n-----END PRIVATE KEY-----
{% endentity_example %}