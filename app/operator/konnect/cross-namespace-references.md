---
title: "Cross namespace references"
description: "How do I use cross namespace references with {{ site.operator_product_name }}?"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Key Concepts

min_version:
  operator: '2.1'

---

{{ site.operator_product_name }} supports cross namespace references for certain resources.
This allows you to reference resources that are located in different namespaces than the resource that is referencing them.

## ControlPlane configuration {% new_in 2.1 %}

When configuring a `KonnectGatewayControlPlane`, you can reference it from entities defined in a different namespace.

This reference can be done via the `spec.controlPlaneRef.konnectNamespacedRef.namespace` field, by specifying the `namespace` of the `KonnectGatewayControlPlane` resource.

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongservice_api_version }}
kind: KongService
metadata:
  name: my-service
  namespace: default
spec:
  name: service-1
  host: example.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: my-control-plane
      namespace: kong
```

In order to protect cross namespace references, the `KonnectGatewayControlPlane` resource must explicitly allow references from other namespaces by specifying `KongReferenceGrant` resources.

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongreferencegrant_api_version }}
kind: KongReferenceGrant
metadata:
  name: allow-kongservice-to-konnectgatewaycontrolplane
  namespace: kong
spec:
  from:
    - group: configuration.konghq.com
      kind: KongService
      namespace: default
  to:
    - group: konnect.konghq.com
      kind: KonnectGatewayControlPlane
      # Optionally specify a specific KonnectGatewayControlPlane name to allow
      # only this specific resource to be referenced.
      # name: my-control-plane
```

## Certificate configuration {% new_in 2.1 %}

When configuring `KongCertificate` and `KongCACertificate` objects, you can reference `Secret` resources containing the actual certificate data in a different namespace.

You can do this with the `spec.secretRef.namespace` and `spec.secretRefAlt.namespace` fields, by specifying the `namespace` of the `Secret` resource:

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongcertificate_api_version }}
kind: KongCertificate
metadata:
  name: dual-cert-cross-namespace
  namespace: default
spec:
  type: secretRef
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: my-control-plane
  # Primary certificate (RSA) - cross-namespace reference
  secretRef:
    name: rsa-tls-secret
    namespace: tls-secrets-namespace
  # Alternative certificate (ECDSA) - cross-namespace reference
  secretRefAlt:
    name: ecdsa-tls-secret
    namespace: tls-secrets-namespace
```

In order to protect cross-namespace references, the `Secret` resource must explicitly allow references from other namespaces using `KongReferenceGrant` resources:

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongreferencegrant_api_version }}
kind: KongReferenceGrant
metadata:
  name: allow-kongcertificate-to-secret
  namespace: tls-secrets-namespace
spec:
  from:
    - group: configuration.konghq.com
      kind: KongCertificate
      namespace: default
  to:
    - group: core
      kind: Secret
      # Optionally specify a specific Secret name to allow
      # only this specific resource to be referenced.
      # name: my-secret-name
```

## KongPlugin configuration {% new_in 2.1 %}

When configuring `KongPluginBinding` to bind targets to an existing `KongPlugin`, you can reference `KongPlugin` resources in a different namespace.

You can do this with the `spec.pluginRef.namespace` field, by specifying the `namespace` of the `KongPlugin` resource:

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongpluginbinding_api_version }}
kind: KongPluginBinding
metadata:
  name: plugin-binding-kongservice
  namespace: default
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: demo-cp
  pluginRef:
    name: rate-limit-5-min
    namespace: ns-plugin
  targets:
    serviceRef:
      name: service-1
      kind: KongService
      group: configuration.konghq.com
```

In order to protect cross-namespace references, the `KongPlugin` resource must explicitly allow references from other namespaces using `KongReferenceGrant` resources:

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongreferencegrant_api_version }}
kind: KongReferenceGrant
metadata:
  name: allow-kongpluginbinding-to-kongplugin
  namespace: ns-plugin
spec:
  from:
    - group: configuration.konghq.com
      kind: KongPluginBinding
      namespace: default
  to:
    - group: configuration.konghq.com
      kind: KongPlugin
      # Optionally specify a specific KongPlugin name to allow
      # only this specific resource to be referenced.
      # name: my-plugin-name
```

## KongRoute configuration {% new_in 2.1 %}

When configuring `KongRoute` to bind to a `KongService`, you can reference `KongService` in a different namespace.

You can do this with the `spec.serviceRef.namespacedRef.namespace` field, by specifying the `namespace` of the `KongService` resource:

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongroute_api_version }}
kind: KongRoute
metadata:
  name: my-route
  namespace: default
spec:
  name: route-1
  protocols:
  - http
  hosts:
  - example.com
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: my-service-name
      namespace: service-namespace
```

In order to protect cross-namespace references, the `KongPlugin` resource must explicitly allow references from other namespaces using `KongReferenceGrant` resources:

```yaml
apiVersion: configuration.konghq.com/{{ site.operator_kongreferencegrant_api_version }}
kind: KongReferenceGrant
metadata:
  name: allow-kongroute-to-kongservice
  namespace: service-namespace
spec:
  from:
    - group: configuration.konghq.com
      kind: KongRoute
      namespace: default
  to:
    - group: configuration.konghq.com
      kind: KongService
      # Optionally specify a specific KongService name to allow
      # only this specific resource to be referenced.
      # name: my-service-name
```

## Troubleshooting

If you're having issues with cross namespace references, you can always check your
object's status conditions - specifically the `ResolvedRefs` condition - for more information:

```bash
kg kongservice -n kong service-1 -o jsonpath-as-json="{ .status.conditions[?(@.type=='ResolvedRefs')]}"
```

```json
[
    {
        "lastTransitionTime": "2025-12-19T15:18:07Z",
        "message": "KongReferenceGrant default/my-control-plane does not allow access to KonnectGatewayControlPlane <konnectNamespacedRef:default/my-control-plane>",
        "observedGeneration": 2,
        "reason": "RefNotPermitted",
        "status": "False",
        "type": "ResolvedRefs"
    }
]
```
