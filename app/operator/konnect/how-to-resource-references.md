---
title: Cross-namespace resource references
description: "Learn how to use Gateway API ReferenceGrant and KongReferenceGrant to authorize cross-namespace resource references in {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/konnect/how-to/resource-references/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "How-To"

products:
  - operator

works_on:
  - konnect
  - on-prem

tldr:
  q: How do I reference resources from a different namespace?
  a: Use a `ReferenceGrant` (for Gateway API resources) or a `KongReferenceGrant` (for Kong-specific resources) in the target namespace to authorize references from the source namespace.

---

## Overview

In complex Kubernetes environments, you may want to centralize resources like authentication credentials or TLS secrets in a dedicated, secure namespace, while your Gateway resources reside in another.

By default, {{ site.operator_product_name }} restricts references to resources within the same namespace for security. To enable cross-namespace references, you must use one of the following resources in the **target** namespace (where the resource being referenced is located):

*   **ReferenceGrant**: Standard [Kubernetes Gateway API resource](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1beta1.ReferenceGrant) used for authorizing references from Gateway API resources (like `Gateway`) to other resources (like `Secret`).
*   **KongReferenceGrant**: Kong-specific resource used for authorizing references from Kong resources (like `KonnectGatewayControlPlane` or `KongCertificate`) to other resources.

## Example: Konnect authentication across namespaces

This example shows how to allow a `Gateway` in the `kong` namespace to use Konnect authentication credentials stored in the `auth` namespace.

### 1. Create the Auth Namespace and Credentials

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: auth
---
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth
  namespace: auth
spec:
  type: token
  token: kpat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  serverURL: us.api.konghq.tech
```

### 2. Grant Reference Permission

Create a `KongReferenceGrant` in the **auth** namespace to allow the Operator's control plane (created in the `kong` namespace) to access the credentials.

```yaml
kind: KongReferenceGrant
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: allow-kong-cp-to-auth
  namespace: auth
spec:
  from:
    - group: konnect.konghq.com
      kind: KonnectGatewayControlPlane
      namespace: kong
  to:
    - group: konnect.konghq.com
      kind: KonnectAPIAuthConfiguration
```

### 3. Create the Gateway Configuration

Configure the `GatewayConfiguration` to reference the credential in the `auth` namespace.

```yaml
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/v2beta1
metadata:
  name: jw-gwc
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth
      namespace: auth
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:3.12
```

---

## Example: TLS Secret across namespaces

This example demonstrates using both `ReferenceGrant` and `KongReferenceGrant` to allow a `Gateway` in the `kong` namespace to reference a TLS `Secret` in the `secret-ns` namespace.

### 1. Create the Secret Namespace and Secret

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secret-ns
---
apiVersion: v1
kind: Secret
metadata:
  name: example-tls-secret
  namespace: secret-ns
  labels:
    konghq.com/secret: "true"
type: kubernetes.io/tls
stringData:
  tls.crt: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
  tls.key: |
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
```

### 2. Grant Reference Permissions

You need both a standard `ReferenceGrant` (for the `Gateway`) and a `KongReferenceGrant` (for Kong-specific resources that might use the secret).

```yaml
# Authorize Gateway (Standard Gateway API)
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-to-secret
  namespace: secret-ns
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: Gateway
      namespace: kong
  to:
    - group: ""
      kind: Secret
---
# Authorize Kong Resources
apiVersion: configuration.konghq.com/v1alpha1
kind: KongReferenceGrant
metadata:
  name: allow-kong-to-secret
  namespace: secret-ns
spec:
  from:
    - group: configuration.konghq.com
      kind: KongCertificate
      namespace: kong
  to:
    - group: core
      kind: Secret
```

### 3. Configure the Gateway

The `Gateway` in the `kong` namespace can now reference the `Secret` in the `secret-ns` namespace.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-gateway
  namespace: kong
spec:
  gatewayClassName: kong-xns-secret
  listeners:
    - name: https
      port: 443
      protocol: HTTPS
      hostname: example.localdomain.dev
      tls:
        mode: Terminate
        certificateRefs:
          - group: ""
            kind: Secret
            name: example-tls-secret
            namespace: secret-ns
```
