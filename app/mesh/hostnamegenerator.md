---
title: HostnameGenerator
description: Customize hostnames for MeshService resources using templated HostnameGenerator resources.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: MeshMultiZoneService
    url: '/mesh/meshmultizoneservice/'
  - text: MeshService
    url: '/mesh/meshservice/'
  - text: MeshExternalService
    url: '/mesh/meshexternalservice/'
min_version:
  mesh: '2.9'
---


The `HostnameGenerator` resource provides:

- A template to generate hostnames from properties of `MeshServices`, `MeshMultiZoneService`, and `MeshExternalServices` resources.
- A selector that defines for which `MeshServices`, `MeshMultiZoneService`, and `MeshExternalServices` this generator runs.

## Defaults

{{site.mesh_product_name}} ships with default `HostnameGenerator` resources based on the control plane mode and storage type.

### Local MeshService in Universal zone

The following resource is automatically created on a zone control plane running in Universal mode.
It creates a hostname for each `MeshService` created in a zone.
For example, for a `MeshService` named `redis`, {{site.mesh_product_name}} creates a `redis.svc.mesh.local` hostname.

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: local-universal-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.svc.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}


### Local MeshExternalService

The following resource is automatically created on a zone control plane.
It creates a hostname for each `MeshExternalService` created in a zone.
For example, for a `MeshExternalService` named `aurora`, {{site.mesh_product_name}} creates a `aurora.extsvc.mesh.local` hostname.

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: local-mesh-external-service
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.extsvc.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}


### Synced MeshService from Kubernetes zone

The following resources are automatically created on a global control plane and synced to all zones.

The first creates a hostname for each `MeshService` synced from another Kubernetes zone.
For example, for a `MeshService` named `redis` with the namespace `redis-system` from zone `east`, {{site.mesh_product_name}} creates a `redis.redis-system.svc.east.mesh.local` hostname.

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-kube-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        k8s.kuma.io/is-headless-service: false
        kuma.io/env: kubernetes
  template: "{% raw %}{{ .DisplayName }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

The second creates a hostname for each `MeshService` synced from another Kubernetes zone that were created from a headless `Service`.
For example, for a Pod `redis-0` with `MeshService` named `redis`, with the namespace `redis-system` from zone `east`, {{site.mesh_product_name}} creates a `redis-0.redis.redis-system.svc.east.mesh.local` hostname.

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-headless-kube-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        k8s.kuma.io/is-headless-service: true
        kuma.io/env: kubernetes
  template: "{% raw %}{{ label 'statefulset.kubernetes.io/pod-name' }}.{{ label 'k8s.kuma.io/service-name' }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

### Synced MeshService from Universal zone

The following policy is automatically created on a global control plane and synced to all zones.
It creates a hostname for each `MeshService` synced from another Universal zone.
For example, for a `MeshService` named `redis` from zone `west`, {{site.mesh_product_name}} creates a `redis.svc.west.mesh.local` hostname.

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-universal-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        kuma.io/env: universal
  template: "{% raw %}{{ .DisplayName }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

### Synced MeshMultiZoneService from a global control plane

The following policy is automatically created on a global control plane and synced to all zones.
It creates a hostname for each `MeshMultiZoneService` synced from a global control plane.
For example, for a `MeshMultiZoneService` named `redis`, {{site.mesh_product_name}} creates a `redis.mzsvc.mesh.local` hostname:

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-mesh-multi-zone-service
spec:
  selector:
    meshMultiZoneService:
      matchLabels:
        kuma.io/origin: global
  template: "{% raw %}{{ .DisplayName }}.mzsvc.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

### Synced MeshExternalService from a global control plane

The following policy is automatically created on a global control plane and synced to all zones.
It creates a hostname for each `MeshExternalService` synced from a global control plane.
For example, for a `MeshExternalService` named `aurora`, {{site.mesh_product_name}} creates a `aurora.extsvc.mesh.local` hostname.

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-mesh-external-service
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: global
  template: "{% raw %}{{ .DisplayName }}.extsvc.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}


## Template

A template is a [Golang text template](https://pkg.go.dev/text/template).
It runs with the function `label` to retrieve labels from the `MeshService`, `MeshMultiZoneService`, or `MeshExternalService` resources,
as well as the following attributes:
* `.DisplayName`: The name of the resource in its original zone.
* `.Namespace`: The namespace of the resource in its original zone on Kubernetes
* `.Zone`: The zone of the resource.
* `.Mesh`: The mesh of the resource.

For example, with the following `MeshService`:

```yaml
kind: MeshService
metadata:
  name: redis
  namespace: kuma-demo
  labels:
    kuma.io/mesh: products
    team: backend
    k8s.kuma.io/service-name: redis
    k8s.kuma.io/namespace: kuma-demo
```

If you use the template `"{% raw %}{{ .DisplayName }}.{{ .Namespace }}.{{ .Mesh }}.{{ label "team" }}.mesh.local{% endraw %}"`, you would get the hostname `redis.kuma-demo.products.backend.mesh.local`.

The generated hostname points to the first VIP known for the `MeshService`.

## Status

Every generated hostname is recorded under the `MeshService` resource's status, in the `addresses` field:

```yaml
status:
  addresses:
    - hostname: redis.kuma-demo.svc.east.mesh.local
      origin: HostnameGenerator
      hostnameGeneratorRef:
        coreName: synced-kube-mesh-service
```

