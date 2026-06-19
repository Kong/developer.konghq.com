---
title: Mesh Traffic Permission
name: MeshTrafficPermissions
products:
    - mesh
description: "Define what services can talk to other services."
content_type: plugin
type: policy
icon: meshtrafficpermission.png
---
{:.warning}
> This policy uses new policy matching algorithm.
> Do **not** combine with the deprecated TrafficPermission policy.

{:.info}
> [Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls) has to be enabled to make MeshTrafficPermission work.

The `MeshTrafficPermission` policy provides access control within the Mesh.
It allows you to define granular rules about which services can communicate with each other.

## TargetRef support matrix

{% navtabs "support-matrix" %}
{% navtab "Sidecar" %}
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `Dataplane`, `MeshSubset(deprecated)`"
  - targetref: "`from[].targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshSubset`, `MeshServiceSubset`"
{% endtable %}
{% endnavtab %}
{% navtab "Builtin Gateway" %}
`MeshTrafficPermission` isn't supported on builtin gateways. If applied via
`spec.targetRef.kind: MeshService`, it has no effect.
{% endnavtab %}

{% navtab "Delegated Gateway" %}
`MeshTrafficPermission` isn't supported on delegated gateways.
{% endnavtab %}
{% endnavtabs %}

If you don't understand this table you should read [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

### Action

{{ site.mesh_product_name }} allows configuring one of 3 actions for a group of service's clients:

* `Allow` - allows incoming requests matching the from `targetRef`.
* `Deny` - denies incoming requests matching the from `targetRef`
* `AllowWithShadowDeny` - same as `Allow` but will log as if request is denied, this is useful for rolling new restrictive policies without breaking things.

## Examples

### Service 'payments' allows requests from 'orders'

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: allow-orders
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: payments
  from:
    - targetRef:
        kind: MeshSubset
        tags: 
          kuma.io/service: orders
      default:
        action: Allow
```
{% endpolicy_yaml %}

#### Explanation

1. Top level `targetRef` selects data plane proxies that have `app: payments` label.
   MeshTrafficPermission `allow-orders` will be configured on these proxies.

    ```yaml
    targetRef: # 1
      kind: Dataplane
      labels:
        app: payments
    ```

2. `TargetRef` inside the `from` array selects proxies that implement `order` service.
   These proxies will be subjected to the action from `default.action`.

    ```yaml
    - targetRef: # 2
        kind: MeshSubset
        tags: 
          kuma.io/service: orders
    ```

3. The action is `Allow`. All requests from service `orders` will be allowed on service `payments`.

    ```yaml
    default: # 3
      action: Allow
    ```

### Deny all

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: deny-all
mesh: default
spec:
  from:
    - targetRef: # 2
        kind: Mesh
      default: # 3
        action: Deny
```
{% endpolicy_yaml %}

#### Explanation

1. Since top level `targetRef` is empty it selects all proxies in the mesh.
2. `TargetRef` inside the `from` array selects all clients.

    ```yaml
    - targetRef: # 2
        kind: Mesh
    ```

3. The action is `Deny`. All requests from all services will be denied on all proxies in the `default` mesh.

    ```yaml
    default: # 3
      action: Deny
    ```

### Allow all

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: allow-all
mesh: default
spec:
  from:
    - targetRef: # 2
        kind: Mesh
      default: # 3
        action: Allow
```
{% endpolicy_yaml %}

#### Explanation

1. Since top level `targetRef` is empty it selects all proxies in the mesh.
2. `targetRef` inside the element of the `from` array selects all clients within the mesh.

    ```yaml
    - targetRef: # 2
        kind: Mesh
    ```

3. The action is `Allow`. All requests from all services will be allow on all proxies in the `default` mesh.

    ```yaml
    default: # 3
      action: Allow
    ```

### Allow requests from zone 'us-east', deny requests from 'dev' environment

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: example-with-tags
mesh: default
spec:
   from:
      - targetRef: # 2
           kind: MeshSubset
           tags:
              kuma.io/zone: us-east
        default: # 3
           action: Allow
      - targetRef: # 4
           kind: MeshSubset
           tags:
              env: dev
        default: # 5
           action: Deny
```
{% endpolicy_yaml %}

#### Explanation

1. Since top level `targetRef` is empty it selects all proxies in the mesh.
2. `TargetRef` inside the `from` array selects proxies that have label `kuma.io/zone: us-east`.
   These proxies will be subjected to the action from `default.action`.

    ```yaml
    - targetRef: # 2
        kind: MeshSubset
        tags:
          kuma.io/zone: us-east
    ```

3. The action is `Allow`. All requests from the zone `us-east` will be allowed on all proxies.

    ```yaml
    default: # 3
      action: Allow
    ```

4. `TargetRef` inside the `from` array selects proxies that have tags `kuma.io/zone: us-east`.
   These proxies will be subjected to the action from `default.action`.

    ```yaml
    - targetRef: # 4
        kind: MeshSubset
        tags:
          env: dev
    ```

5. The action is `Deny`. All requests from the env `dev` will be denied on all proxies.

    ```yaml
    default: # 5
      action: Deny
    ```

{:.info}
> Order of rules inside the `from` array matters.
> Request from the proxy that has both `kuma.io/zone: east` and `env: dev` will be denied.
> This is because the rule with `Deny` is later in the `from` array than any `Allow` rules.
