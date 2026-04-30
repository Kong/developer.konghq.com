---
title: Running built-in gateway pods on Kubernetes with MeshGatewayInstance
description: Guide to running built-in gateway pods with MeshGatewayInstance in Kubernetes and customizing deployments and services.
products:
  - mesh
content_type: reference
layout: reference
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.7'

related_resources:
  - text: Add a built-in gateway
    url: /how-to/set-up-a-built-in-mesh-gateway/
  - text: Deploy Kong Mesh on Kubernetes
    url: /mesh/kubernetes/
  - text: Built-in gateways
    url: /mesh/built-in-gateway/
  - text: Configuring built-in routes
    url: /mesh/gateway-routes/
---

`MeshGatewayInstance` is a Kubernetes-only resource for deploying [{{site.mesh_product_name}}'s built-in gateway](/mesh/built-in-gateway/).

[`MeshGateway`](/mesh/gateway-listeners/) and [`MeshHTTPRoute`](/mesh/policies/meshhttproute/)/[`MeshTCPRoute`](/mesh/policies/meshtcproute/) configure built-in gateway listeners and routes, but don't manage the `kuma-dp` instances that serve traffic.

{{site.mesh_product_name}} offers `MeshGatewayInstance` to manage a Kubernetes Deployment and Service
that together provide service capacity for the `MeshGateway`.

{:.info}
> If you're not using the `default` mesh, label the `MeshGatewayInstance` with `kuma.io/mesh`.

Consider the following example:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
  labels:
    kuma.io/mesh: mesh-name
spec:
  replicas: 2
  serviceType: LoadBalancer
```

Once a `MeshGateway` exists with `kuma.io/service: edge-gateway_default_svc`, the control plane creates a new Deployment in the `default` namespace.
This Deployment deploys two replicas of `kuma-dp` and a corresponding built-in gateway data plane with `kuma.io/service: edge-gateway_default_svc`.

The control plane also creates a new Service to send network traffic to the built-in data plane Pods.
The Service is of type `LoadBalancer`, and its ports are automatically adjusted to match the listeners on the corresponding `MeshGateway`.

## Customization

You can further customize the generated Service or Pods using `spec.serviceTemplate` and `spec.podTemplate`.

For example, you can add annotations or labels to the generated objects:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
  serviceTemplate:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
  podTemplate:
    metadata:
      labels:
        app-name: my-app
```

You can also modify several resource limits or security-related parameters for the generated Pods or specify a `loadBalancerIP` for the Service:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
  resources:
    requests:
      memory: 64Mi
      cpu: 250m
    limits:
      memory: 128Mi
      cpu: 500m
  serviceTemplate:
    metadata:
      labels:
        svc-id: "19-001"
    spec:
      loadBalancerIP: 172.17.0.1
  podTemplate:
    metadata:
      annotations:
        app-monitor: "false"
    spec:
      serviceAccountName: my-sa
      securityContext:
        fsGroup: 2000
      container:
        securityContext:
          readOnlyRootFilesystem: true
```

## Schema

{% json_schema kuma.io_meshgatewayinstances type=crd %}
