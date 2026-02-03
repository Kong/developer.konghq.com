---
title: Secrets and Credentials Reference
description: "Reference guide for configuring Kubernetes Secrets and Credentials with the Kong Gateway Operator."
content_type: reference
permalink: /operator/reference/secrets-and-credentials/
breadcrumbs:
  - /operator/
  - index: operator
    group: Reference
  - index: operator
    group: Reference
    section: "Reference"
products:
  - operator
works_on:
  - on-prem
  - konnect
tldr:
  q: Why is my Secret not being picked up by the Operator?
  a: Ensure it has the `konghq.com/secret: "true"` label.
---

## Overview

The Kong Gateway Operator (KGO) uses a strict filtering mechanism for watching Kubernetes Secrets. To prevent the Operator from reconciling every secret in the cluster (which can be expensive and insecure), it only watches secrets that are explicitly labeled.

This guide outlines the required labels for different types of secrets.

## General Requirement

All secrets referenced by Kong resources (e.g., certificates, plugin configuration, consumer credentials) **must** have the following label:

```yaml
metadata:
  labels:
    konghq.com/secret: "true"
```

If this label is missing, the Operator will ignore the secret, even if it is correctly referenced in other resources.

## types of Secrets

### 1. TLS Certificates

Used in `Gateway` listeners or `KongPlugin` configuration.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-cert
  namespace: kong
  labels:
    konghq.com/secret: "true"
type: kubernetes.io/tls
data:
  tls.crt: ...
  tls.key: ...
```

### 2. Consumer Credentials

Used in `KongConsumer` resources. In addition to the detailed secret label, these secrets usually require a type-specific credential label (legacy KIC pattern), which is still supported and often required.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-apikey
  namespace: kong
  labels:
    # Required for Operator visibility
    konghq.com/secret: "true"
    # Required for the Consumer to identify the credential type
    konghq.com/credential: key-auth
type: Opaque
stringData:
  key: my-secret-key
```

### 3. Plugin Configuration References

Some plugins allow referencing a secret for sensitive configuration values.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: plugin-secret
  namespace: kong
  labels:
    konghq.com/secret: "true"
type: Opaque
stringData:
  secret-value: "super-secure"
```

## Troubleshooting

If your `Gateway`, `KongConsumer`, or `KongPlugin` is status "Programmed" or "Created" but the functionality is not working (e.g., 401 Unauthorized, default certificate served):

1.  Check the labels on your referenced secret:
    ```bash
    kubectl get secret <name> -n <namespace> --show-labels
    ```
2.  Ensure `konghq.com/secret` is present and set to `"true"`.
