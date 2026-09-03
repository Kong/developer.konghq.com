---
title: How to setup self-signed intermediate certificates in Kong hybrid model
content_type: support
description: Environment variable configuration for {{site.base_gateway}} hybrid mode control planes and data planes using self-signed intermediate CA certificates, plus fixes for related TLS handshake and certificate verification errors.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Kong cluster telemetry endpoint configuration
    url: /gateway/configuration/#cluster-telemetry-endpoint
tldr:
  q: How do I configure Kong hybrid mode to use self-signed intermediate certificates?
  a: |
    Set `KONG_CLUSTER_MTLS=pki` on both the control plane and data plane, and point `KONG_CLUSTER_CA_CERT` / `KONG_LUA_SSL_TRUSTED_CERTIFICATE` at a full chain file (root CA + intermediate CA) rather than just the intermediate certificate. On the data plane, `KONG_CLUSTER_SERVER_NAME` and `KONG_CLUSTER_TELEMETRY_SERVER_NAME` must both match the control plane certificate's CN, or you'll see a `telemetry, tls handshake failed: certificate host mismatch` error. An `unable to verify the first certificate` error means the CA cert path only has the intermediate certificate, not the full chain.
---

## Overview

To install Kong in the hybrid model by Helm, the parameters below are typically required in the case of using self-signed intermediate certificates.

In CP config:

```yaml
- name: KONG_CLUSTER_MTLS
  value: pki
- name: KONG_CLUSTER_CA_CERT
  value: {path-to-chain.cert}  # in case of using immediate CA
- name: KONG_CLUSTER_CERT
  value: {path-to-cert}
- name: KONG_CLUSTER_CERT_KEY
  value:  {path-to-key}
```

In DP config:

```yaml
- name: KONG_CLUSTER_MTLS
  value: pki
- name: KONG_CLUSTER_CA_CERT
  value: {path-to-chain.cert}  # in case of using immediate CA
- name: KONG_CLUSTER_SERVER_NAME
  value: {CN}  # this should be matching with cp cert CN name
- name: KONG_CLUSTER_CERT
  value: {path to cert}
- name: KONG_CLUSTER_CERT_KEY
  value: {path to key}
- name: KONG_LUA_SSL_TRUSTED_CERTIFICATE
  value: {path-to-chain.cert}  # in case of using immediate CA
- name: KONG_CLUSTER_TELEMETRY_SERVER_NAME
  value: {same to KONG_CLUSTER_SERVER_NAME}
```

Troubleshooting:

1. Error message: `telemetry, tls handshake failed: certificate host mismatch`

   Solution:

   Please add `KONG_CLUSTER_TELEMETRY_SERVER_NAME` into the DP. The value should be the same as `KONG_CLUSTER_SERVER_NAME`.

2. Error message: `unable to verify the first certificate`

   This error message indicates an intermediate CA is used.

   In this case, a full chain from root CA to intermediate CA should be provided.

   For example, let's call it `chain.pem`.

   Inside it would look like:

   ```
   -----BEGIN CERTIFICATE-----
   {root ca cert}
   -----END CERTIFICATE-----
   -----BEGIN CERTIFICATE-----
   {intermediate ca cert}
   -----END CERTIFICATE-----
   ```

   Then, make the value of `KONG_CLUSTER_CA_CERT` and `KONG_LUA_SSL_TRUSTED_CERTIFICATE` point to this `chain.pem`.
