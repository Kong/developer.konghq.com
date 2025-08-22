---
title: Configure ControlPlane Feature Gates and Controllers
description: "Configure feature gates and controllers for Kong ControlPlane in {{ site.ko_product_name }}"
content_type: how_to

permalink: /operator/control-planes/how-to/configure-feature-gates-controllers/
breadcrumbs:
  - /operator/
  - index: operator
    group: Control Plane
  - index: operator
    group: Control Plane
    section: "How-To"

products:
  - operator

works_on:
  - konnect
  - on-prem

entities: []

tags:
  - ControlPlane
  - feature-gates
  - controllers

tldr:
  q: How do I configure feature gates and controllers for a ControlPlane?
  a: Use the `spec.featureGates` and `spec.controllers` fields in the ControlPlane resource.

prereqs:
  show_works_on: true
  skip_product: true
---

This guide explains how to configure feature gates and controllers for a ControlPlane in {{ site.ko_product_name }}. Feature gates allow you to enable or disable specific features, while controllers allow you to enable or disable specific resource reconciliation.

## Feature Gates

Feature gates control the availability of features in the ControlPlane. They follow the same concept as [Kubernetes feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).

### Configure Feature Gates

To configure feature gates, use the `spec.featureGates` field in your ControlPlane resource:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: my-controlplane
spec:
  featureGates:
  - name: GatewayAlpha
    state: enabled
  - name: FillIDs
    state: enabled
  dataplane:
    type: managedByOwner
```

### Available Feature Gates

The following feature gates are available:

| Feature Gate | Default | Description |
|--------------|---------|-------------|
| `GatewayAlpha` | `false` | Enables alpha maturity Gateway API features |
| `FillIDs` | `true` | Makes KIC fill in ID fields of Kong entities (Services, Routes, Consumers) to ensure stable IDs across restarts |
| `RewriteURIs` | `false` | Enables the `konghq.com/rewrite` annotation |
| `KongServiceFacade` | `false` | Enables KongServiceFacade CR reconciliation |
| `SanitizeKonnectConfigDumps` | `true` | Enables sanitization of Konnect config dumps |
| `FallbackConfiguration` | `false` | Enables generating fallback configuration when Kong Admin API returns entity errors |
| `KongCustomEntity` | `true` | Enables KongCustomEntity CR reconciliation for custom Kong entities |

{:.info}
> **Note:** The `KongCustomEntity` feature gate requires `FillIDs` to be enabled, as custom entities require stable IDs for their foreign field references.

## Controllers

Controllers determine which Kubernetes resources the ControlPlane will reconcile. You can selectively enable or disable controllers based on your needs.

### Configure Controllers

To configure controllers, use the `spec.controllers` field in your ControlPlane resource:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: my-controlplane
spec:
  controllers:
  - name: INGRESS_NETWORKINGV1
    state: enabled
  - name: SERVICE
    state: enabled
  - name: KONG_PLUGIN
    state: enabled
  - name: GWAPI_GATEWAY
    state: disabled
  - name: GWAPI_HTTPROUTE
    state: disabled
  dataplane:
    type: managedByOwner
```

### Available Controllers

The following controllers are available:

#### Ingress Controllers
| Controller Name | Enabled by default | Description |
|-----------------|--------------------|-------------|
| `INGRESS_NETWORKINGV1` | Yes | Manages Kubernetes Ingress resources (networking/v1) |
| `INGRESS_CLASS_NETWORKINGV1` | Yes | Manages Kubernetes IngressClass resources (networking/v1) |
| `INGRESS_CLASS_PARAMETERS` | Yes | Manages IngressClass parameters |

#### Kong Controllers
| Controller Name | Enabled by default | Description |
|-----------------|--------------------|-------------|
| `KONG_CLUSTERPLUGIN` | Yes | Manages Kong cluster-scoped plugin resources |
| `KONG_PLUGIN` | Yes | Manages Kong plugin resources |
| `KONG_CONSUMER` | Yes | Manages Kong consumer resources |
| `KONG_UPSTREAM_POLICY` | Yes | Manages Kong upstream policy resources |
| `KONG_SERVICE_FACADE` | Yes | Manages Kong service facade resources |
| `KONG_VAULT` | Yes | Manages Kong vault resources |
| `KONG_LICENSE` | Yes | Manages Kong license resources |
| `KONG_CUSTOM_ENTITY` | Yes | Manages Kong custom entity resources |

#### Kubernetes Core Controllers
| Controller Name | Enabled by default | Description |
|-----------------|--------------------|-------------|
| `SERVICE` | Yes | Manages Kubernetes Service resources |

#### Gateway API Controllers
| Controller Name | Enabled by default | Description |
|-----------------|--------------------|-------------|
| `GWAPI_GATEWAY` | Yes | Manages Gateway API Gateway resources |
| `GWAPI_HTTPROUTE` | Yes | Manages Gateway API HTTPRoute resources |
| `GWAPI_GRPCROUTE` | Yes | Manages Gateway API GRPCRoute resources |
| `GWAPI_REFERENCE_GRANT` | Yes | Manages Gateway API ReferenceGrant resources |

## Examples

### Enable Gateway API Support

To enable full Gateway API support:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: gateway-api-controlplane
spec:
  featureGates:
  - name: GatewayAlpha
    state: enabled
  controllers:
  - name: GWAPI_GATEWAY
    state: enabled
  - name: GWAPI_HTTPROUTE
    state: enabled
  - name: GWAPI_GRPCROUTE
    state: enabled
  - name: GWAPI_REFERENCE_GRANT
    state: enabled
  dataplane:
    type: managedByOwner
```

### Minimal Ingress-Only Configuration

For a minimal setup that only manages Ingress resources:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: ingress-only-controlplane
spec:
  controllers:
  - name: INGRESS_NETWORKINGV1
    state: enabled
  - name: INGRESS_CLASS_NETWORKINGV1
    state: enabled
  - name: SERVICE
    state: enabled
  # Disable all other controllers
  - name: KONG_PLUGIN
    state: disabled
  - name: KONG_CONSUMER
    state: disabled
  - name: GWAPI_GATEWAY
    state: disabled
  - name: GWAPI_HTTPROUTE
    state: disabled
  dataplane:
    type: managedByOwner
```

### Enable Experimental Features

To enable experimental features like URI rewriting and fallback configuration:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: experimental-controlplane
spec:
  featureGates:
  - name: RewriteURIs
    state: enabled
  - name: FallbackConfiguration
    state: enabled
  - name: KongServiceFacade
    state: enabled
  dataplane:
    type: managedByOwner
```

## Validation

You can verify your configuration by checking the ControlPlane status:

```bash
kubectl get controlplane my-controlplane -o jsonpath='{.status}' | jq .
```

The status will show which feature gates and controllers are active.
