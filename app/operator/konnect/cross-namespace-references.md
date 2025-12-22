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

When configuring a `KonnectGatewayControlPlane`, you can reference it from entities defined ain a different namespace.

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
