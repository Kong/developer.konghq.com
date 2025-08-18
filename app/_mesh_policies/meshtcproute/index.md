---
title: Mesh TCP Route
name: MeshTCPRoutes
products:
    - mesh
description: 'Alter and redirect TCP requests depending on where the request is coming from and where it’s going to.'
content_type: plugin
type: policy
min_version:
  mesh: '2.3'
icon: meshtcproute.png
---

The `MeshTCPRoute` policy allows you to alter and redirect TCP requests
depending on where the request is coming from and where it's going to.

{% if_version lte:2.5.x %}
{% warning %}
`MeshTCPRoute` doesn't support cross zone traffic before version 2.6.0.
{% endwarning %}
{% endif_version %}

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs %}
{% tab Sidecar %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`           | Allowed kinds                                 |
| --------------------- | --------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `Dataplane`, `MeshSubset(deprecated)` |
| `to[].targetRef.kind` | `MeshService`                                 |
{% endif_version %}
{% endtab %}

{% tab Builtin Gateway %}
| `targetRef`             | Allowed kinds                                             |
| ----------------------- | --------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags` |
| `to[].targetRef.kind`   | `Mesh`                                                    |
{% endtab %}

{% tab Delegated Gateway %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% endtab %}
{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ❌   | ❌    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ✅   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |

{% endif_version %}

For more information, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

Unlike other outbound policies, `MeshTCPRoute` doesn't contain `default`
directly in the `to` array. The `default` section is nested inside `rules`. For more information review the [MeshTCPRoute policy documentation](/mesh/policies/meshtcproute/reference/).

{% if_version lte:2.8.x %}
```yaml
spec:
  targetRef: # top-level targetRef selects a group of proxies to configure
    kind: Mesh|MeshSubset|MeshService|MeshServiceSubset 
  to:
    - targetRef: # targetRef selects a destination (outbound listener)
        kind: MeshService
        name: backend
      rules:
        - default: # configuration applied for the matched TCP traffic
            backendRefs: [...]
```
{% endif_version %}

{% if_version eq:2.9.x %}
```yaml
spec:
  targetRef: # top-level targetRef selects a group of proxies to configure
    kind: Mesh|MeshSubset 
  to:
    - targetRef: # targetRef selects a destination (outbound listener)
        kind: MeshService
        name: backend
      rules:
        - default: # configuration applied for the matched TCP traffic
            backendRefs: [...]
```
{% endif_version %}

{% if_version gte:2.10.x %}
```yaml
spec:
  targetRef: # top-level targetRef selects a group of proxies to configure
    kind: Mesh|Dataplane 
  to:
    - targetRef: # targetRef selects a destination (outbound listener)
        kind: MeshService
        name: backend
      rules:
        - default: # configuration applied for the matched TCP traffic
            backendRefs: [...]
```
{% endif_version %}

### Default configuration

The following describes the default configuration settings of the `MeshTCPRoute` policy:

- **`backendRefs`**: (Optional) List of destinations for the request to be redirected to
  - **`kind`**: One of `MeshService`, `MeshServiceSubset`{% if_version gte:2.9.x %}, `MeshExtenalService`{% endif_version %}
  - **`name`**: The service name
  - **`tags`**: Service tags. These must be specified if the `kind` is 
    `MeshServiceSubset`.
  - **`weight`**: When a request matches the route, the choice of an upstream
    cluster is determined by its weight. Total weight is a sum of all weights
    in the `backendRefs` list.

### Gateways

In order to route TCP traffic for a MeshGateway, you need to target the
MeshGateway in `spec.targetRef` and set `spec.to[].targetRef.kind: Mesh`.

### Interactions with `MeshHTTPRoute`

[`MeshHTTPRoute`](../meshhttproute) takes priority over `MeshTCPRoute` when both are defined for the same service, and the matching `MeshTCPRoute` is ignored.

### Interactions with `TrafficRoute`

`MeshTCPRoute` takes priority over [`TrafficRoute`](../traffic-route) when a proxy is targeted by both policies.

All legacy policies like `Retry`, `TrafficLog`, `Timeout` etc. only match on routes defined by `TrafficRoute`.
All new recommended policies like `MeshRetry`, `MeshAccessLog`, `MeshTimeout` etc. match on routes defined by `MeshTCPRoute` and `TrafficRoute`.

If you don't use legacy policies, it's recommended to remove any existing `TrafficRoute`.
Otherwise, it's recommended to migrate to new policies and then removing `TrafficRoute`.