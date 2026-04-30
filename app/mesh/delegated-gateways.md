---
title: 'Delegated gateways'
description: 'Guide to configuring delegated gateways in {{site.mesh_product_name}}, allowing external API gateways to handle ingress while {{site.mesh_product_name}} manages egress to the mesh.'

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: 'Data plane proxy'
    url: '/mesh/data-plane-proxy/'
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: Built-in gateways
    url: '/mesh/built-in-gateway/'

min_version:
  mesh: '2.6'

---

Delegated gateways allow you to integrate existing API gateway solutions into your mesh.

In delegated gateway mode, {{site.mesh_product_name}} configures an Envoy [sidecar](/mesh/data-plane-proxy/) for your API gateway.
Handling incoming traffic is left to the API gateway while Envoy and {{site.mesh_product_name}} take care of traffic leaving the gateway for the mesh.
The non-{{site.mesh_product_name}} gateway is in charge of policy such as security or timeouts related to incoming traffic, and {{site.mesh_product_name}} takes over after traffic leaves the gateway for the mesh.

At a technical level, the delegated gateway sidecar is similar to any other sidecar in the mesh, except that incoming traffic bypasses the sidecar and directly reaches the gateway.

See [Set up a built-in gateway with {{site.mesh_product_name}}](/mesh/use-kong-as-delegated-gateway/) to get started with delegated gateways.

## Usage

### Kubernetes

{{site.mesh_product_name}} supports most ingress controllers. However, the recommended gateway in Kubernetes is [{{site.base_gateway}}](/gateway/). You can use [{{site.operator_product_name}}](/operator/) to implement authentication, transformations, and other functionality across Kubernetes clusters with zero downtime.

#### Service upstream

{{site.mesh_product_name}} takes over from `kube-proxy` when managing endpoints for `Service` traffic.
{{site.base_gateway}} does the same for upstream traffic.
To prevent these from conflicting, configure {{site.operator_product_name}} to forward traffic to the `Service` IP rather than directly to Pod endpoints by setting `serviceUpstream: true` in an [`IngressClassParameters`](/operator/reference/custom-resources/#ingressclassparametersspec) resource:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: IngressClassParameters
metadata:
  name: kong-params
  namespace: default
spec:
  serviceUpstream: true
```

Then reference this in your `IngressClass`:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: kong
spec:
  controller: ingress-controllers.konghq.com/kong
  parameters:
    apiGroup: configuration.konghq.com
    kind: IngressClassParameters
    name: kong-params
    namespace: default
    scope: Namespace
```

{{site.mesh_product_name}} then routes this `Service` traffic to endpoints as configured by the mesh.

#### Delegated gateway data planes

To use the delegated gateway feature, add your the `kuma.io/gateway: enabled` annotation to your gateway's Pod.
The control plane automatically generates `Dataplane` objects.

For example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
spec:
  template:
    metadata:
      annotations:
        kuma.io/gateway: enabled
      ...
```

Now the gateway can send traffic to any services in the mesh including other zones.

In order to send multi-zone traffic, you can either use the [`.mesh` address](/mesh/dns/) or create a `Service` of type `ExternalName` that points to that URL.

### Universal

On Universal, you should define the `Dataplane` entity like this:

```yaml
type: Dataplane
mesh: default
name: kong-01
networking:
  ...
  gateway:
    type: DELEGATED
    tags:
      kuma.io/service: kong
```

Traffic that should go through the gateway should be sent directly to the gateway process. When configuring your API Gateway to forward traffic to the mesh, configure the `Dataplane` object as any other `Dataplane` on Universal.

