---
# @TODO KO 2.1
title: Automate TLS certificates with cert-manager
description: "Learn how to use cert-manager to automatically provision and rotate TLS certificates for {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/dataplanes/how-to/cert-manager/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem
  - konnect

tldr:
  q: How do I automate TLS certificates with {{ site.operator_product_name }}?
  a: Annotate your `Gateway` with `cert-manager.io/issuer` and reference the resulting `Secret` in your `Gateway` listeners.

---

## Overview

Integrating {{ site.operator_product_name }} with [cert-manager](https://cert-manager.io/) allows you to automatically provision and rotate TLS certificates for your Gateway listeners. This integration follows the standard Kubernetes Gateway API pattern.

When you annotate a `Gateway` resource with a cert-manager issuer, cert-manager automatically creates a `Certificate` and a corresponding `Secret` containing the TLS key pair. The Operator then configures the managed Data Planes to use this secret for TLS termination.

## Prerequisites

- [cert-manager installed](https://cert-manager.io/docs/installation/) in your cluster. If using annotations on the `Gateway` for automatic provisioning, ensure the `gateway-shim` controller is enabled.
- A configured cert-manager `Issuer` or `ClusterIssuer`.

## Configuration

The following example demonstrates how to set up `cert-manager` to issue certificates for a `Gateway`.

### 1. Create a cert-manager Issuer

For this example, we'll use a simple self-signed issuer. In a production environment, you would typically use an ACME issuer (like Let's Encrypt) or a CA issuer.

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: kong
spec:
  selfSigned: {}
```

### 2. Configure the Gateway with cert-manager

Annotate the `Gateway` resource with `cert-manager.io/issuer` and specify the `tls.certificateRefs` pointing to the secret name you want cert-manager to manage.

```yaml
---
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-gateway-configuration
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - image: kong:3.9
              name: proxy
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong-cert-manager
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong-gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-gateway
  namespace: kong
  annotations:
    # Point to the issuer created in step 1
    cert-manager.io/issuer: "selfsigned-issuer"
spec:
  gatewayClassName: kong-cert-manager
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
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-tls-certificate
  namespace: kong
spec:
  secretName: example-tls-secret
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
  dnsNames:
    - example.localdomain.dev
  # The Kong Operator requires this label to identify secrets it should manage
  secretTemplate:
    labels:
      konghq.com/secret: "true"
```

### 3. Deploy a Route

Deploy a sample `HTTPRoute` to verify that TLS termination is working.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
  namespace: kong
spec:
  parentRefs:
    - name: kong-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo
          kind: Service
          port: 80
```

Deploy the standard echo service to test the route:

```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

## Verify the Setup

1.  Check that cert-manager has created the `Certificate` resource:

    ```bash
    kubectl get certificate -n kong
    ```

2.  Verify that the `Secret` has been provisioned:

    ```bash
    kubectl get secret example-tls-secret -n kong
    ```

3.  Test the connection (assuming you have access to the Gateway's external IP and have configured DNS or hosts for `example.localdomain.dev`):

    ```bash
    curl -ivk --resolve example.localdomain.dev:443:$GATEWAY_IP https://example.localdomain.dev/echo
    ```
