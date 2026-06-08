You'll inject all three fault types against Kong Air services, each time confirming the resilience policy from previous paths actually does what it's supposed to. Every example uses the safe `x-chaos: true` header guard from the Learn section so nothing affects real traffic.

### Setup: confirm you have observability

This step is much more interesting with metrics dashboards open. If you skipped the previous path's observability step, do it now — the validation steps below rely on the bundled Grafana to confirm policies fire correctly.

### Step 1: Abort 10% of `flight-control`'s responses, gated by header

The fault only fires for requests carrying `x-chaos: true`. Production traffic without the header is untouched.

{% navtabs "fault-abort" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-flight-control-resilience
  namespace: kong-air-production
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
      color: blu
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10
            match:
              headers:
                - name: x-chaos
                  value: "true"' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshFaultInjection
name: test-flight-control-resilience
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
      color: blu
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10
            match:
              headers:
                - name: x-chaos
                  value: "true"' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 2: Drive traffic through the fault and observe `MeshRetry` working

From a caller of `flight-control`, drive 100 requests **with** the chaos header and 100 **without**:

```bash
CALLER=$(kubectl get pod -n kong-air-production -l app=check-in-api -o jsonpath='{.items[0].metadata.name}')

# Without the header — should be 100% successful
kubectl exec -n kong-air-production "$CALLER" -- \
  sh -c 'for i in $(seq 1 100); do curl -s -o /dev/null -w "%{http_code}\n" http://flight-control:8080/status; done' \
  | sort | uniq -c
# 100 200

# With the header — 10% would abort, but MeshRetry should mask most failures
kubectl exec -n kong-air-production "$CALLER" -- \
  sh -c 'for i in $(seq 1 100); do curl -s -o /dev/null -w "%{http_code}\n" -H "x-chaos: true" http://flight-control:8080/status; done' \
  | sort | uniq -c
# ~99 200, ~1 503  (depending on whether you have a MeshRetry on flight-control)
```

If you don't have a `MeshRetry` on the path from `check-in-api → flight-control`, you'll see roughly 10% 503s. If you do, the retry budget should mask most of them.

Verify this in metrics. Open the Service Map; you should see a small spike in `envoy_cluster_upstream_rq_retry` for `flight-control-blu`. That's the resilience policy doing exactly what it's supposed to.

### Step 3: Inject a 5s delay and verify `MeshTimeout` enforces the budget

Replace the abort with a delay scoped to 50% of header-matched requests:

{% navtabs "fault-delay" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-flight-control-resilience
  namespace: kong-air-production
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
      color: blu
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - delay:
              value: 5s
              percentage: 50
            match:
              headers:
                - name: x-chaos
                  value: "true"' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshFaultInjection
name: test-flight-control-resilience
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
      color: blu
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - delay:
              value: 5s
              percentage: 50
            match:
              headers:
                - name: x-chaos
                  value: "true"' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

If `MeshTimeout` on this path has `requestTimeout: 3s`, then 50% of header-matched requests should fail with a timeout-shaped error (504 or connect-style failure), and the rest should succeed normally:

```bash
kubectl exec -n kong-air-production "$CALLER" -- \
  sh -c 'for i in $(seq 1 50); do curl -s -o /dev/null -w "%{http_code} %{time_total}\n" -H "x-chaos: true" http://flight-control:8080/status; done'
```

Half the lines should report ≈3s with a non-200 status code. The other half should be sub-second 200s. That bimodal distribution is the timeout policy interrupting the delayed calls before they'd otherwise complete.

### Step 4: Throttle response body bytes and observe streaming behaviour

This one matters for file uploads, large JSON payloads, and any streaming protocol. Cap response bandwidth to 1KB/s:

{% navtabs "fault-rate-limit" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-flight-control-bandwidth
  namespace: kong-air-production
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: file-storage-svc
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - responseRateLimit:
              bandwidth: "1kbps"
              percentage: 100
            match:
              headers:
                - name: x-chaos
                  value: "true"' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshFaultInjection
name: test-flight-control-bandwidth
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: file-storage-svc
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - responseRateLimit:
              bandwidth: "1kbps"
              percentage: 100
            match:
              headers:
                - name: x-chaos
                  value: "true"' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

A 10KB response now takes about 10s to download. Test with a client that has a body-read timeout and confirm it fails gracefully rather than hanging:

```bash
kubectl exec -n kong-air-production "$CALLER" -- \
  curl --max-time 5 -H "x-chaos: true" http://file-storage-svc:8080/big-payload
```

The `--max-time 5` should kick in before the response completes. Many real clients have shorter read-side timeouts than connect-side ones, and this fault is the only way to catch that asymmetry before users do.

### Step 5: Build a small chaos "game day" drill

Combine the three patterns into a single recurring exercise:

1. Pick a target service for the week.
2. Apply an abort fault (5%) — observe error rates, alert thresholds, and incident response validity.
3. Replace with a delay (50%, 2s) — observe p99 latency, queue depths, frontend behaviour.
4. Replace with a response-rate fault — observe streaming clients.
5. Remove all faults; capture findings in an after-action note.

Per-week rotation gives every important Kong Air service a quarterly resilience review without overwhelming the on-call rotation.

### Step 6: Clean up

```bash
kubectl delete meshfaultinjection \
  test-flight-control-resilience \
  test-flight-control-bandwidth \
  -n kong-air-production 2>/dev/null
```

### What you did

- Applied each of `MeshFaultInjection`'s three fault types against Kong Air services.
- Used the `Dataplane` + labels targeting pattern (the modern, recommended shape).
- Gated every fault with `match.headers.x-chaos: true` so production traffic was completely untouched.
- Watched `MeshRetry`, `MeshTimeout`, and downstream timeouts trigger correctly in metrics.
- Got a starting recipe for a recurring "chaos game day" against your own services.

In Step 5 you'll meet the escape hatch — `MeshProxyPatch` — for the rare cases where no high-level {{site.mesh_product_name}} policy expresses what you need.
