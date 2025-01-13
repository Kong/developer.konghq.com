---
title: CA Certificates
content_type: reference
entities:
  - ca_certificate

description: A CA certificate object represents a trusted certificate authority. These objects are used by {{site.base_gateway}} to verify the validity of a client or server certificate.

related_resources:
  - text: Certificate entity
    url: /gateway/entities/certificate/
  - text: Mutual TLS Authentication plugin
    url: /plugins/mtls-auth/
  - text: Define global CA Certificate
    url: /how-to/global-ca-cert-for-server/
  - text: Define Service-level CA Certificate
    url: /how-to/ca-cert-for-server-on-service/

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

To verify server certificates, you can define your CA Certificate:
- [Globally](/how-to/global-ca-cert-for-server/), to cover verification of all upstream server certificates
- [On a specific Gateway service](/how-to/ca-cert-for-server-on-service/)

To verify client certificates, you can use the [Mutual TLS Authentication plugin](/plugins/mtls-auth/).

## Schema

{% entity_schema %}

## Set up a CA Certificate

{% entity_example %}
type: ca_certificate
data:
    name: my_ca_certificate
    cert: |
      -----BEGIN CERTIFICATE-----
      MIIB4TCCAYugAwIBAgIUAenxUyPjkSLCe2BQXoBMBacqgLowDQYJKoZIhvcNAQEL
      BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
      GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0yNDEwMjgyMDA3NDlaFw0zNDEw
      MjYyMDA3NDlaMEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEw
      HwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwXDANBgkqhkiG9w0BAQEF
      AANLADBIAkEAyzipjrbAaLO/yPg7lL1dLWzhqNdc3S4YNR7f1RG9whWhbsPE2z42
      e6WGFf9hggP6xjG4qbU8jFVczpd1UPwGbQIDAQABo1MwUTAdBgNVHQ4EFgQUkPPB
      ghj+iHOHAKJlC1gLbKT/ZHQwHwYDVR0jBBgwFoAUkPPBghj+iHOHAKJlC1gLbKT/
      ZHQwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAANBALfy49GvA2ld+u+G
      Koxa8kCt7uywoqu0hfbBfUT4HqmXPvsuhz8RinE5ltxId108vtDNlD/+bKl+N5Ub
      qKjBs0k=
      -----END CERTIFICATE-----
{% endentity_example %}