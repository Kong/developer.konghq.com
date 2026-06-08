You'll walk through inspecting an existing multi-zone mesh to confirm the pieces are wired together as the Learn section describes. If you only have a standalone mesh available, you can still apply the commands — they'll tell you immediately when you don't have a multi-zone setup.

### Step 1: Confirm you have more than one zone

{% navtabs "list-zones" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
kubectl get zones -A
```

You should see one entry per zone (`us-east-1`, `eu-west-1`, etc.), each in state `Online`.
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
kumactl get zones
```
{% endnavtab %}
{% endnavtabs %}

If you only see one zone (or none), you're on a standalone Control Plane. Most of what follows still works, but the cross-zone failover demos in Steps 3 and 4 will need a real multi-zone deployment to be meaningful.

### Step 2: Find the ZoneIngresses

```bash
kubectl get zoneingresses -A
```

You should see a ZoneIngress per remote zone. In a Kubernetes deployment with the operator, each one runs as a `Deployment` in `kong-mesh-system`. Confirm the pods are healthy:

```bash
kubectl get pods -n kong-mesh-system -l app=kuma-ingress
```

The address column on `kubectl get zoneingresses` shows the routable address other zones use to reach this one. Spot-check that it's reachable — from a pod in another zone, `curl` it directly to confirm network connectivity.

### Step 3: Find (or note the absence of) ZoneEgresses

```bash
kubectl get zoneegresses -A
```

If the result is empty, your zones are routing outbound traffic directly from each sidecar — fine for many cases, but the Advanced Patterns path's `MeshPassthrough` step is more useful with a ZoneEgress in place. If your compliance posture requires a single egress control point, [install one now](/mesh/zone-egress/) before continuing.

### Step 4: Apply a `MeshMultiZoneService` and watch it sync

Pick a service that exists in multiple zones — for Kong Air, `check-in-api` is deployed in both `east` and `west`. Define an MMZS that aggregates them, and confirm the `kuma.io/origin: global` label and the `appProtocol: http` port spec from the Learn section:

{% navtabs "create-mmzs" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-global
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: MeshMultiZoneService
name: check-in-api-global
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Confirm the resource exists at the Global CP and has been synced down to each zone:

```bash
kubectl get meshmultizoneservices -n kong-air-production -o wide
# repeat against each zone's kubeconfig - you should see the same resource, marked as origin=global
```

### Step 5: Resolve the MMZS hostname from inside the mesh

A sidecar anywhere in the mesh should be able to resolve the MMZS's hostname:

```bash
POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$POD" -c kuma-sidecar -- \
  nslookup check-in-api-global.mzsvc.kong-air-production.mesh.local
```

You should see a VIP. The sidecar's outbound listener intercepts traffic to that VIP and steers it to actual endpoints in either zone, with locality preference applied automatically.

### Step 6: Add a baseline locality-aware load-balancing strategy

The default already prefers local endpoints. Make the cross-zone failover behaviour explicit so you can rely on it in Step 3:

{% navtabs "locality-baseline" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshLoadBalancingStrategy
metadata:
  name: prefer-local-with-failover
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Any' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshLoadBalancingStrategy
name: prefer-local-with-failover
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Any' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Every sidecar in the mesh now has the same behaviour: prefer local endpoints; if none are healthy, fail over to any remote zone.

### Step 7: Generate cross-zone traffic and watch it in Grafana

If you completed the Observability path step, the Service Map dashboard now shows cross-zone edges in addition to in-zone ones. Generate a few calls into the MMZS and confirm:

```bash
kubectl exec -n kong-air-production "$POD" -c app -- \
  sh -c 'for i in $(seq 1 50); do curl -s check-in-api-global:8080/health; done'
```

In Grafana, the Service Map should now show two arrows from `flight-control` to `check-in-api` — one local, one cross-zone — with the local one carrying the heavy traffic (because of locality awareness).

### What you did

- Listed the zones, ZoneIngresses, and (if deployed) ZoneEgresses that make up the multi-zone fabric.
- Created an MMZS with the two non-obvious requirements (`kuma.io/origin: global` and `appProtocol: http`) and confirmed it synced to every zone via KDS.
- Applied a baseline locality-aware load-balancing strategy so failover is well-defined for the canary work in Step 3.
- Verified cross-zone traffic is observable end to end in the Service Map.

In Step 2 you'll decide whether to keep all Kong Air's teams on this one mesh (soft multi-tenancy) or split them into isolated meshes (hard multi-tenancy), and walk through the trade-offs.
