---
title: "Mesh-Scoped Zone Proxies"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Deploy and configure dedicated per-mesh zone ingress and egress proxies in {{site.mesh_product_name}} 2.14, enabling per-mesh identity, fine-grained policy control, and isolated observability for cross-zone traffic.
products:
  - mesh
tldr:
  q: How do I get per-mesh identity and fine-grained policy control on my zone proxies?
  a: |
    Deploy **mesh-scoped zone proxies** via the Helm `meshes:` list:
    1. Enable `spec.meshServices.mode: Exclusive` on your mesh.
    2. Add a `meshes:` entry for each mesh in your zone Helm values.
    3. Target the new proxies with `targetRef.labels: {kuma.io/listener-zoneingress: enabled}` or `kuma.io/listener-zoneegress: enabled`.
    4. Use `sectionName` to scope a policy to a specific named listener.
next_steps:
  - text: "Global Canary Releases"
    url: "/mesh/scenarios/global-canary-releases/"
---

Before {{site.mesh_product_name}} 2.14, a single ZoneIngress and ZoneEgress handled **all** meshes in a zone. This global scope created three hard limits: the proxies could not receive a mesh-specific SPIFFE identity via `MeshIdentity`, mesh-scoped policies such as `MeshTimeout` or `MeshMetric` could not target them, and all meshes shared the same observability view of cross-zone traffic.

Kong Air encountered all three. Their `kong-air-mesh` carries passenger PII. Regulatory requirements say that cross-zone traffic from `kong-air-mesh` must present a verifiable mTLS identity distinct from any other mesh sharing the zone. The single global zone egress made this impossible.

Mesh-scoped zone proxies solve this by representing zone ingress and egress as `Dataplane` resources with a `networking.listeners` array, the same kind as application sidecars, only with listener types of `ZoneIngress` and `ZoneEgress` instead of inbound ports. Because they are ordinary Dataplanes inside a specific mesh, they can hold a `MeshIdentity`-issued SPIFFE certificate and be targeted by any mesh-scoped policy.

## 1. Prerequisites

The only required condition before the control plane will generate zone proxy listeners is `spec.meshServices.mode: Exclusive` on the target mesh. The listener generation code checks for this before building the listener configuration.

Verify it before proceeding:

```bash
kumactl get mesh kong-air-mesh -o yaml | grep -A3 "meshServices:"
```

If `meshServices.mode` is not `Exclusive`, update the mesh:

```bash
kubectl patch mesh kong-air-mesh \
  --type merge \
  -p '{"spec":{"meshServices":{"mode":"Exclusive"}}}'
```

## 2. Old vs New Deployment Model

| | Old model (global zone proxies) | New model (mesh-scoped zone proxies) |
|---|---|---|
| **Resource kind** | `ZoneIngress` / `ZoneEgress` | `Dataplane` with `networking.listeners[]` |
| **Helm key** | `kuma.ingress.enabled: true` | `kuma.meshes[].ingress.enabled: true` |
| **Scope** | Cluster-wide (all meshes) | Per mesh |
| **MeshIdentity** | Not supported | Supported |
| **Mesh-scoped policies** | Not supported | Supported |
| **Policy labels** | N/A | `kuma.io/listener-zoneingress: enabled` / `kuma.io/listener-zoneegress: enabled` |
| **Per-listener targeting** | N/A | `sectionName` using the port number string |

{% tip %}
The two models can coexist during a migration window. The old `kuma.ingress.enabled: true` key and the new `kuma.meshes:` key are both honored in 2.14. Remove the old key only after you confirm that mesh-scoped listeners are serving traffic.
{% endtip %}

## 3. Enabling Mesh-Scoped Zone Proxies

Add a `meshes:` entry to each zone CP's Helm values. The entry must name the mesh and choose between separate ingress/egress deployments or a combined proxy:

```yaml
# Zone Helm values (values-zone1.yaml)
kuma:
  # Remove or leave the old global ingress/egress keys during migration:
  # ingress:
  #   enabled: true
  # egress:
  #   enabled: true

  meshes:
    - name: kong-air-mesh
      ingress:
        enabled: true
      egress:
        enabled: true
```

Apply the upgrade:

```bash
helm upgrade kong-mesh kong-mesh/kong-mesh \
  --namespace kong-mesh-system \
  --reuse-values \
  --set "kuma.meshes[0].name=kong-air-mesh" \
  --set "kuma.meshes[0].ingress.enabled=true" \
  --set "kuma.meshes[0].egress.enabled=true" \
  --version 2.14.0
```

Helm renders per-mesh templates for each entry: a `Deployment`, `Service`, `ServiceAccount`, and optionally an `HPA` and `PDB`. The Service for the zone ingress is labeled `k8s.kuma.io/zone-proxy-type: ingress`; the zone egress service is labeled `k8s.kuma.io/zone-proxy-type: egress`. These labels tell the pod controller which listener type to assign to each port.

{% tip %}
Use `combinedProxies` instead of separate `ingress` and `egress` entries when you want a single lower-footprint Deployment for a small or staging environment. The two shapes are mutually exclusive per mesh entry.

```yaml
meshes:
  - name: kong-air-mesh
    combinedProxies:
      enabled: true
```
{% endtip %}

## 4. What Gets Created

### Dataplane resources with listeners

The zone CP generates a `Dataplane` resource for each zone proxy pod. Unlike application sidecars (which have `networking.inbound`), a dedicated zone proxy Dataplane has a `networking.listeners` array.

Wait for the pods to reach `Running` state, then inspect the Dataplanes:

```bash
kubectl get pods -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"

kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneingress=enabled,kuma.io/mesh=kong-air-mesh" \
  -o yaml
```

Example output:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Dataplane
metadata:
  name: kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/zone: zone1
    kuma.io/listener-zoneingress: enabled
    k8s.kuma.io/zone-proxy-type: ingress
spec:
  networking:
    address: 10.42.0.30
    listeners:
      - type: ZoneIngress
        address: 10.42.0.30
        port: 10001
        name: "10001"
        state: Ready
```

The listener `name` is derived from the Service port name. For Helm-deployed proxies with no named ports, the name defaults to the port number as a string (`"10001"` for zone ingress, `"10002"` for zone egress). This name is what you use in `sectionName` when targeting specific listeners.

The CP automatically computes and sets `kuma.io/listener-zoneingress: enabled` and `kuma.io/listener-zoneegress: enabled` on Dataplanes that have the corresponding listener type.

### MeshZoneAddress

For every Service labeled `k8s.kuma.io/zone-proxy-type: ingress` with at least one ready endpoint, the zone CP creates a `MeshZoneAddress` resource and syncs it to the global CP:

```bash
kubectl get meshzoneaddresses -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"
```

Example:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshZoneAddress
metadata:
  name: kong-mesh-kong-air-mesh-ingress
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/zone: zone1
spec:
  address: 203.0.113.42  # public LoadBalancer IP
  port: 10001
```

Other zones use this address to route cross-zone traffic into `zone1`. The resource is removed automatically when the zone ingress is scaled to zero, ensuring other zones stop routing to a dead endpoint.

### Envoy listener naming

For the zone ingress Dataplane, Envoy generates a dedicated listener named `self_zoneingress_dp_<port-name>`. With the default Helm port name of `"10001"`, the Envoy listener name is `self_zoneingress_dp_10001`.

Verify it on the zone ingress pod:

```bash
ZIPOD=$(kubectl get pods -n kong-mesh-system \
  -l "k8s.kuma.io/zone-proxy-type=ingress" \
  -o jsonpath='{.items[0].metadata.name}')
PODIP=$(kubectl get pod -n kong-mesh-system "$ZIPOD" \
  -o jsonpath='{.status.podIP}')

kubectl exec -n kong-mesh-system "$ZIPOD" -c kuma-sidecar -- \
  wget -qO- "http://${PODIP}:9902/listeners"
```

Expected output includes `self_zoneingress_dp_10001::10.42.0.30:10001`.

## 5. Policy Targeting

Because mesh-scoped zone proxies are ordinary `Dataplane` resources, every mesh-scoped policy (`MeshTimeout`, `MeshMetric`, `MeshAccessLog`, `MeshIdentity`, etc.) can target them using the standard `spec.targetRef` model.

### Label-based targeting

Use the computed labels to select all proxies of a given type across the mesh:

```yaml
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled  # all zone ingress proxies in this mesh
```

```yaml
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled   # all zone egress proxies in this mesh
```

### Listener-scoped targeting with `sectionName`

Use `sectionName` to narrow a policy to a specific named listener. The value must match the listener `name` from the Dataplane spec, for Helm-deployed proxies this is the port number as a string:

```yaml
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled
    sectionName: "10001"   # targets only the ZoneIngress listener on port 10001
```

```yaml
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
    sectionName: "10002"   # targets only the ZoneEgress listener on port 10002
```

`sectionName` is most useful when the Dataplane mixes application inbounds with zone proxy listeners (for example, a combined proxy co-located with an application). For dedicated zone proxy Deployments, label-based targeting is usually sufficient.

## 6. Practical Policy Examples

### MeshMetric: dedicated observability per mesh

The global zone proxy mixed telemetry from every mesh onto the same Prometheus path. A mesh-scoped proxy exposes metrics only for its mesh:

```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: kong-air-zone-egress-metrics
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
  default:
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
          tls:
            mode: Disabled
EOF
```

Verify metrics are available. The `_kuma:metrics:prometheus:default-backend` listener appears in the zone egress pod's listener list, and port 5670 serves Envoy metrics:

```bash
ZEPOD=$(kubectl get pods -n kong-mesh-system \
  -l "k8s.kuma.io/zone-proxy-type=egress" \
  -o jsonpath='{.items[0].metadata.name}')
PODIP=$(kubectl get pod -n kong-mesh-system "$ZEPOD" \
  -o jsonpath='{.status.podIP}')

kubectl exec -n kong-mesh-system "$ZEPOD" -c kuma-sidecar -- \
  wget -qO- "http://${PODIP}:5670/metrics" | grep -c "envoy_"
```

### MeshTimeout: idle timeout on the zone ingress listener

Use `rules` (the current API replacing the deprecated `from`) to set the idle timeout on incoming zone ingress connections:

```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: kong-air-zone-ingress-timeout
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled
  rules:
    - default:
        idleTimeout: 30s
EOF
```

Verify the idle timeout is applied in the zone ingress Envoy listener:

```bash
ZIPOD=$(kubectl get pods -n kong-mesh-system \
  -l "k8s.kuma.io/zone-proxy-type=ingress" \
  -o jsonpath='{.items[0].metadata.name}')
PODIP=$(kubectl get pod -n kong-mesh-system "$ZIPOD" \
  -o jsonpath='{.status.podIP}')

kubectl exec -n kong-mesh-system "$ZIPOD" -c kuma-sidecar -- \
  wget -qO- "http://${PODIP}:9902/config_dump" \
  | grep -A2 "self_zoneingress_dp_10001" \
  | grep -o '"idle_timeout": "[^"]*"' | head -1
# Expected: "idle_timeout": "30s"
```

### MeshAccessLog: audit zone ingress traffic with sectionName

Use `sectionName` and `rules` to emit access logs only on the ZoneIngress listener:

```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: kong-air-zone-ingress-audit
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled
    sectionName: "10001"
  rules:
    - default:
        backends:
          - type: File
            file:
              path: /tmp/zone-ingress-audit.log
              format:
                type: Plain
                plain: "[%START_TIME%] %UPSTREAM_HOST%"
EOF
```

Verify the access log is configured in the `self_zoneingress_dp_10001` listener:

```bash
ZIPOD=$(kubectl get pods -n kong-mesh-system \
  -l "k8s.kuma.io/zone-proxy-type=ingress" \
  -o jsonpath='{.items[0].metadata.name}')
PODIP=$(kubectl get pod -n kong-mesh-system "$ZIPOD" \
  -o jsonpath='{.status.podIP}')

kubectl exec -n kong-mesh-system "$ZIPOD" -c kuma-sidecar -- \
  wget -qO- "http://${PODIP}:9902/config_dump" \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
for c in d.get('configs', []):
  for l in c.get('dynamic_listeners', []):
    if '10001' in l.get('name', ''):
      data = json.dumps(l)
      if 'access_log' in data:
        print('Access log configured on zone ingress listener')
"
```

### MeshIdentity: give zone proxies a SPIFFE identity

With global zone proxies, applying `MeshIdentity` was blocked because the resource is mesh-scoped. With mesh-scoped proxies, the control plane can issue distinct SPIFFE certificates to each zone's ingress and egress.

```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: kong-air-zone-proxy-identity
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled
  default:
    spiffeId:
      type: Path
      value: /zone/{% raw %}{{ .Zone }}{% endraw %}/type/zone-ingress
EOF
```

Verify the policy matched the zone ingress Dataplane:

```bash
ZINAME=$(kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneingress=enabled,kuma.io/mesh=kong-air-mesh" \
  -o jsonpath='{.items[0].metadata.name}')

kumactl inspect dataplane "${ZINAME}" \
  --mesh kong-air-mesh --type policies | grep MeshIdentity
```

## 7. ZoneEgress is Deny-by-Default

With the old global ZoneEgress, traffic that reached the proxy was forwarded without additional authentication. The mesh-scoped ZoneEgress listener enforces **deny-by-default**: every `MeshExternalService` is SNI-matched at the listener and refused unless a `MeshTrafficPermission` `Allow` rule explicitly permits the caller's SPIFFE identity.

Before cutting over from a global ZoneEgress, create the required permissions:

```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: kong-air-external-allow
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
  rules:
    - default:
        allow:
          # SNI format: sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>
          # See the MeshExternalService scenario for how to derive it.
          - spiffeID:
              type: Exact
              value: spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control
            sni:
              type: Exact
              value: sni.extsvc.kong-air-mesh.zone1.kong-mesh-system.weather-api.443
EOF
```

> [!NOTE]
> On mesh-scoped ZoneEgress, `MeshTrafficPermission` targets the **zone-egress `Dataplane`** and matches the caller's `spiffeID` together with the destination `sni`. The older `targetRef.kind: MeshExternalService` + `from[]` form is **rejected by the admission webhook in 2.14**.

Omitting this permission causes the ZoneEgress to refuse the request (a `503`) before `MeshPassthrough` or any other policy evaluates.

## 8. Verifying the Setup

After applying the Helm upgrade, confirm all expected resources are present:

```bash
# Confirm zone proxy pods are running
kubectl get pods -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"

# Confirm mesh-scoped zone ingress Dataplanes exist with the computed label
kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneingress=enabled,kuma.io/mesh=kong-air-mesh"

# Confirm mesh-scoped zone egress Dataplanes exist
kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneegress=enabled,kuma.io/mesh=kong-air-mesh"

# Confirm MeshZoneAddress was created and will sync to the global CP
kubectl get meshzoneaddresses -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"
```

Confirm the zone ingress Envoy listener is active:

```bash
ZIPOD=$(kubectl get pods -n kong-mesh-system \
  -l "k8s.kuma.io/zone-proxy-type=ingress" \
  -o jsonpath='{.items[0].metadata.name}')
PODIP=$(kubectl get pod -n kong-mesh-system "$ZIPOD" \
  -o jsonpath='{.status.podIP}')

kubectl exec -n kong-mesh-system "$ZIPOD" -c kuma-sidecar -- \
  wget -qO- "http://${PODIP}:9902/listeners"
# Expected to include: self_zoneingress_dp_10001::<pod-ip>:10001
```

Confirm that policies target the new proxies by inspecting the Dataplane:

```bash
ZINAME=$(kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneingress=enabled,kuma.io/mesh=kong-air-mesh" \
  -o jsonpath='{.items[0].metadata.name}')
kumactl inspect dataplane "${ZINAME}" --mesh kong-air-mesh --type policies
```

## 9. Migrating from Global Zone Proxies

The migration is **additive**: deploy mesh-scoped proxies alongside the existing global proxies, verify traffic flows through the new proxies, then remove the old ones.

```yaml
# Transition values, both models active simultaneously
kuma:
  ingress:
    enabled: true   # old global, leave until migration is confirmed
  egress:
    enabled: true   # old global, leave until migration is confirmed

  meshes:
    - name: kong-air-mesh
      ingress:
        enabled: true   # new mesh-scoped
      egress:
        enabled: true   # new mesh-scoped
```

Once cross-zone traffic is flowing through the mesh-scoped proxies, remove the old keys:

```yaml
kuma:
  # ingress.enabled and egress.enabled removed
  meshes:
    - name: kong-air-mesh
      ingress:
        enabled: true
      egress:
        enabled: true
```

{% warning %}
Scale down the old global ZoneIngress **before** removing its Helm key. Deleting the Helm key without scaling first can cause a brief traffic interruption if KDS has not yet propagated the `MeshZoneAddress` from the new proxies to other zones.
{% endwarning %}

The old `ZoneIngress` and `ZoneEgress` resource kinds continue to exist in the API for backward compatibility in 2.14. They are planned for deprecation in a future major release.
