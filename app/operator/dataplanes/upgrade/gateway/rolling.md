---
title: "Rolling upgrades for {{ site.base_gateway }}"
description: "Automatically terminate existing pods as new ones become ready"
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
    section: Upgrading

---

## Using DataPlane

{:.warning}
> This method is only available when running in [hybrid mode](/operator/get-started/gateway-api/install/).

To change the image used for your `DataPlane` resources, set the `spec.deployment.podTemplateSpec.spec.containers[].image` field in your resource:

```bash
kubectl edit dataplane dataplane-example -n kong
```

Once the resource is saved, Kubernetes will perform a rolling upgrade of your `Pod`s.

## Using GatewayConfiguration

{:.warning}
> This method is only available when running in [KIC mode](/operator/get-started/gateway-api/install/).

The `GatewayConfiguration` API can be used to provide the image and the image version desired for either the `ControlPlane` or `DataPlane` component of the `Gateway`. For example:

```yaml
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: kong
  namespace: default
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
```

The above configuration will deploy all `DataPlane` resources connected to the
`GatewayConfiguration` (by way of `GatewayClass`) using `kong/kong-gateway:{{ site.data.gateway_latest.release }}` and any `ControlPlane` will be deployed with `kong/kubernetes-ingress-controller:{{ site.data.kong_latest_KIC.version }}`.

Given the above, a manual upgrade or downgrade can be performed by changing the version.

For example, assuming that at least one `Gateway` is currently deployed and running using the above `GatewayConfiguration`, an upgrade could be performed by running the following:

```bash
kubectl edit gatewayconfiguration kong
```

And updating the `proxy` container image tag in `spec.dataPlaneOptions.deployment.podTemplateSpec.spec` to `3.4` like so: `kong/kong-gateway:3.4`.
The result will be a replacement `Pod` that will roll out with the old version, and once healthy the old `Pod` will be terminated.
