---
title: "PodTemplateSpec"
description: "Customize your ControlPlane and DataPlane deployments. Supports images, volume mounts, node affinity and more"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Advanced Usage

---

The Kubernetes `PodTemplateSpec` defines how pods should run. You can customize everything you need to in your deployment using this resource.

For more information see the [PodTemplateSpec documentation](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-template-v1/#PodTemplateSpec).

A `PodTemplateSpec` can be provided on both `GatewayConfiguration` and `DataPlane` resources.

## GatewayConfiguration

When using the `GatewayConfiguration` resource, the `ControlPlane` and `DataPlane` resources are configured independently.

* `ControlPlane` pods take their configuration from the `spec.controlPlaneOptions.deployment.podTemplateSpec` field.
* `DataPlane` pods take their configuration from the `spec.dataPlaneOptions.deployment.podTemplateSpec` field.

## DataPlane

When using the `DataPlane` resource directly, you specify `spec.deployment.podTemplateSpec`.

## Common Usage

Here are some examples for the most common use of `PodTemplateSpec`:

- [Customize the DataPlane image](/operator/dataplanes/how-to/set-dataplane-image/)
- [Deploy a sidecar container](/operator/dataplanes/how-to/deploy-sidecars/)

In addition, you can also customize:

* Volume mounts
* Node affinity / anti-affinity
* Service account used to run the Pod

If you need additional information about customizing your deployment, raise an issue in [Kong/gateway-operator](https://github.com/Kong/gateway-operator/issues).
