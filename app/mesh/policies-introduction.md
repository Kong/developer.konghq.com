---
title: "Policies"
description: 'Learn how policies in {{site.mesh_product_name}} configure Data Plane proxies by defining rules for traffic behavior, proxy targeting, and merging strategies. This reference covers `targetRef`, directional policies, producer/consumer scopes, and shadow mode simulation.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - policy
  - service-mesh

related_resources:
  - text: Policy hub
    url: '/mesh/policies/'
  - text: Service meshes
    url: /mesh/service-mesh/

min_version:
  mesh: '2.10'
---
## What is a policy?

A [policy](/mesh/concepts#policy) is a set of configurations used to generate [data plane proxy](/mesh/concepts#data-plane-proxy--sidecar) configuration.
{{ site.mesh_product_name }} combines policies with the `Dataplane` resource to generate the Envoy configuration of a data plane proxy within a [mesh](/mesh/concepts#mesh).

## What do policies look like?

Like all [resources](/mesh/concepts#resource) in {{ site.mesh_product_name }}, a policy has two parts: the metadata and the spec.

### Metadata

Metadata identifies a policy by its `name`, `type`, and the `mesh` it belongs to:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

In Kubernetes, all our policies are implemented as [custom resource definitions (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) in the group `kuma.io/v1alpha1`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
spec: ... # spec data specific to the policy kind
```

By default, the policy is created in the `default` [mesh](/mesh/concepts#mesh).
You can specify the [mesh](/mesh/concepts#mesh) by using the `kuma.io/mesh` label.

For example:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: "my-mesh"
spec: ... # spec data specific to the policy kind
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: ExamplePolicy
name: my-policy-name
mesh: default
spec: ... # spec data specific to the policy kind
```

{% endnavtab %}
{% endnavtabs %}

### Spec

The `spec` field contains the actual configuration of the policy.

Some policies apply to only a subset of the configuration of the proxy.

- **Inbound policies** apply only to incoming traffic. Most inbound policies now use `spec.rules[]` to define their
  configuration.
  However, [`MeshTrafficPermission`](../meshtrafficpermission) and [`MeshFaultInjection`](../meshfaultinjection) still
  use the `spec.from[].targetRef` field,
  which defines the subset of clients that are going to be impacted by this policy.
- **Outbound policies** apply only to outgoing traffic. The `spec.to[].targetRef` field defines the outbounds that are
  going to be impacted by this policy.

The actual configuration is defined under the `default` field.

For example:
{% policy_yaml %}

```yaml
type: ExampleOutboundPolicy
name: my-example
mesh: default
spec:
  targetRef:
    kind: Mesh # policy applies to all proxies in the mesh
  to:
    - targetRef:
        kind: MeshService # only for requests destined for 'my-service'
        name: my-service
      default: # configuration that applies to selected requests on selected proxies
        key: value
---
type: ExampleInboundPolicy
name: my-example
mesh: default
spec:
  targetRef:
    kind: Dataplane # policy applies to proxies with 'app: my-app' label
    labels:
      app: my-app
    sectionName: httpport # only for inbound listener named 'httpport'
  rules:
    - default: # configuration that applies to selected inbound listeners on selected proxies
        key: value
```

{% endpolicy_yaml %}

Some policies are not directional and have neither `to` nor `rules`. Examples include [`MeshTrace`](/mesh/policies/meshtrace) and [`MeshProxyPatch`](/mesh/policies/meshproxypatch).
For example:

{% policy_yaml %}
```yaml
type: NonDirectionalPolicy
name: my-example
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    key: value
```
{% endpolicy_yaml %}

All specs have a **top-level `targetRef`** which identifies which proxies this policy applies to.
In particular, it defines which proxies have their Envoy configuration modified.

{:.info}
> One of the benefits of `targetRef` policies is that the spec is always the same between Kubernetes and Universal.
>
> This means that converting policies between Universal and Kubernetes only means rewriting the metadata.

## Writing a `targetRef`

`targetRef` is a concept borrowed from [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).
Its goal is to reference resources in a cluster.

It looks like:

```yaml
targetRef:
  kind: Mesh | Dataplane | MeshService | MeshExternalService | MeshMultiZoneService | MeshGateway
  name: my-name # On Kubernetes resources can be selected by name/namespace
  namespace: ns
  labels: # Alternative to name/namespace, labels can be used to select a group of resources
    key: value
  sectionName: ASection # This is used when trying to attach to a specific part of a resource (for example an inbound port of a `Dataplane`)
  tags: # Only for kind MeshGateway to select a set of listeners
    key: value
  proxyTypes: [ Sidecar, Gateway ] # Only for kind Mesh to apply to all proxies of a specific type
```

Consider the two example policies below:

{% policy_yaml use_meshservice=true %}

```yaml
type: MeshAccessLog
name: example-outbound
mesh: default
spec:
  targetRef: # top level targetRef
    kind: Dataplane
    labels:
      app: web-frontend
  to:
    - targetRef: # to level targetRef
        kind: MeshService
        name: web-backend
        namespace: kuma-demo
        sectionName: httpport
        _port: 8080
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```

{% endpolicy_yaml %}
{% policy_yaml %}

```yaml
type: MeshAccessLog
name: example-inbound
mesh: default
spec:
  targetRef: # top level targetRef
    kind: Dataplane
    labels:
      app: web-frontend
  rules:
    - default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```

{% endpolicy_yaml %}

Using `spec.targetRef`, this policy targets all proxies that have a label `app:web-frontend`.
It defines the scope of this policy as applying to traffic either from or to data plane proxies with the tag
`app:web-frontend`.

The `spec.to[].targetRef` section enables logging for any traffic going to `web-backend`.
The `spec.rules[]` section enables logging for any traffic coming on inbound listeners of the `web-frontend` proxies.

### Using a `sectionName`

The `targetRef.sectionName` field helps select specific sections within certain resource kinds:

* `Dataplane` – selects an inbound port
* `MeshService` – selects a port of the matching services
* `MeshMultiZoneService` – selects a port

To resolve `sectionName`, the following steps are applied:

1. Look for a section where the name matches `sectionName`.
2. If no match is found, try interpreting `sectionName` as a number and find a port with the same value—only if the port's name is unset.

#### Examples

Given a Dataplane resource with several inbound listeners:

```yaml
type: Dataplane
mesh: default
name: backend
labels:
  app: backend
networking:
  address: 192.168.0.2
  inbound:
    - name: backend-api
      port: 8080
      tags:
        kuma.io/service: backend
    - name: admin-api
      port: 5000
      tags:
        kuma.io/service: backend-admin
```

Inbound policies can attach to all inbound listeners:

{% policy_yaml %}

```yaml
type: MeshAccessLog
name: all-inbounds
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```

{% endpolicy_yaml %}

or just some inbound listeners:

{% policy_yaml %}

```yaml
type: MeshAccessLog
name: only-backend-api-inbound
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
    sectionName: backend-api
  rules:
    - default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```

{% endpolicy_yaml %}

### Omitting `targetRef`

When a `spec.targetRef` is not present, it is semantically equivalent to `spec.targetRef.kind: Mesh` and refers to
everything inside the `Mesh`.

### Applying to specific proxy types

The top-level `targetRef` field can select a specific subset of data plane proxies. The field named `proxyTypes` can
restrict policies to specific types of data plane proxies:

- `Sidecar`: Targets data plane proxies acting as sidecars to applications (including [delegated gateways](/mesh/ingress-gateway-delegated/)).
- `Gateway`: Applies to data plane proxies operating in [built-in Gateway](/mesh/built-in-gateway/) mode.
- Empty list: Defaults to targeting all data plane proxies.

#### Example

The following policy will only apply to gateway data-planes:
{% policy_yaml %}

```yaml
type: MeshTimeout
name: gateway-only-timeout
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: [ "Gateway" ]
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```

{% endpolicy_yaml %}

### Targeting gateways

Given a MeshGateway:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge
  namespace: {{site.mesh_namespace}}
conf:
  listeners:
    - port: 80
      protocol: HTTP
      tags:
        port: http-80
    - port: 443
      protocol: HTTPS
      tags:
        port: https-443
```

Policies can attach to all listeners:

{% policy_yaml %}

```yaml
type: MeshTimeout
name: timeout-all
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```

{% endpolicy_yaml %}

so that requests to either port 80 or 443 will have an idle timeout of 10 seconds,
or just some listeners:

{% policy_yaml %}

```yaml
type: MeshTimeout
name: timeout-8080
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge
    tags:
      port: http-80
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```

{% endpolicy_yaml %}

So that only requests to port 80 will have the idle timeout.

Note that depending on the policy,
there may be restrictions on whether or not specific listeners can be selected.

#### Routes

Read the [MeshHTTPRoute docs](/mesh/policies/meshhttproute/#gateways)
and [MeshTCPRoute docs](/mesh/policies/meshtcproute/#gateways) for more
on how to target gateways for routing traffic.

### Target kind support for different policies

Not every policy supports `to` and `rules` levels. Additionally, not every resource can
appear at every supported level. The specified top level resource can also affect which
resources can appear in `to` or `rules`.

To help users, each policy documentation includes tables indicating which `targetRef` kinds are supported at each level.
For each type of proxy, sidecar or builtin gateway, the table indicates for each
`targetRef` level, which kinds are supported.

#### Example tables

These are just examples, remember to check the docs specific to your policy.

<!-- vale off -->
{% navtabs "proxy-type" %}
{% navtab "Sidecar" %}

{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `Dataplane`, `MeshGateway`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService`"
{% endtable %}
<!-- vale on -->

The table above shows that we can select sidecar proxies via `Mesh`, `Dataplane`, `MeshGateway`.

We can use the policy as an _outbound_ policy with:

* `to[].targetRef.kind: Mesh` which will apply to all traffic originating at the sidecar _to_ anywhere
* `to[].targetRef.kind: MeshService` which will apply to all traffic _to_ specific services
* `to[].targetRef.kind: MeshExternalService` which will apply to all traffic _to_ specific external services
* `to[].targetRef.kind: MeshMultiZoneService` which will apply to all traffic _to_ specific multi-zone services

{% endnavtab %}

{% navtab "Builtin Gateway" %}

<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshGateway`, `MeshGateway` with `tags`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`Mesh`"
{% endtable %}
<!-- vale on -->

The table above indicates that we can select builtin gateway via `Mesh`, `MeshGateway` or even specific listeners with
`MeshGateway` using tags.

We can use the policy only as an _outbound_ policy with:

* `to[].targetRef.kind: Mesh` all traffic from the gateway _to_ anywhere.

{% endnavtab %}
{% endnavtabs %}


## Merging configuration

A proxy can be targeted by multiple `targetRef`s. To define how policies are merged, the following strategy is used:

We define a total order of policy priority. The table below defines the sorting order for resources in the cluster.
Sorting is applied sequentially by attribute, with ties broken using the next attribute in the list.

<!-- vale off -->
{% table %}
columns:
  - title: ""
    key: num
  - title: Attribute
    key: attribute
  - title: Order
    key: order
rows:
  - num: "1"
    attribute: "`spec.targetRef`"
    order: "* `Mesh` (less priority)<br>* `MeshGateway`<br>* `Dataplane`<br>* `Dataplane` with `labels`<br>* `Dataplane` with `labels/sectionName`<br>* `Dataplane` with `name/namespace`<br>* `Dataplane` with `name/namespace/sectionName`"
  - num: "2"
    attribute: "Origin<br>Label `kuma.io/origin`"
    order: "* `global` (less priority)<br>* `zone`"
  - num: "3"
    attribute: "Policy Role<br>Label `kuma.io/policy-role`"
    order: "* `system` (less priority)<br>* `producer`<br>* `consumer`<br>* `workload-owner`"
  - num: "4"
    attribute: "Display Name<br>Label `kuma.io/display-name`"
    order: "Inverted lexicographical order, i.e;<br>* `zzzzz` (less priority)<br>* `aaaaa1`<br>* `aaaaa`<br>* `aaa`"
{% endtable %}
<!-- vale on -->

For `to` and `rules` policies, we concatenate the arrays from each matching policy.
For `to` policies, we sort the concatenated arrays again based on the `spec.to[].targetRef` field:

<!-- vale off -->
{% table %}
columns:
  - title: ""
    key: num
  - title: Attribute
    key: attribute
  - title: Order
    key: order
rows:
  - num: "1"
    attribute: "`spec.to[].targetRef`"
    order: "* `Mesh` (less priority)<br>* `MeshService`<br>* `MeshService` with `sectionName`<br>* `MeshExternalService`<br>* `MeshMultiZoneService`"
{% endtable %}
<!-- vale on -->

We then build configuration by merging each level using [JSON patch merge](https://www.rfc-editor.org/rfc/rfc7386).

For example, if there are two `default` entries ordered this way:

```yaml
default:
  conf: 1
  sub:
    array: [ 1, 2, 3 ]
    other: 50
    other-array: [ 3, 4, 5 ]
---
default:
  sub:
    array: [ ]
    other-array: [ 5, 6 ]
    extra: 2
```

The merge result is:

```yaml
default:
  conf: 1
  sub:
    array: [ ]
    other: 50
    other-array: [ 5, 6 ]
    extra: 2
```

## Using policies with `MeshService`, `MeshMultiZoneService`, and `MeshExternalService`

[`MeshService`](/mesh/meshservice) is a feature to define services explicitly in {{ site.mesh_product_name }}.
It can be selectively enabled or disabled depending on the value of [meshServices.mode](/mesh/meshservice/#migration) on your Mesh object.

When using explicit services, `MeshServiceSubset` is no longer a valid kind and `MeshService` can only be used to select an actual `MeshService` resource (it can no longer select a `kuma.io/service`).

In the following example we'll assume we have a `MeshService`:

{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshService
name: my-service
labels:
  k8s.kuma.io/namespace: kuma-demo 
  kuma.io/zone: my-zone
  app: redis 
spec:
  selector:
    dataplaneTags:
      app: redis
      k8s.kuma.io/namespace: kuma-demo 
  ports:
  - port: 6739
    targetPort: 6739
    appProtocol: tcp
```
{% endpolicy_yaml %}

There are two ways to select a `MeshService`:

If you are in the same namespace (or same zone in Universal), you can select one specific service by using its explicit name:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis
  namespace: kuma-demo
spec:
  to:
  - targetRef:
      kind: MeshService
      name: redis
    default:
      connectionTimeout: 10s
```

You can also select all matching `MeshService` resources by labels:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: all-in-my-namespace 
  namespace: kuma-demo
spec:
  to:
  - targetRef:
      kind: MeshService
      labels:
        k8s.kuma.io/namespace: kuma-demo
    default:
      connectionTimeout: 10s
```

This is equivalent to writing a specific policy for each service that matches this label (one per matching service in each zone).

{:.info}
> When a `MeshService` has multiple ports, you can use `sectionName` to restrict the policy to a single port.

### Global, zonal, producer and consumer policies

Policies can be applied to a zone or to a namespace when using Kubernetes.
Policies never affect proxies beyond the scope in which they are defined.
In other words:

1. a policy applied to the global control plane will apply to all proxies in all zones.
2. a policy applied to a zone will only apply to proxies inside this zone. It is equivalent to having:
   ```yaml
   spec:
     targetRef: 
       kind: Dataplane
       labels:
         kuma.io/zone: "my-zone"
   ```
3. a policy applied to a namespace will only apply to proxies inside this namespace. It is equivalent to having:
   ```yaml
   spec:
     targetRef: 
       kind: Dataplane
       labels:
         kuma.io/zone: "my-zone"
         kuma.io/namespace: "my-ns"
   ```

There is, however, one exception to this when using `MeshService` with **outbound** policies (policies with
`spec.to[].targetRef`).
In this case, if you define a policy in the same namespace as the `MeshService` it is defined in, that policy will be
considered a **producer** policy.
This means that all clients of this service (even in different zones) will be impacted by this policy.

An example of a producer policy is:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshService
        name: redis
      default:
        connectionTimeout: 10s
```

The other type is a consumer policy, which most commonly uses labels to match a service.

An example of a consumer policy that would override the previous producer policy:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis-consumer
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/service-name: redis
      default:
        connectionTimeout: 10s
```

{:.info}
> Remember that `labels` on a `MeshService` applies to _each_ matching `MeshService`. To communicate to services
> named the same way in different namespaces or zones with different configuration, use a more specific set of labels.

{{ site.mesh_product_name }} adds a label `kuma.io/policy-role` to identify the type of the policy. The values of the
label are:

- **system**: Policies defined on global or in the zone's system namespace
  `spec.rules`
- **consumer**: Policies defined in a non-system namespace that have `spec.to` which either do not use `name` or have a
  different `namespace`
- **producer**: Policies defined in the same namespace as the services identified in the `spec.to[].targetRef`

### Example

We have 2 clients client1 and client2 they run in different namespaces respectively ns1 and ns2.

{% mermaid %}
flowchart LR
subgraph ns1
    client1(client)
end
subgraph ns2
  client2(client)
  server(MeshService: server)
end
client1 --> server
client2 --> server
{% endmermaid %}

First, define a producer policy:
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
    name: producer-policy
    namespace: ns2
spec:
  to:
    - targetRef:
        kind: MeshService
        name: server
      default:
        idleTimeout: 20s
```

This is a producer policy because it is defined in the same namespace as the `MeshService: server` and references that service in its `spec.to[].targetRef`.
Both client1 and client2 receive the timeout of 20 seconds.

Next, create a consumer policy:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: consumer-policy
  namespace: ns1
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/service-name: server
      default:
        idleTimeout: 30s
```

This policy only affects client1, as client2 doesn't run in ns1. As consumer policies have a higher priority than producer policies, client1 will have an `idleTimeout: 30s`.

To also configure client2, define another consumer policy:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: consumer-policy
  namespace: ns2
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/service-name: server
      default:
        idleTimeout: 40s
```

The only difference is the namespace: this policy is defined in `ns2` rather than `ns1`.

{:.info}
> Use labels for consumer policies and name for producer policies.
> It will be easier to differentiate between producer and consumer policies.

## Examples

#### Applying a global default

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        key: value
```

All traffic from any proxy (top-level `targetRef`) going to any proxy (to `targetRef`) will have this policy applied with value `key=value`.

#### Recommending to users

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: my-service
      default:
        key: value
```

All traffic from any proxy (top-level `targetRef`) going to the service "my-service" (to `targetRef`) will have this policy applied with value `key=value`.

This is useful when a service owner wants to suggest a set of configurations to its clients.

#### Configuring all proxies of a team

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      team: "my-team"
  rules:
    - default:
        key: value
```

All inbound traffic to any proxy with the tag `team=my-team` (top-level `targetRef`) will have this policy applied with value `key=value`.

This is a useful way to define coarse-grained rules, for example.

#### Configuring all proxies in a zone

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/zone: "east"
  default:
    key: value
```

All proxies in zone `east` (top-level `targetRef`) will have this policy configured with `key=value`.

This can be very useful when observability stores are different for each zone, for example.

#### Configuring all gateways in a Mesh

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: ["Gateway"]
  default:
    key: value
```

All gateway proxies in mesh `default` will have this policy configured with `key=value`.

This can be very useful when timeout configurations for gateways need to differ from those of other proxies.

## Applying policies in shadow mode

### Overview

Shadow mode allows users to mark policies with a specific label to simulate configuration changes
without affecting the live environment.
It lets you safely observe the potential impact on Envoy proxy configurations before committing changes.

### Recommended setup

It's not necessary, but CLI tools like [jq](https://jqlang.github.io/jq/) and [jd](https://github.com/josephburnett/jd) can greatly improve working with {{ site.mesh_product_name }} resources.

### How to use shadow mode

1. Before applying the policy, add a `kuma.io/effect: shadow` label.

2. Check the proxy config with shadow policies taken into account through the {{site.mesh_product_name}} API. By using HTTP API:
    ```shell
    curl http://localhost:5681/meshes/${mesh}/dataplane/${dataplane}/_config?shadow=true
    ```
   or by using `kumactl`:
    ```shell
    kumactl inspect dataplane ${name} --type=config --shadow
    ```

3. Check the diff in [JSON Patch](https://jsonpatch.com/) format through the {{site.mesh_product_name}} API. By using HTTP API:
    ```shell
    curl http://localhost:5681/meshes/${mesh}/dataplane/${dataplane}/_config?shadow=true&include=diff
    ```
   or by using `kumactl`:
    ```shell
    kumactl inspect dataplane ${name} --type=config --shadow --include=diff
    ```

### Limitations and Considerations

Currently, the {{site.mesh_product_name}} API mentioned above works only on Zone CP.
Attempts to use it on Global CP lead to `405 Method Not Allowed`.
This might change in the future.

### Examples

Apply policy with `kuma.io/effect: shadow` label:

{% policy_yaml use_meshservice=true %}
```yaml
type: MeshTimeout
name: frontend-timeouts
mesh: default
labels:
  kuma.io/effect: shadow
spec:
   targetRef:
     kind: MeshSubset
     tags:
       kuma.io/service: frontend
   to:
   - targetRef:
       kind: MeshService
       name: backend
       namespace: kuma-demo
       sectionName: httpport
       _port: 3001
     default:
       idleTimeout: 23s
```
{% endpolicy_yaml %}

Check the diff using `kumactl`:

```shell
$ kumactl inspect dataplane frontend-dpp --type=config --include=diff --shadow | jq '.diff' | jd -t patch2jd
@ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","backend_kuma-demo_svc_3001","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","idleTimeout"]
- "3600s"
@ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","backend_kuma-demo_svc_3001","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","idleTimeout"]
+ "23s"
```

The output not only identifies the exact location in Envoy where the change will occur, but also shows the current value that would be replaced.
