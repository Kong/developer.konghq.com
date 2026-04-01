---
title: MeshService
description: Define and manage Services within the mesh, replacing kuma.io/service tags for clearer Service targeting and routing.

content_type: reference
layout: reference
products:
    - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
  - text: DNS
    url: /mesh/dns/
  - text: Resource sizing guidelines
    url: /mesh/resource-sizing-guidelines/
  - text: Version compatibility
    url: /mesh/version-compatibility/

min_version:
    mesh: '2.9'
---

A `MeshService` represents a destination for traffic from elsewhere in a mesh. 
It defines which `Dataplane` objects serve this traffic as well as what ports are available. 
It also holds information about which IPs and hostnames can be used to reach this destination.

`MeshService` replaces the `Dataplane` tag `kuma.io/service`. It's similar to the Kubernetes `Service` resource.

Here's an example of a `MeshService`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshService
name: redis
mesh: default
labels:
  team: db-operators
spec:
  selector:
    dataplaneTags: # tags in Dataplane object
      app: redis
      k8s.kuma.io/namespace: kong-mesh-demo # added automatically
  ports:
  - port: 6739
    targetPort: 6739
    appProtocol: tcp
  - name: some-port
    port: 16739
    targetPort: target-port-from-container # name of the inbound
    appProtocol: tcp
status:
  addresses:
  - hostname: redis.mesh
    origin: HostnameGenerator
    hostnameGeneratorRef:
      coreName: kmy-hostname-generator
  vips:
  - ip: 10.0.1.1 # {{site.mesh_product_name}} VIP or Kubernetes cluster IP
```
{% endpolicy_yaml %}

## Zone types

The way users interact with `MeshServices` depends on the type of zone.
In both cases, the resource is generated automatically.

### Kubernetes

On Kubernetes, `Service` already provides a number of the features provided by `MeshService`. For this reason, {{site.mesh_product_name}} generates `MeshService` resources from the `Service` resources and:

* Reuses VIPs in the form of cluster IPs.
* Uses Kubernetes DNS names.

In most cases, Kubernetes users don't create `MeshService` resources.

### Universal

On Universal, `MeshService` resources are generated based on the `kuma.io/service` value of the `inbounds` parameter in the `Dataplane` resources. 
The name of the generated `MeshService` is derived from the value of the `kuma.io/service` tag and has one port that corresponds to the given inbound. 
If the inbound doesn't have a name, one is generated from the `port` value.

The only restriction in this case is that the port numbers must match. 

For example, with a `Dataplane` configure with the following inbound:

```yaml
inbound:
- name: main
  port: 80
  tags:
    kuma.io/service: test-server
```

{{site.mesh_product_name}} would create the following `MeshService`:

```yaml
type: MeshService
name: test-server
spec:
  ports:
  - port: 80
    targetPort: 80
    name: main
  selector:
    dataplaneTags:
      kuma.io/service: test-server
```

However, if you create another `Dataplane` with the following configuration, {{site.mesh_product_name}} can't combine the two inbounds into a single coherent `MeshService` for `test-server`:

```yaml
inbound:
- name: main
  port: 8080
  tags:
    kuma.io/service: test-server
```

## Hostnames

The [`HostnameGenerator` resource](/mesh/hostnamegenerator/) is used to manage hostnames for `MeshService` resources. The `VirtualOutbound` policy isn't supported by the `MeshService` resource.

## Ports

The `ports` field lists the ports exposed by the `Dataplane` resources that the `MeshService` matches. 
`targetPort` can refer to a port directly or by the name of the `Dataplane` port:

```yaml
ports:
- name: redis-non-tls
  port: 16739
  targetPort: 6739
  appProtocol: tcp
```

## Multi-zone

The main difference between `kuma.io/service` and `MeshService` at the data plane level is that traffic to a `MeshService` always goes to a specific zone. It may be the local zone or a remote zone.

With `kuma.io/service`, this behavior depends on the [locality awareness](/mesh/policies/meshloadbalancingstrategy/#localityawareness) setting. If it's not enabled, traffic is load-balanced equally between zones. If it is enabled, destinations in the local zone are prioritized.

When migrating from `kuma.io/service`, you must choose between:

* Moving to a `MeshService`, either from the local zone or one synced from a remote zone.
* Moving to a [`MeshMultiZoneService`](/mesh/meshmultizoneservice/) to keep the same behavior.

For more information, see the [migration](#migration) section.

## Targeting

The following sections describe how to configure other resources to target a `MeshService`.

### Policy

You can use a `MeshService` resource as the destination target of a policy by setting `to[].targetRef`:

```yaml
spec:
  to:
  - targetRef:
      kind: MeshService
      name: test-server
      namespace: test-app
      sectionName: main
```

With this configuration, the policy targets requests to the given `MeshService` and port with the name `main`.
Only Kubernetes zones can reference using `namespace`, which always selects resources in the local zone.

### Route

In order to direct traffic to a given `MeshService`, you must reference it with `backendRefs`:

```yaml
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: test-server
        namespace: test-app
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /v2
          default:
            backendRefs:
              - kind: MeshService
                name: test-server-v2
                namespace: test-app
                port: 80
```

In `backendRefs`, ports can be optionally referred to by their number.

### Labels

Instead of referencing a `MeshService` by name, you can use labels.
This is useful if you want to select a `MeshService` from other zones, or select multiple `MeshService` resources.

{:.info}
> With `backendRefs`, only one resource can be selected.

Here's a configuration example that can be used under `targetRef` or `backendRefs`:

```yaml
- kind: MeshService
  labels:
    kuma.io/display-name: test-server-v2
    k8s.kuma.io/namespace: test-app
    kuma.io/zone: east
```

In this case, the entry selects resources with the display name `test-server-v2` from the `east` zone in the `test-app` namespace.
Only one resource will be selected.

However, if you leave out the namespace, any resource named `test-server-v2` in the `east` zone is selected, regardless of its namespace:

```yaml
- kind: MeshService
  labels:
    kuma.io/display-name: test-server-v2
    kuma.io/zone: east
```

## Migration

`MeshService` is opt-in and involves a migration process. 
Every `Mesh` must enable `MeshService` resources using the `spec.meshServices.mode` parameter. It can be set to `Disabled`, [`Everywhere`](#everywhere), [`ReachableBackends`](#reachablebackends), or [`Exclusive`](#exclusive).

The biggest change with `MeshService` is that traffic is no longer load-balanced between all zones. 
Traffic sent to a `MeshService` is only ever sent to a single zone.

The goal of migration is to stop using `kuma.io/service` entirely and instead use `MeshService` resources as destinations and as `targetRef` in policies and `backendRef` in Routes.

After enabling `MeshService` resources, the control plane generates additional resources, based on the specified mode.

### Options

#### Everywhere

This enables `MeshService` resource generation everywhere.
Both `kuma.io/service` and `MeshService` are used to generate the Envoy resources, Envoy Clusters, and `ClusterLoadAssignments`. 
Having both enabled results in about twice as many resources, which means potentially hitting the resource limits of the control plane and memory usage in the data plane, before reachable backends would otherwise be necessary.

#### ReachableBackends

This enables automatic generation of the `MeshService` resources, but does not include the corresponding resources for every data plane proxy.
The intention is for users to explicitly and gradually introduce relevant `MeshService` resources via [`reachableBackends`](/mesh/configure-transparent-proxying/#reachable-backends).

#### Exclusive

This is the end goal of the migration. 
Destinations in the mesh are managed solely with `MeshService` resources and no longer via `kuma.io/service` tags and `Dataplane` inbounds. 
In the future this will be the default behavior.

### Migration steps

1. Decide whether you want to set `mode: Everywhere` or enable `MeshService` consumer by consumer with `mode: ReachableBackends`.
1. For every `kuma.io/service`, decide how it should be migrated:
  * As `MeshService`: Only ever from one single zone. These are created automatically.
  * As `MeshMultiZoneService`: Combined with all same Services in other zones. These have to be created manually.
1. Update your `MeshHTTPRoutes`/`MeshTCPRoutes` to refer to the `MeshService`/`MeshMultiZoneService` directly.
1. Set `mode: Exclusive` to stop receiving configuration based on `kuma.io/service`.
1. Update `targetRef.kind: MeshService` references to use the real name of the `MeshService`, as opposed to the `kuma.io/service`. This is not strictly required.
