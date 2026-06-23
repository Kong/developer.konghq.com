---
title: "Mesh-Scoped Zone Proxies"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Give each mesh its own dedicated zone ingress and egress in {{site.mesh_product_name}} 2.14, with per-mesh workload identity, targetable policy, isolated observability, and a deny-by-default egress perimeter for cross-zone traffic.
products:
  - mesh
tldr:
  q: How do I give one mesh its own identity, policies, and observability on cross-zone traffic?
  a: |
    Give the mesh its own dedicated zone proxies instead of sharing one global pair:
    1. Put the mesh in `spec.meshServices.mode: Exclusive`.
    2. Add a `meshes:` entry for it in your zone Helm values.
    3. Apply any mesh-scoped policy to the proxies with `targetRef.labels: {kuma.io/listener-zoneingress: enabled}` (or `...-zoneegress: enabled`).
    4. Cross-zone traffic now carries the mesh's own SPIFFE identity, honors its policies, and reports its own metrics.
next_steps:
  - text: "Global Routing: Canary Rollouts and Color Rings"
    url: "/mesh/scenarios/global-routing/"
---

Cross-zone traffic used to be the one place where every mesh in a zone looked the same. Before {{site.mesh_product_name}} 2.14, a single ZoneIngress and ZoneEgress carried traffic for **all** meshes in a zone. That meant `kong-air-mesh` could not present its own identity on the wire, could not have its own timeouts or access logs on cross-zone calls, and shared one blended observability view with every other mesh in the zone.

For Kong Air that was a compliance blocker. `kong-air-mesh` carries passenger PII, and auditors require its cross-zone traffic to present a verifiable mTLS identity distinct from any other mesh sharing the zone. A single shared egress made that impossible.

**Mesh-scoped zone proxies** give each mesh its own dedicated ingress and egress. For Kong Air, that turns the shared perimeter into one they fully own:

{% table %}
columns:
  - title: What Kong Air gets
    key: outcome
  - title: What it means
    key: meaning
rows:
  - outcome: "A verifiable identity for cross-zone traffic"
    meaning: "The zone proxies receive a `MeshIdentity`-issued SPIFFE certificate, so cross-zone calls from `kong-air-mesh` are provably theirs, the compliance requirement that started this."
  - outcome: "Cross-zone traffic they can govern"
    meaning: "Any mesh-scoped policy (`MeshTimeout`, `MeshAccessLog`, `MeshRateLimit`, and more) can target the proxies directly."
  - outcome: "Observability scoped to one mesh"
    meaning: "Metrics and logs cover only `kong-air-mesh`, instead of a blend of every mesh in the zone."
  - outcome: "A deny-by-default perimeter"
    meaning: "The egress refuses outbound traffic unless a policy explicitly allows it, no more open forwarding."
{% endtable %}

This is possible because each mesh-scoped proxy is just an ordinary `Dataplane` inside the mesh, the same kind of resource as an application sidecar. That is the whole trick: anything you can do to a workload, you can now do to your zone proxies.

## 1. Turn on Exclusive Mode

Mesh-scoped proxies are only generated for a mesh running in `Exclusive` mode. Confirm it first:

```bash
kumactl get mesh kong-air-mesh -o yaml | grep -A3 "meshServices:"
```

If `meshServices.mode` is not `Exclusive`, switch it on:

```bash
kubectl patch mesh kong-air-mesh \
  --type merge \
  -p '{"spec":{"meshServices":{"mode":"Exclusive"}}}'
```

## 2. Give Your Mesh Its Own Zone Proxies

You ask for a dedicated pair of proxies per mesh in your zone Helm values, instead of the one cluster-wide pair. Here is what changes between the two models:

| | Shared (global zone proxies) | Dedicated (mesh-scoped zone proxies) |
|---|---|---|
| **Scope** | All meshes in the zone | One mesh |
| **Own SPIFFE identity** | Not possible | Yes, via `MeshIdentity` |
| **Targetable by mesh policy** | No | Yes |
| **Resource kind** | `ZoneIngress` / `ZoneEgress` | `Dataplane` with `networking.listeners[]` |
| **Helm key** | `kuma.ingress.enabled: true` | `kuma.meshes[].ingress.enabled: true` |
| **Policy selector** | N/A | `kuma.io/listener-zoneingress: enabled` / `kuma.io/listener-zoneegress: enabled` |

{% tip %}
The two models can coexist during a migration window. The old `kuma.ingress.enabled: true` key and the new `kuma.meshes:` key are both honored in 2.14, so you can stand up the dedicated proxies before retiring the shared ones. See [Migrating from global zone proxies](#6-migrating-from-global-zone-proxies).
{% endtip %}

Add a `meshes:` entry to each zone CP's Helm values, naming the mesh and choosing separate ingress/egress deployments or a combined proxy:

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

This gives `kong-air-mesh` its own ingress and egress Deployment (each with its own Service and ServiceAccount).

{% tip %}
Use `combinedProxies` instead of separate `ingress` and `egress` entries when you want a single lower-footprint Deployment for a small or staging environment. The two shapes are mutually exclusive per mesh entry.

```yaml
meshes:
  - name: kong-air-mesh
    combinedProxies:
      enabled: true
```
{% endtip %}

## 3. Confirm the Proxies Belong to Your Mesh

Once the pods are `Running`, you can see that the zone proxies are now first-class members of `kong-air-mesh`, each one a `Dataplane` carrying the mesh label:

```bash
kubectl get pods -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"

kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneingress=enabled,kuma.io/mesh=kong-air-mesh" \
  -o yaml
```

A zone ingress Dataplane looks like this, note it belongs to `kong-air-mesh` and exposes a `ZoneIngress` listener:

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

{% tip %}
The listener `name` (here `"10001"`) is what you use in `sectionName` to target one specific listener. For Helm-deployed proxies with no named ports it defaults to the port number as a string, `"10001"` for zone ingress and `"10002"` for zone egress.
{% endtip %}

Other zones learn how to reach this mesh's ingress through a `MeshZoneAddress` that the control plane publishes for it:

```bash
kubectl get meshzoneaddresses -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"
```

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

If you scale the zone ingress to zero, its `MeshZoneAddress` is withdrawn automatically, so other zones stop routing to a dead endpoint.

## 4. Apply Per-Mesh Identity, Policy, and Observability

As the proxies are ordinary `Dataplane` resources in `kong-air-mesh`, every mesh-scoped policy can now target them, the controls that were impossible with a shared global proxy.

Two ways to select the proxies:

```yaml
# All zone ingress proxies in this mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled
```

```yaml
# Only one specific listener, matched by its name (the port string from step 3)
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled
    sectionName: "10001"
```

Use `sectionName` when a Dataplane mixes application inbounds with zone proxy listeners (for example a combined proxy co-located with an application). For dedicated zone proxy Deployments, the label is usually enough.

### Give Cross-Zone Traffic a Verifiable Identity

This is the requirement that started Kong Air's journey. With a dedicated proxy, the control plane can issue each zone's ingress and egress its own SPIFFE certificate, so cross-zone traffic is provably `kong-air-mesh`:

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

Confirm the identity reached the zone ingress proxy:

```bash
ZINAME=$(kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneingress=enabled,kuma.io/mesh=kong-air-mesh" \
  -o jsonpath='{.items[0].metadata.name}')

kumactl inspect dataplane "${ZINAME}" \
  --mesh kong-air-mesh --type policies | grep MeshIdentity
```

### Report Observability for Just This Mesh

The shared proxy blended telemetry from every mesh onto one Prometheus path. A dedicated egress reports metrics for `kong-air-mesh` alone:

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

Confirm the egress is serving its own metrics on port 5670:

```bash
ZEPOD=$(kubectl get pods -n kong-mesh-system \
  -l "k8s.kuma.io/zone-proxy-type=egress" \
  -o jsonpath='{.items[0].metadata.name}')
PODIP=$(kubectl get pod -n kong-mesh-system "$ZEPOD" \
  -o jsonpath='{.status.podIP}')

kubectl exec -n kong-mesh-system "$ZEPOD" -c kuma-sidecar -- \
  wget -qO- "http://${PODIP}:5670/metrics" | grep -c "envoy_"
```

### Set Timeouts and Audit Logs on Cross-Zone Traffic

Tune resilience and capture an audit trail on the proxies directly. An idle timeout on incoming cross-zone connections:

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

Confirm the timeout landed on the zone ingress listener:

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

For a compliance audit trail, emit access logs on just the ZoneIngress listener with `sectionName`:

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

Confirm the access log is configured on the ingress listener:

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

## 5. A Deny-by-Default Egress Perimeter

The shared egress forwarded any traffic that reached it. A mesh-scoped egress is closed by default: every `MeshExternalService` is SNI-matched at the listener and refused unless a `MeshTrafficPermission` explicitly allows the caller's SPIFFE identity. You decide exactly what may leave the mesh.

Grant the access each caller needs:

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

{% tip %}
On mesh-scoped ZoneEgress, `MeshTrafficPermission` targets the **zone-egress `Dataplane`** and matches the caller's `spiffeID` together with the destination `sni`. The older `targetRef.kind: MeshExternalService` + `from[]` form is **rejected by the admission webhook in 2.14**.
{% endtip %}

Without an allow rule, the egress refuses the request with a `503` before `MeshPassthrough` or any other policy evaluates, so add the permissions before you route real traffic through it.

## 6. Migrating from Global Zone Proxies

The move is **additive**: stand up the mesh-scoped proxies alongside the existing global ones, confirm cross-zone traffic flows through the new pair, then retire the old.

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

Once traffic is flowing through the mesh-scoped proxies, remove the old keys:

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
Scale down the old global ZoneIngress **before** removing its Helm key. Deleting the key without scaling first can cause a brief traffic interruption if KDS has not yet propagated the new proxies' `MeshZoneAddress` to other zones.
{% endwarning %}

The old `ZoneIngress` and `ZoneEgress` resource kinds remain in the API for backward compatibility in 2.14, and are planned for deprecation in a future major release.
