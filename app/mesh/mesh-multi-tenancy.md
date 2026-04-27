---
title: 'Configuring your Mesh and multi-tenancy'
description: 'Learn how to create and configure isolated service meshes using the Mesh resource in {{site.mesh_product_name}}, supporting multi-tenancy and gradual adoption.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.6'

tags:
  - service-mesh

related_resources:
  - text: Data plane proxy
    url: '/mesh/data-plane-proxy/'
  - text: Mesh Observability
    url: '/mesh/observability/'
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: Install {{site.mesh_product_name}}
    url: /mesh/#install-kong-mesh
---

The `Mesh` resource lets you create multiple isolated service meshes within the same {{site.mesh_product_name}} cluster, making it straightforward to operate in environments that require more than one mesh for security, segmentation, or governance reasons.

You can create a `Mesh` per line of business, per team, per application, or per environment. Multiple meshes allow organizations to adopt a service mesh gradually without requiring all teams to coordinate, and provide an extra layer of security and segmentation. For example, policies applied to one `Mesh` don't affect another `Mesh`.

`Mesh` is the parent resource of every other resource in {{site.mesh_product_name}}, including:

* [Data plane proxies](/mesh/data-plane-proxy/)
* [Policies](/mesh/policies/)

In order to use {{site.mesh_product_name}} at least one `Mesh` must exist, and there is no limit to the number of Meshes that can be created. When a data plane proxy connects to the control plane (`kuma-cp`), it specifies which `Mesh` resource it belongs to. A data plane proxy can only belong to one `Mesh` at a time.

{:.info}
> When starting a new {{site.mesh_product_name}} cluster from scratch, a `default` Mesh is created automatically.

In addition to creating virtual service meshes, the `Mesh` resource is also used for:

* [Mutual TLS](/mesh/policies/mutual-tls/), to secure and encrypt our service traffic and assign an identity to the data plane proxies within the Mesh.
* [Zone Egress](/mesh/zone-egress/), to setup if `ZoneEgress` should be used for cross zone and external service communication.
* [Non-mesh traffic](/mesh/policies/meshpassthrough/), to setup if `passthrough` mode should be used for the non-mesh traffic.

To support cross-mesh communication an intermediate API Gateway must be used. See [{{site.mesh_product_name}}'s builtin gateway](/mesh/ingress/) to set this up.

{:.info}
> Previously, observability and locality awareness were configured within the `Mesh` object.
>
> However, for enhanced flexibility and granular control, these configurations have been extracted into separate policies:
> [`MeshAccessLog`](/mesh/policies/meshaccesslog/), [`MeshTrace`](/mesh/policies/meshtrace/) and [`MeshMetric`](/mesh/policies/meshmetric/) for observability, and [`MeshLoadBalancingStrategy`](/mesh/policies/meshloadbalancingstrategy/) for locality awareness.
>
> This separation allows for more fine-grained adjustments of each aspect, ensuring that observability and locality awareness are tailored to specific requirements.

## Usage

The easiest way to create a `Mesh` is to specify its `name`. The name of a Mesh must be unique.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
```

Apply the configuration with `kubectl apply -f [..]`.
{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
```

Apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/mesh/interact-with-control-plane/).
{% endnavtab %}
{% endnavtabs %}

## Creating resources in a Mesh

You can specify which `Mesh` other resources belong to in the following ways.

### Data plane proxies

When starting a data plane proxy, specify which `Mesh` it belongs to:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}
By using the `kuma.io/mesh` annotation in a `Deployment`, like:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        # indicate to {{site.mesh_product_name}} what is the Mesh that the data plane proxy belongs to
        kuma.io/mesh: default
    spec:
      containers:
        ...
```

A `Mesh` may span multiple Kubernetes namespaces. Any {{site.mesh_product_name}} resource in the cluster which
specifies a particular `Mesh` will be part of that `Mesh`.

{:.warning}
> {% new_in 2.13 %}
> **namespace-mesh constraint:** A single Kubernetes namespace cannot contain pods in multiple meshes. This limitation exists because [Workload](/mesh/data-plane-kubernetes/) resources are mesh-scoped and generated from the `app.kubernetes.io/name` label, which can cause resource collisions when the same workload name is used across different meshes in the same namespace.
>
> When {{site.mesh_product_name}} detects multiple meshes in a single namespace, it:
>
> * Emits a Kubernetes warning event on the namespace
> * Skips Workload resource generation for affected workloads
> * Logs an error message
>
> To prevent this configuration issue proactively, you can enable the runtime flag [`runtime.kubernetes.disallowMultipleMeshesPerNamespace`](/mesh/reference/kuma-cp/) (disabled by default). When enabled, the admission webhook rejects pod creation or updates if the namespace already contains Dataplanes in a different mesh.
>
> **Best practice:** Keep all pods in a single namespace within the same mesh.

{% endnavtab %}
{% navtab "Universal" %}

By using the `-m` or `--mesh` argument when running `kuma-dp`, for example:

```sh
kuma-dp run \
  --name=backend-1 \
  --mesh=default \
  --cp-address=https://127.0.0.1:5678 \
  --dataplane-token-file=/tmp/kuma-dp-backend-1-token
```

{% endnavtab %}
{% endnavtabs %}

You can control which data plane proxies are allowed to join the mesh using [mesh constraints](/mesh/configure-data-plane-proxy-membership/).

### Policies

When creating new [Policies](/mesh/policies/), you must also specify which `Mesh` they belong to:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}
By using the `kuma.io/mesh` label, like:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: route-1
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # indicate to {{site.mesh_product_name}} what is the Mesh that the resource belongs to
spec:
  ...
```

{{site.mesh_product_name}} consumes all [Policies](/mesh/policies/) on the cluster and joins each to an individual `Mesh`, identified by this property.
{% endnavtab %}
{% navtab "Universal" %}
By using the `mesh` property, like:

```yaml
type: MeshHTTPRoute
name: route-1
mesh: default # indicate to {{site.mesh_product_name}} what is the Mesh that the resource belongs to
...
```

{% endnavtab %}
{% endnavtabs %}

## Skipping default resource creation

By default, to help users get started we create the following default policies:

{% policy_yaml %}

```yaml
type: MeshTimeout
mesh: default
name: mesh-gateways-timeout-all-default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: [Gateway]
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 1h
        http:
          streamIdleTimeout: 5s
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 5m
        http:
          streamIdleTimeout: 5s
          requestHeadersTimeout: 500ms
---
type: MeshTimeout
mesh: default
name: mesh-timeout-all-default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: [Sidecar]
  to:
    - targetRef:
        kind: Mesh
      default:
        connectionTimeout: 5s
        idleTimeout: 1h
        http:
          requestTimeout: 15s
          streamIdleTimeout: 30m
  from:
    - targetRef:
        kind: Mesh
      default:
        connectionTimeout: 10s
        idleTimeout: 2h
        http:
          requestTimeout: 0s
          streamIdleTimeout: 1h
          maxStreamDuration: 0s
---
type: MeshRetry
mesh: default
name: mesh-retry-all-default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        tcp:
          maxConnectAttempt: 5
        http:
          numRetries: 5
          perTryTimeout: 16s
          backOff:
            baseInterval: 25ms
            maxInterval: 250ms
        grpc:
          numRetries: 5
          perTryTimeout: 16s
          backOff:
            baseInterval: 25ms
            maxInterval: 250ms
---
type: MeshCircuitBreaker
mesh: default
name: mesh-circuit-breaker-all-default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        connectionLimits:
          maxConnections: 1024
          maxPendingRequests: 1024
          maxRetries: 3
          maxRequests: 1024
```

{% endpolicy_yaml %}

To prevent these policies from being added when creating a mesh, set `skipCreatingInitialPolicies`:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  skipCreatingInitialPolicies: ['*']
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
skipCreatingInitialPolicies: ['*']
```

{% endnavtab %}
{% endnavtabs %}

You can also skip creating the default mesh by setting the control plane configuration: `KUMA_DEFAULTS_SKIP_MESH_CREATION=true`.

## All options

{% json_schema Mesh type=proto %}
