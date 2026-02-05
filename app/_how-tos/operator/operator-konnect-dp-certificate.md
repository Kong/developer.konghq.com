---
title: Create a Data Plane client certificate
description: "Provision a Data Plane client certificate in {{site.konnect_short_name}} using the `KongDataPlaneClientCertificate` CRD."
content_type: how_to


permalink: /operator/konnect/crd/gateway/dataplane-certificate/
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

entities: []
related_resources: 
  - text: Data Plane reference
    url: /gateway/data-plane-reference/
tags:
  - konnect-crd
 
tldr:
  q: How do I create a data plane client certificate using KGO?
  a: Use the `KongDataPlaneClientCertificate` resource to provision a TLS certificate for authenticating Data Planes in {{site.konnect_short_name}}.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongDataPlaneClientCertificate`

Use the `KongDataPlaneClientCertificate` resource to define a TLS certificate used for authenticating Data Plane nodes. The certificate must be associated with a `KonnectGatewayControlPlane`.


<!-- vale off -->
{% konnect_crd %}
kind: KongDataPlaneClientCertificate
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: dp-cert
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
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
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongDataPlaneClientCertificate
name: dp-cert
{% endvalidation %}
<!-- vale on -->