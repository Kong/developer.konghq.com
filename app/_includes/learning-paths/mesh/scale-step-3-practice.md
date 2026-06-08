You'll roll booking-engine v2 out to 10% of `us-east-1` while keeping `us-west-2` and `eu-west-1` on 100% v1, then verify the cross-zone failover safety net by simulating a collapse of the East canary.

### Step 1: Define the global stable + canary MMZS resources

These aggregate the v1 and v2 instances across every zone. Apply at the Global CP.

{% navtabs "canary-mmzs" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-stable
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        version: stable
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-canary
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        version: canary
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: MeshMultiZoneService
name: check-in-api-stable
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
        version: stable
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: check-in-api-canary
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/service: check-in-api
        version: canary
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Confirm both MMZS resources synced to every zone:

```bash
kubectl get meshmultizoneservices -n kong-air-production
```

### Step 2: Apply the East-only 90/10 route

This `MeshHTTPRoute` targets only sidecars belonging to `passenger-portal-east`, so it only affects the East zone.

{% navtabs "east-canary-route" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: check-in-east-canary
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal-east
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 90
              - kind: MeshMultiZoneService
                name: check-in-api-canary
                weight: 10' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: check-in-east-canary
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal-east
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 90
              - kind: MeshMultiZoneService
                name: check-in-api-canary
                weight: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Apply the West 100/0 route (and an equivalent for EU)

{% navtabs "west-stable-route" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: check-in-west-stable
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal-west
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 100' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: check-in-west-stable
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal-west
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-stable
                weight: 100' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 4: Add cross-region failover for both pools

If East's stable _or_ canary collapses, traffic should fail over to West's stable. This is the safety net from the Learn section.

{% navtabs "canary-failover" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshLoadBalancingStrategy
metadata:
  name: check-in-locality
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Any
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-canary
      default:
        localityAwareness:
          disabled: false
          crossZone:
            failover:
              - to:
                  type: Any' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshLoadBalancingStrategy
name: check-in-locality
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-stable
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Any
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-canary
      default:
        localityAwareness:
          disabled: false
          crossZone:
            failover:
              - to:
                  type: Any' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 5: Verify the per-zone split

From an East `passenger-portal` pod, you should see roughly 90/10:

```bash
EAST_POD=$(kubectl --context east get pod -n kong-air-production -l app=passenger-portal -o jsonpath='{.items[0].metadata.name}')
kubectl --context east exec -n kong-air-production "$EAST_POD" -- \
  sh -c 'for i in $(seq 1 100); do curl -s http://check-in-api-stable.mzsvc.kong-air-production.mesh.local:8080 | grep -o "version=[a-z]*"; done | sort | uniq -c'

#  90 version=stable
#  10 version=canary
```

From a West pod, every request should hit stable:

```bash
WEST_POD=$(kubectl --context west get pod -n kong-air-production -l app=passenger-portal -o jsonpath='{.items[0].metadata.name}')
kubectl --context west exec -n kong-air-production "$WEST_POD" -- \
  sh -c 'for i in $(seq 1 50); do curl -s http://check-in-api-stable.mzsvc.kong-air-production.mesh.local:8080 | grep -o "version=[a-z]*"; done | sort | uniq -c'

#  50 version=stable
```

### Step 6: Simulate East canary collapse and verify failover

Scale East's canary deployment to zero replicas to simulate it crashing:

```bash
kubectl --context east scale deployment check-in-api-canary -n kong-air-production --replicas=0
```

Now rerun the East verification. You should see 100/0 stable — the 10% that _would_ have gone to canary is now flowing to East-stable (because East stable is healthier than crossing into West) until you exhaust East stable too.

Bring it back when you're done:

```bash
kubectl --context east scale deployment check-in-api-canary -n kong-air-production --replicas=3
```

### Step 7: Progressing the rollout

Ramping East to 50/50 is one patch:

```bash
kubectl patch meshhttproute check-in-east-canary -n kong-air-production --type=merge \
  -p '{"spec":{"to":[{"targetRef":{"kind":"MeshMultiZoneService","name":"check-in-api-stable"},"rules":[{"matches":[{"path":{"value":"/","type":"PathPrefix"}}],"default":{"backendRefs":[{"kind":"MeshMultiZoneService","name":"check-in-api-stable","weight":50},{"kind":"MeshMultiZoneService","name":"check-in-api-canary","weight":50}]}}]}]}}'
```

Going global once East has burned in: replace both per-zone routes with a single `Mesh`-level route at the Global CP. Now West and EU pick up the canary on the same rollout schedule.

Rolling back: drop East's canary weight to 0. Failed deploys never reach a passenger.

### What you did

- Defined stable and canary `MeshMultiZoneService` resources, with the `kuma.io/origin: global` label and `appProtocol: http` port spec that MMZS needs.
- Wrote per-zone `MeshHTTPRoute` policies so the canary only ran in East, leaving West and EU untouched.
- Added a `MeshLoadBalancingStrategy` so a complete collapse of the East canary fails over to West stable, not to nothing.
- Confirmed the split per zone, watched failover kick in, and rehearsed the ramp / global-promotion / rollback motions.

In Step 4 you'll use a closely related multi-zone pattern — color-pinning routes against agnostic MMZS hostnames — to keep entire request _chains_ on the same color across many service hops.
