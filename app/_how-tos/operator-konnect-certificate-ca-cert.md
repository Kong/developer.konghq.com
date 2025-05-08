---
title: Create a Certificate and CA Certificate
description: "Provision TLS and CA certificates in {{site.konnect_short_name}} using Kubernetes CRDs, and assign SNIs to TLS certificates."
content_type: how_to
permalink: /operator/konnect/crd/gateway/certificate-ca-cert/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Gateway"

products:
  - operator

works_on:
  - konnect
search_aliases:
  - kgo certificate
  - kgo ca certificate
entities: []
related_resources:
  - text: CA Certificate
    url: /gateway/entities/ca-certificate/
  - text: Certificate
    url: /gateway/entities/certificate/
tags:
  - konnect-crd
 
tldr:
  q: How do I configure TLS and CA certificates for {{site.konnect_short_name}} using KGO?
  a: Use `KongCertificate` and `KongCACertificate` to manage TLS credentials and CA Certificates


prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongCertificate`

Use the `KongCertificate` resource to provision a TLS certificate in {{site.konnect_short_name}}. The certificate must be associated with a `KonnectGatewayControlPlane`.

<!-- vale off -->
{% konnect_crd %}
kind: KongCertificate
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: cert
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane # Reference to the KonnectGatewayControlPlane object
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
  key: | 
    -----BEGIN PRIVATE KEY-----
    MIIBVAIBADANBgkqhkiG9w0BAQEFAASCAT4wggE6AgEAAkEAyzipjrbAaLO/yPg7
    lL1dLWzhqNdc3S4YNR7f1RG9whWhbsPE2z42e6WGFf9hggP6xjG4qbU8jFVczpd1
    UPwGbQIDAQABAkB4pTPsOMxznDrAWbYtcFovzJMPRIOp/2J5rtGdUcIAxP2rsdqh
    Y1Nj2MV91UPsWjM0OpTD694T5mVR92oTUIvVAiEA7D1L8dCNc4pwZD7tpNLhZVh9
    BhCHPVVQ2RUwBype4FsCIQDcOFV7eD6LWTGLQfCcATr4qYLQ96Xu84F/CyqRIXvu
    1wIhAM3glYDFuaBJs60JUl1kEl4aAcr5OILxCSZGWrbD7C8lAiBtERF1JyaCyVf6
    SlwqR4m3YezCJgTuhXdbPmKEonrI3QIgIh52IOxTS7+ETXY1JjbouTR5irPEWgTM
    +qqDoIn8JJI=
    -----END PRIVATE KEY-----
{% endkonnect_crd %}
<!-- vale on -->
## Create a `KongCACertificate`

Use the `KongCACertificate` resource to provision a CA certificate in Konnect. This certificate can be used for client authentication or mutual TLS setups.
<!-- vale on -->
{% konnect_crd %}
kind: KongCACertificate
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: ca-cert
spec:
  controlPlaneRef:
    type: konnectNamespacedRef # This indicates that an in cluster reference is used
    konnectNamespacedRef:
      name: gateway-control-plane # Reference to the KonnectGatewayControlPlane object
  cert: | # Sample CA certificate in PEM format, replace with your own
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
{% endkonnect_crd %}
<!-- vale off -->


## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongCertificate
name: cert
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KongCACertificate
name: ca-cert
{% endvalidation %}
<!-- vale on -->