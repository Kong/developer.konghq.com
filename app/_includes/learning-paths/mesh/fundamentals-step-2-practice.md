You'll enable mTLS on the default Mesh, move from `allow-all` to a default-deny posture, and then explicitly authorize Kong Air's `flight-control` service to call the `check-in-api`.

### Step 1: Enable mTLS on the default Mesh

The `Mesh` resource is **Global CP only** — apply it against your Global CP kubeconfig (or a Universal Global CP `kumactl` target).

{% navtabs "mesh-mtls" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    backends:
      - name: builtin
        type: builtin
    enabledBackend: builtin' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
mtls:
  backends:
    - name: builtin
      type: builtin
  enabledBackend: builtin' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify mTLS is now active:

```bash
kumactl get meshes -o yaml | grep -A5 mtls
```

You should see:

```yaml
mtls:
  backends:
    - name: builtin
      type: builtin
  enabledBackend: builtin
```

Every sidecar in the mesh is now encrypting and mutually authenticating all inter-service traffic. No application changes were needed.

### Step 2: Remove the `allow-all` baseline

A fresh mesh ships with an `allow-all` `MeshTrafficPermission`. Because **Allow wins** over Deny when both match, you must delete it before a default-deny will take effect.

{% navtabs "delete-allow-all" %}
{% navtab "Kubernetes" %}
```bash
kubectl delete meshtrafficpermission allow-all -n kong-mesh-system
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
kumactl delete meshtrafficpermission allow-all --mesh default
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Apply a mesh-wide default-deny

{% navtabs "default-deny" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: default-deny
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Deny' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: default-deny
mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Deny' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

At this point, every service-to-service request inside the mesh is blocked. If you try to call `check-in-api` from anywhere, you'll get a `403` or a connection timeout.

### Step 4: Authorize flight-control → check-in-api

Punch a precise hole for the one flow Kong Air actually needs:

{% navtabs "targeted-allow" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-flight-control-to-check-in
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  from:
    - targetRef:
        kind: MeshService
        name: flight-control
      default:
        action: Allow' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: allow-flight-control-to-check-in
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  from:
    - targetRef:
        kind: MeshService
        name: flight-control
      default:
        action: Allow' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 5: Verify the zero-trust posture

From a `flight-control` pod, you should now be able to reach `check-in-api`:

```bash
kubectl exec -n kong-air-production deploy/flight-control -- curl -s -o /dev/null -w "%{http_code}\n" http://check-in-api/health
# 200
```

From any other service — for example, `passenger-portal`:

```bash
kubectl exec -n kong-air-production deploy/passenger-portal -- curl -s -o /dev/null -w "%{http_code}\n" http://check-in-api/health
# 403
```

That's the zero-trust outcome: only the flow you explicitly authorized passes; everything else is rejected at the destination's sidecar.

### What you did

- Enabled built-in mTLS on the default `Mesh` — every inter-service request is now encrypted and mutually authenticated.
- Deleted the `allow-all` permission and applied a mesh-wide `default-deny`.
- Authorized `flight-control` to call `check-in-api` and confirmed every other source is blocked.

In Step 3 you'll learn how `MeshTrafficPermission` — and every other {{site.mesh_product_name}} policy — uses the same `targetRef` shape, and how to layer policies from broad mesh-wide baselines to fine-grained service overrides.
