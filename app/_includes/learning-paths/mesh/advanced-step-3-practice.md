You'll deploy {{site.base_gateway}} as an ingress into a strict-mTLS mesh and confirm the bridge pattern delivers a `200` end to end. Then you'll deliberately break each piece in turn to see exactly what symptoms the canonical misconfigurations produce.

This step assumes you have a `check-in-api` workload deployed in `kong-air-production` and that the mesh is in `MeshTLS: Strict` (from the previous path's Step 2).

### Step 1: Annotate the {{site.base_gateway}} pod

Either patch your existing deployment manifest, or update the Helm values for the gateway. The change is to the Pod template's annotations:

```yaml
spec:
  template:
    metadata:
      annotations:
        kuma.io/gateway: enabled
```

After a rollout, confirm the gateway's pods have a `kuma-sidecar` container:

```bash
kubectl get pods -n kong -l app=gateway -o jsonpath='{.items[0].spec.containers[*].name}'
# proxy kuma-sidecar
```

The `kuma-sidecar` container is the gateway's own outbound proxy. Without the annotation, you'd either get sidecar/gateway port conflicts or no sidecar at all.

### Step 2: Create the `ExternalName` bridge service

```bash
echo 'apiVersion: v1
kind: Service
metadata:
  name: check-in-mesh-bridge
  namespace: kong-air-production
spec:
  type: ExternalName
  externalName: check-in-api.kong-air-production.svc.mesh.local' | kubectl apply -f -
```

This service has no selectors and no endpoints. Its only job is to be an alias for the mesh DNS name.

Verify the alias resolves from inside the cluster:

```bash
kubectl run dns-debug --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.6 --rm -it --restart=Never -- \
  nslookup check-in-mesh-bridge.kong-air-production
```

You should see the alias chain through to the mesh VIP.

### Step 3: Point the `HTTPRoute` at the bridge

Update the `HTTPRoute` that exposes `check-in-api` to use the bridge as its backend:

```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: check-in-ingress
  namespace: kong-air-production
spec:
  parentRefs:
    - name: kong-air-gateway
      namespace: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /check-in
      backendRefs:
        - name: check-in-mesh-bridge
          port: 8080' | kubectl apply -f -
```

### Step 4: Send a request through the gateway

```bash
GATEWAY=$(kubectl get svc -n kong kong-air-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -i "http://${GATEWAY}/check-in/health"
# HTTP/1.1 200 OK
```

Confirm the request actually went through the sidecar. In the gateway pod's `kuma-sidecar` logs, you should see an outbound request to the `check-in-api` service:

```bash
kubectl logs -n kong -l app=gateway -c kuma-sidecar --tail=20 | grep check-in-api
```

### Step 5: Break it deliberately — pod-IP routing

Skip the bridge and point the route straight at the backend pods to see the classic failure mode:

```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: check-in-ingress
  namespace: kong-air-production
spec:
  parentRefs:
    - name: kong-air-gateway
      namespace: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /check-in
      backendRefs:
        - name: check-in-api      # <-- the real Service, not the bridge
          port: 8080' | kubectl apply -f -
```

Now retry:

```bash
curl -i "http://${GATEWAY}/check-in/health"
# HTTP/1.1 502 Bad Gateway
```

Check both ends of the failure:

```bash
# Gateway side: connect failure
kubectl logs -n kong -l app=gateway -c proxy --tail=20 | grep -E "(502|connect)"

# Backend side: TLS handshake error (we sent plaintext into strict mTLS)
kubectl logs -n kong-air-production -l app=check-in-api -c kuma-sidecar --tail=20 \
  | grep -E "(handshake|TLS_error)"
```

This is the canonical "everything is 502'd" symptom. Restore the bridge route from Step 3 before continuing.

### Step 6: Break it the other way — annotation missing

Roll back the `kuma.io/gateway: enabled` annotation:

```bash
kubectl annotate pod -n kong -l app=gateway kuma.io/gateway- --overwrite
kubectl rollout restart deploy -n kong gateway
```

The gateway pods will come up _without_ a sidecar (or with one that conflicts on ports). Calls will either fail at the gateway because there's no outbound mTLS path to the mesh, or fail at startup because of listener conflicts depending on the gateway image and version.

Re-add the annotation:

```bash
kubectl annotate pod -n kong -l app=gateway kuma.io/gateway=enabled --overwrite
kubectl rollout restart deploy -n kong gateway
```

### Step 7: Tighten the boundary (optional)

You can layer a `MeshTrafficPermission` that explicitly allows the gateway → check-in-api flow and denies everything else into `check-in-api` from outside the mesh:

{% navtabs "gateway-tpermission" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-gateway-to-check-in
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  from:
    - targetRef:
        kind: Dataplane
        labels:
          kuma.io/gateway: enabled
      default:
        action: Allow' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: allow-gateway-to-check-in
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  from:
    - targetRef:
        kind: Dataplane
        labels:
          kuma.io/gateway: enabled
      default:
        action: Allow' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Now only mesh sidecars annotated as gateways can reach `check-in-api` from the ingress side.

### What you did

- Annotated {{site.base_gateway}}'s pods with `kuma.io/gateway: enabled` so the sidecar handles outbound mTLS correctly.
- Created an `ExternalName` bridge service that aliases to the mesh DNS hostname for `check-in-api`.
- Pointed the `HTTPRoute` at the bridge — forcing traffic through mesh DNS and the VIP layer.
- Confirmed end-to-end `200` through a strict-mTLS mesh.
- Reproduced both of the canonical failure modes (pod-IP routing → 502; missing annotation → port conflict / no outbound mTLS) and saw exactly what they look like in the logs.

In Step 4 you'll deliberately break Kong Air's services with `MeshFaultInjection` to validate that the `MeshRetry` policies you set up in Step 2 actually do what you think.
