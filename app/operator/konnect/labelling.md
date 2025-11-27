---
title: "Labelling and Tagging resources"
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

---

Tags and labels are a way to organize and categorize your resources. This doc explains how to annotate your {{site.konnect_short_name}} entities managed by {{site.operator_product_name}} with tags and labels depending on particular entity's support for those.

## Labeling
Labels are key-value pairs you can attach to certain objects. Currently, the only {{site.konnect_short_name}} entity that supports labels is [`KonnectGatewayControlPlane`](/operator/konnect/crd/control-planes/hybrid/).
You can add labels to the `KonnectGatewayControlPlane` object by specifying the `labels` field in the `spec` section.

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

At this point, labels should be visible in the [Gateway Manager](https://cloud.konghq.com/us/gateway-manager/) UI.

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

At this point, tags should be visible in the [Gateway Manager](https://cloud.konghq.com/us/gateway-manager/) UI.

### `konghq.com/tags` annotation

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
