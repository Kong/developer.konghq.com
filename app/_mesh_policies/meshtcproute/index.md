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

## TargetRef support matrix

{% navtabs "support-matrix" %}
{% navtab "Sidecar" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `Dataplane`, `MeshSubset(deprecated)`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`MeshService`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Built-in Gateway" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`Mesh`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Delegated Gateway" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshSubset`"
  - targetref: "`to[].targetRef.kind`"
    allowed_kinds: "`MeshService`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}
{% endnavtabs %}

For more information, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

Unlike other outbound policies, `MeshTCPRoute` doesn't contain `default`
directly in the `to` array. The `default` section is nested inside `rules`. For more information review the [MeshTCPRoute policy documentation](/mesh/policies/meshtcproute/reference/).

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

### Default configuration

The following describes the default configuration settings of the `MeshTCPRoute` policy:

- **`backendRefs`**: (Optional) List of destinations for the request to be redirected to
  - **`kind`**: One of `MeshService`, `MeshServiceSubset`, `MeshExternalService`
  - **`name`**: The service name
  - **`tags`**: Service tags. These must be specified if the `kind` is 
    `MeshServiceSubset`.
  - **`weight`**: When a request matches the route, the choice of an upstream
    cluster is determined by its weight. Total weight is a sum of all weights
    in the `backendRefs` list.

### Gateways

To route TCP traffic for a MeshGateway, you need to target the
MeshGateway in `spec.targetRef` and set `spec.to[].targetRef.kind: Mesh`.

### Interactions with `MeshHTTPRoute`

[`MeshHTTPRoute`](../meshhttproute) takes priority over `MeshTCPRoute` when both are defined for the same service, and the matching `MeshTCPRoute` is ignored.

### Interactions with `TrafficRoute`

`MeshTCPRoute` takes priority over [`TrafficRoute`](../traffic-route) when a proxy is targeted by both policies.

All legacy policies like `Retry`, `TrafficLog`, `Timeout` and so on only match on routes defined by `TrafficRoute`.
All new recommended policies like `MeshRetry`, `MeshAccessLog`, `MeshTimeout` and so on match on routes defined by `MeshTCPRoute` and `TrafficRoute`.

If you don't use legacy policies, we recommend removing any existing `TrafficRoute`.
Otherwise, we recommend migrating to new policies and then removing `TrafficRoute`.
