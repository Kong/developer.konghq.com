---
title: "Labeling and tagging resources"
description: "How do I add additional metadata to entities managed by {{ site.operator_product_name }}?"
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

related_resources:
  - text: "{{site.konnect_short_name}} labels"
    url: /konnect-platform/konnect-labels/
  - text: Set {{site.konnect_short_name}} labels on control planes and data planes with {{site.operator_product_name}}
    url: /operator/konnect/crd/gateway/labels/
  - text: Create a control plane
    url: /operator/konnect/crd/control-planes/hybrid/
  - text: Set data plane labels with KonnectExtension
    url: /operator/dataplanes/konnectextension/#set-dataplane-labels
---

Tags and labels are a way to organize and categorize your resources. This page explains how to add tags and labels to the {{site.konnect_short_name}} entities that {{site.operator_product_name}} manages. Each entity supports tags, labels, or both.

## Labeling
Labels are key-value pairs you can attach to {{site.konnect_short_name}} control planes and data plane nodes. You can set labels in the following ways:

* On a control plane that you manage with the [`KonnectGatewayControlPlane`](/operator/konnect/crd/control-planes/hybrid/) resource.
* On the control plane and data plane nodes of a hybrid `Gateway`, with annotations on the `Gateway` or `GatewayClass`. See [Labels on hybrid Gateways](#labels-on-hybrid-gateways).

Labels must meet the [{{site.konnect_short_name}} label requirements](/konnect-platform/konnect-labels/#label-requirements). Control plane labels have the following additional restrictions:

* Keys can't start with `k8s`.
* {{site.operator_product_name}} only checks the length of values, so make sure values also follow the {{site.konnect_short_name}} requirements.

To add labels to a `KonnectGatewayControlPlane` object, set the `labels` field in the `spec.createControlPlaneRequest` section.

```yaml
echo '
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: gateway-control-plane
  namespace: default
spec:
  createControlPlaneRequest:
    labels: # Arbitrary key-value pairs
      environment: production
      team: devops
    name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth # Reference to the KonnectAPIAuthConfiguration object
  ' | kubectl apply -f -
```

{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}

At this point, labels should be visible in the {{site.konnect_short_name}} UI.

### Labels on hybrid Gateways

When {{site.operator_product_name}} provisions a hybrid `Gateway`, you can set {{site.konnect_short_name}} labels with the `konghq.com/konnect-cp-labels` and `konghq.com/konnect-dp-labels` annotations on the `Gateway` or `GatewayClass` resource. For an example, see [Set {{site.konnect_short_name}} labels on control planes and data planes](/operator/konnect/crd/gateway/labels/).

{{site.operator_product_name}} writes the labels to the resources that it generates for the `Gateway`:

* `konghq.com/konnect-cp-labels`: `spec.createControlPlaneRequest.labels` of the `KonnectGatewayControlPlane`
* `konghq.com/konnect-dp-labels`: `spec.konnect.dataPlane.labels` of the `KonnectExtension`

{{site.operator_product_name}} merges the labels on a `Gateway` with the labels from its `GatewayClass`. When both set the same key, the `Gateway` value takes precedence.

Labels set through these annotations have the following limitations:

* Each annotation can contain at most 5 labels on the `Gateway` and at most 5 labels on the `GatewayClass`. The merged result for each annotation can't exceed 5 labels either. For example, if the `GatewayClass` sets 3 control plane labels and the `Gateway` sets 3 other control plane labels, the merged result has 6 labels, so {{site.operator_product_name}} rejects it.
* Each label must contain exactly one `=`, and the key can't be empty. Because `,` separates labels and `=` separates the key from the value, keys and values can't contain these characters.
* {{site.operator_product_name}} removes spaces around keys and values.
* The `konghq.com/konnect-cp-labels` annotation only applies to control planes that {{site.operator_product_name}} creates. {{site.operator_product_name}} ignores it when the `GatewayConfiguration` mirrors an existing control plane.

Control plane labels can't use the `managed-by` key, because {{site.operator_product_name}} sets it on the control plane that it creates for the `Gateway`. For the other label requirements, see [Labeling](#labeling).

If an annotation is invalid, {{site.operator_product_name}} doesn't apply any labels from that annotation and sets the `Programmed` condition of the `Gateway` to `False`, with the reason `InvalidKonnectLabels`.

## Tagging

Tags are values that you can attach to objects. All the {{site.konnect_product_name}} entities that can be attached to a `KonnectGatewayControlPlane` object support tagging. You can add tags to those entities by specifying the `tags` field in their `spec` section.

For example, to add tags to a `KongService` object, you can apply the following YAML manifest:

```yaml
echo '
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: service
  namespace: default
spec:
  tags: # Arbitrary list of strings
    - production
    - devops
  name: service
  host: example.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane # Reference to the KonnectGatewayControlPlane object
  ' | kubectl apply -f -
```

{% validation kubernetes-resource %}
kind: KongService
name: service
{% endvalidation %}

At this point, tags should be visible in the {{site.konnect_short_name}} UI.

### konghq.com/tags annotation

Alternatively you can use the `konghq.com/tags` annotation to add tags to any {{site.konnect_product_name}} entity that supports tagging.

The value of this annotation is treated as comma-separated list of tags.

For example, to add tags to a `KongService` object using the `konghq.com/tags` annotation, you can apply the following YAML manifest:

```yaml
echo '
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: service
  namespace: default
  annotations:
    konghq.com/tags: "production,devops" # Arbitrary list of strings as comma-separated values
spec:
  name: service
  host: example.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane # Reference to the KonnectGatewayControlPlane object
  ' | kubectl apply -f -
```
