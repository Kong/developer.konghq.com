---
title: "{{site.mesh_product_name}} architecture"
description: Understand the architecture of a {{site.mesh_product_name}} service mesh, including control plane and data plane components, Kubernetes and Universal modes, and how services integrate into the mesh.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - control-plane
  - data-plane
  - kubernetes

related_resources:
  - text: Mesh concepts
    url: /mesh/concepts/
  - text: Service meshes
    url: '/mesh/service-mesh/'
  - text: Mesh policies
    url: '/mesh/policies-introduction/'
  - text: Install {{site.mesh_product_name}}
    url: /mesh/#install-kong-mesh
---

A {{site.mesh_product_name}} service mesh consists of two main components:

- The [data plane](/mesh/concepts/#data-plane) consists of the proxies that run alongside your services.
  All of your mesh traffic flows through these proxies on its way to its destination.
  {{site.mesh_product_name}} uses [Envoy](https://www.envoyproxy.io/) for its [data plane proxy](/mesh/concepts/#data-plane-proxy-sidecar).
- The [control plane](/mesh/concepts/#control-plane) configures the data plane proxies for handling mesh traffic.
  The control plane runs independently of the data plane and doesn't interact with mesh traffic directly.
  {{site.mesh_product_name}} users create [policies](/mesh/concepts/#policy) that the {{site.mesh_product_name}} control plane processes to generate configuration for the data plane proxies.

{:.info}
> One {{site.mesh_product_name}} control plane deployment can control multiple isolated data planes using the [`Mesh`](/mesh/mesh-multi-tenancy/#usage) resource. Compared to using one control plane per data plane, this option lowers the complexity and operational cost of supporting multiple meshes.

Here's a diagram that shows the {{site.mesh_product_name}} architecture :
{% mermaid %}
flowchart TB
    CP[Control plane]
      subgraph M[Mesh]
        direction LR
        subgraph S1[Service]
            subgraph DP1[Data plane]
                DPP1[Data plane proxy]
            end
        end
        subgraph S2[Service]
            subgraph DP2[Data plane]
                DPP2[Data plane proxy]
            end
        end
        DPP1 <--> DPP2
    end

    CP <----> DPP1 & DPP2
{% endmermaid %}

Data plane proxies handle two types of communication:
* Configuration retrieval from the control plane using the [Envoy **xDS** APIs](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol).
* Request proxying for all traffic to and from the service.

## Components

A minimal {{site.mesh_product_name}} deployment involves one or more instances of the control plane executable `kuma-cp`.
For each service in your mesh, you'll have one or more instances of the data plane proxy executable `kuma-dp`.

You can interact with the control plane via the command-line tool `kumactl`.

There are two modes that the {{site.mesh_product_name}} control plane can run in:

- `kubernetes`: Configure {{site.mesh_product_name}} via Kubernetes resources and {{site.mesh_product_name}} uses the Kubernetes API Server as the data store.
- `universal`: Configure {{site.mesh_product_name}} via the {{site.mesh_product_name}} API server and {{site.mesh_product_name}} resources.
  PostgreSQL serves as the data store.
  This mode works for any infrastructure other than Kubernetes, though you can also run a `universal` control plane on top of a Kubernetes cluster.

## Kubernetes mode

When running in Kubernetes mode, {{site.mesh_product_name}} stores all of its state and configuration on the underlying Kubernetes API Server.

Enable sidecar injection to add Pods to the mesh. {{site.mesh_product_name}} injects the `kuma-dp` sidecar container into any Pod configured for injection. The following label on a `Namespace` or `Pod` controls this behavior:

```
kuma.io/sidecar-injection: enabled
```

For more information, see:
* [{{site.mesh_product_name}} on Kubernetes](/mesh/data-plane-kubernetes/)
* [Kubernetes annotations](/mesh/annotations/)
* [Policies](/mesh/policies-introduction/)

### Services and Pods

#### Pods with Service

For all Pods associated with a Kubernetes `Service` resource, the {{site.mesh_product_name}} control plane automatically generates an annotation `kuma.io/service: <name>_<namespace>_svc_<port>` where `<name>`, `<namespace>` and `<port>` come from the `Service`. 

For example, the following resources generates `kuma.io/service: echo-server_kuma-test_svc_80`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-server
  namespace: kuma-test
  annotations:
    80.service.kuma.io/protocol: http
spec:
  ports:
    - port: 80
      name: http
  selector:
    app: echo-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-server
  namespace: kuma-test
  labels:
    app: echo-server
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: echo-server
  template:
    metadata:
      labels:
        app: echo-server
    spec:
      containers:
        - name: echo-server
          image: nginx
          ports:
            - containerPort: 80
```

#### Pods without Service

In some cases `Pods` don't belong to a corresponding `Service`.
This is typically because they don't expose any consumable services.
Kubernetes `Jobs` are a good example of this.

In this case, the {{site.mesh_product_name}} control plane generates a `kuma.io/service` tag with the format `<name>_<namespace>_svc`, where `<name>` and`<namespace>` come from the `Pod` resource itself.

The `Pods` created by the following example `Deployment` have the tag `kuma.io/service: echo-client_default_svc`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-client
  labels:
    app: echo-client
spec:
  selector:
    matchLabels:
      app: echo-client
  template:
    metadata:
      labels:
        app: echo-client
    spec:
      containers:
        - name: alpine
          image: "alpine"
          imagePullPolicy: IfNotPresent
          command: ["sh", "-c", "tail -f /dev/null"]
```

## Universal mode

When running in Universal mode, {{site.mesh_product_name}} requires a PostgreSQL database to store its state. You can use `kumactl` to interact with the {{site.mesh_product_name}} API server to manage policies. For more information, see [the PostgreSQL section](/mesh/control-plane-configuration/#postgresql) in the control plane configuration docs.
