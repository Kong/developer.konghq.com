---
title: "Policies"
description: 'Learn how to write and configure policies in {{ site.mesh_product_name }}, including policy roles, targetRef, and merging strategies.'
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
  mesh: '2.13'
---

Policies in {{ site.mesh_product_name }} let you declare how traffic and workloads should behave, instead of configuring each [data plane proxy](/mesh/data-plane-proxy/) manually.
They're the main way to enable features like mTLS, traffic permissions, retries, rate limits, access logging, and more.

Every policy follows the same pattern:

* Target: which workloads the policy applies to (`targetRef`)
* Direction: whether it controls outbounds (`to`) or inbounds (`rules`)
* Behavior: the actual configuration (`default`) applied to the traffic

For example, this is a policy that configures timeouts:

```yaml
type: MeshTimeout
name: my-app-timeout
mesh: default
spec:
  targetRef: # Target: the policy applies only to workloads with label `app: my-app`
    kind: Dataplane
    labels:
      app: my-app
  to: # Direction: the policy applies to outbound listeners for the `database` MeshService
    - targetRef:
        kind: MeshService
        name: database
        namespace: database-ns
        sectionName: "443"
      default: # Behavior: the policy sets connection and idle timeouts
        connectionTimeout: 10s
        idleTimeout: 30m
```

## Policy roles

Depending on where a policy is created (in an application namespace, the system namespace, or on the global control plane)
and how its schema is structured, {{ site.mesh_product_name }} assigns it a policy role.
A policy's role determines how it's synchronized in multi-zone deployments and how it's prioritized when multiple policies overlap.

The table below introduces the policy roles and how to recognize them.

<!-- vale off -->
{% table %}
columns:
  - title: "Policy role"
    key: role
  - title: "Controls"
    key: controls
  - title: "Type by schema"
    key: schema
  - title: "Multi-zone sync"
    key: sync
rows:
  - role: "[Producer](#producer-policies)"
    controls: "Outbound behavior of callers to your service (your clients' egress toward you)."
    schema: "Has `spec.to`. Every `to[].targetRef.namespace`, if set, must be equal to `metadata.namespace`."
    sync: "Defined in the app's namespace on a zone CP. Synced to the global CP, then propagated to other zones."
  - role: "[Consumer](#consumer-policies)"
    controls: "Outbound behavior of your service when calling others (your egress)."
    schema: "Has `spec.to`. At least one `to[].targetRef.namespace` is different from `metadata.namespace`."
    sync: "Defined in the app's namespace on a zone CP. Synced to the global CP."
  - role: "[Workload-owner](#workload-owner-policies)"
    controls: "Configuration of your own proxy: inbound traffic handling and sidecar features (for example metrics, traces)."
    schema: "Either has `spec.rules`, or has neither `spec.rules` nor `spec.to` (only `spec.targetRef` + proxy/sidecar settings)."
    sync: "Defined in the app's namespace on a zone CP. Synced to the global CP."
  - role: "[System](#system-policies)"
    controls: "Mesh-wide behavior: can govern both inbound and outbound across services (operator-managed)."
    schema: "Resource is created in the system namespace (for example `{{ site.mesh_namespace }}`)."
    sync: "Created in the system namespace, either on a zone CP or on the global CP."
{% endtable %}
<!-- vale on -->

### Producer policies

Producer policies allow service owners to define recommended client-side behavior for calls to their service by creating the policy in their service's own namespace.
{{ site.mesh_product_name }} then applies it automatically to the outbounds of client workloads.
This lets backend owners publish sensible defaults (timeouts, retries, limits) for consumers,
while individual clients can still refine those settings with their own [consumer](#consumer-policies) policies.

The following policy tells {{ site.mesh_product_name }} to apply 3 retries with a backoff from `15s` to `1m`
on 5xx errors to any client calling `backend`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  namespace: backend-ns # created in the backend's namespace
  name: backend-producer-timeouts
spec:
  targetRef:
    kind: Mesh # any caller
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: backend-ns # same namespace as the policy (producer rule)
      default:
        numRetries: 3
        backOff:
          baseInterval: 15s
          maxInterval: 1m
        retryOn:
          - 5xx
```

### Consumer policies

Consumer policies let service owners adjust how their workloads call other services.
They are created in the client's namespace and applied to that client's outbounds.
This way, the service owner can fine-tune retries, timeouts, or other settings for the calls their workloads make.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  namespace: frontend-ns # created in the namespace of a client
  name: backend-consumer-timeouts
spec:
  targetRef:
    kind: Mesh # any caller, but only in 'frontend-ns' since consumer policies are always scoped to the namespace of origin
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: backend-ns # different namespace from the policy (consumer rule)
      default:
        numRetries: 0
```

### Workload-owner policies

Workload-owner policies let service owners configure their own workload's proxies.
They are created in the workload's namespace and control how proxies handle inbound traffic,
while also enabling various proxy-level features such as `MeshMetric`, `MeshProxyPatch`, and others.

Workload-owner policies either have `spec.rules` for inbound traffic configuration:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: backend-ns # created in the namespace of a server
  name: backend-permissions
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        deny:
          - spiffeID:
              type: Exact
              value: spiffe://trust-domain.mesh/ns/default/sa/legacy
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://trust-domain.mesh/
```

Or only `spec.default` for proxy-level features like metrics and tracing:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: otel-metrics-delegated
  namespace: backend-ns
spec:
  default:
    sidecar:
      profiles:
        appendProfiles:
          - name: All
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: opentelemetry-collector.mesh-observability.svc:4317
          refreshInterval: 30s
```

### System policies

System policies provide mesh-wide defaults managed by platform operators.
Any policy can be a system policy as long as it's created in the system namespace (`{{ site.mesh_namespace }}` by default) on either a zone control plane or the global control plane.

## Referencing data planes, services, and routes inside policies

{{ site.mesh_product_name }} provides an API for cross-referencing policies and other resources called `targetRef`:

```yaml
targetRef:
  kind: Dataplane
  labels:
    app: my-app
```

`targetRef` appears in all policy definitions wherever configuration needs to be associated with resources such as `MeshService`, `MeshExternalService`, `Dataplane`, and others.

The `targetRef` API follows the same principles regardless of the policy type:

* `targetRef.kind` must always refer to a resource that exists in the cluster.
* A resource can be referenced either by `name` and `namespace` or by `labels`. Using `name` and `namespace` creates an unambiguous reference to a single resource, while using `labels` can match multiple resources.
* `targetRef.namespace` is optional and defaults to the namespace of the policy.
* System policies must always use `targetRef.labels`.
* When supported by the target resource, `sectionName` may reference a specific section rather than the entire resource (for example, `MeshService`, `MeshMultiZoneService`, `Dataplane`).
* `sectionName` is resolved by first matching a section name, and if no match is found, by interpreting it as a numeric port value (if the port name is unset).

The set of valid `targetRef.kind` values is the same across all policies:

<!-- vale off -->
{% table %}
columns:
  - title: "Field"
    key: field
  - title: "Available Kinds"
    key: kinds
rows:
  - field: "`spec.targetRef`"
    kinds: |
      * `Mesh`
      * `Dataplane`
  - field: "`spec.to[].targetRef`"
    kinds: |
      * `MeshService`
      * `MeshMultiZoneService`
      * `MeshExternalService`
      * `MeshHTTPRoute` (if the policy supports per-route configuration)
{% endtable %}
<!-- vale on -->

## How policies are combined

When multiple policies target the same proxy, {{ site.mesh_product_name }} merges them using a priority-based strategy.

Policy priority is determined by a total ordering of attributes. The table below defines the sorting order, applied sequentially with ties broken by the next attribute in the list.

<!-- vale off -->
{% table %}
columns:
  - title: "Attribute priority"
    key: num
  - title: "Attribute name"
    key: attribute
  - title: "Order"
    key: order
rows:
  - num: "1"
    attribute: "`spec.targetRef`"
    order: |
      1. `Dataplane` with `name/namespace/sectionName` (highest priority)
      2. `Dataplane` with `name/namespace`
      3. `Dataplane` with `labels/sectionName`
      4. `Dataplane` with `labels`
      5. `Dataplane`
      6. `MeshGateway`
      7. `Mesh` (lowest priority)
  - num: "2"
    attribute: "`kuma.io/origin`"
    order: |
      1. `zone` (highest priority)
      2. `global` (lowest priority)
  - num: "3"
    attribute: "`kuma.io/policy-role`"
    order: |
      1. `workload-owner` (highest priority)
      2. `consumer`
      3. `producer`
      4. `system` (lowest priority)
  - num: "4"
    attribute: "`kuma.io/display-name`"
    order: |
      Inverted lexicographical order, that is:
      1. `aaa` (highest priority)
      2. `aaaaa`
      3. `aaaaa1`
      4. `zzzzz` (lowest priority)
{% endtable %}
<!-- vale on -->

For policies with `to` or `rules`, matching policy arrays are concatenated.
For `to` policies, the concatenated arrays are sorted again based on the `spec.to[].targetRef` field:

1. `MeshMultiZoneService` (highest priority)
2. `MeshExternalService`
3. `MeshService` with `sectionName`
4. `MeshService`
5. `Mesh` (lowest priority)

Configuration is then built by merging each level using [JSON Merge Patch](https://www.rfc-editor.org/rfc/rfc7386).

For example, a producer `MeshTimeout` in `backend-ns` sets broad timeout defaults for all callers:

```yaml
# Producer policy (lower priority)
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: backend-producer-timeouts
  namespace: backend-ns
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: backend-ns
      default:
        connectionTimeout: 10s
        idleTimeout: 2m
        http:
          requestTimeout: 30s
          streamIdleTimeout: 5m
```

The `frontend` team creates a consumer policy to shorten the request timeout for their own calls and cap stream duration:

```yaml
# Consumer policy (higher priority)
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: frontend-consumer-timeouts
  namespace: frontend-ns
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: backend-ns
      default:
        http:
          requestTimeout: 5s
          maxStreamDuration: 1m
```

The merged configuration applied to `frontend`'s outbound toward `backend` is:

```yaml
default:
  connectionTimeout: 10s   # kept from producer: consumer didn't set it
  idleTimeout: 2m          # kept from producer: consumer didn't set it
  http:
    requestTimeout: 5s     # overridden by consumer
    streamIdleTimeout: 5m  # kept from producer: consumer didn't set it
    maxStreamDuration: 1m  # added by consumer
```

## Metadata

Metadata identifies a policy by its name, type/kind, and the mesh it belongs to:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

In Kubernetes, all {{ site.mesh_product_name }} policies are implemented as [Custom Resource Definitions (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) in the group `kuma.io/v1alpha1`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
spec: ... # spec data specific to the policy
```

By default, the policy is created in the `default` mesh.
You can specify the mesh with the `kuma.io/mesh` label:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: "my-mesh"
spec: ... # spec data specific to the policy
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: ExamplePolicy
name: my-policy-name
mesh: default
spec: ... # spec data specific to the policy
```

{% endnavtab %}
{% endnavtabs %}
