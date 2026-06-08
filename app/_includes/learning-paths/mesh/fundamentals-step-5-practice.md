You'll apply a real cross-cutting policy with `MeshSubset`: every Kong Air sidecar in the `us-east-1` region gets a 15-second request timeout, regardless of which service it belongs to. Then you'll contrast that with what a `MeshService`-shaped attempt would have looked like — and why it wouldn't have worked.

### Step 1: Apply the regional timeout

This is a `MeshTimeout` policy that targets every sidecar tagged `region: us-east-1` and sets a 15s ceiling on outbound HTTP requests.

{% navtabs "subset-timeout" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: regional-baseline
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshSubset
    tags:
      region: us-east-1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTimeout
name: regional-baseline
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      region: us-east-1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Notice what's happening:

- The `targetRef.kind` is `MeshSubset` and the `tags` block does the matching.
- The policy applies regardless of which service a workload belongs to — every sidecar in `us-east-1` is affected.
- There is no standalone resource named `regional-baseline-subset` — the subset only exists inside this policy's `targetRef`.

### Step 2: Confirm the policy hit the right sidecars

Pick any pod tagged `region: us-east-1` and inspect its effective configuration:

```bash
kumactl inspect dataplane <us-east-1-pod-name> --mesh default --type config-dump \
  | jq '.. | objects | select(.requestTimeout?) | .requestTimeout'
```

You should see `"15s"`. Now pick a pod in any other region (e.g., `us-west-2`):

```bash
kumactl inspect dataplane <us-west-2-pod-name> --mesh default --type config-dump \
  | jq '.. | objects | select(.requestTimeout?) | .requestTimeout'
```

The `regional-baseline` policy doesn't match this pod's tags, so the timeout falls back to whatever default applies — typically Envoy's built-in 15s if no other policy is in play.

### Step 3: Try (and fail) to do this with `MeshService`

Imagine you wanted to express the same intent with `MeshService` instead. You'd have to:

1. Create a `MeshService` resource for every service in `us-east-1` that you want covered.
2. Apply one `MeshTimeout` per service.
3. Maintain that mapping every time a new service ships in `us-east-1`.

You'd also lose the property that makes `MeshSubset` valuable here: the policy automatically picks up new workloads as long as they're tagged `region: us-east-1`. With `MeshService` you'd be hand-maintaining a list.

This is the practical reason `MeshSubset` exists: cross-cutting, tag-defined policies that should auto-include new workloads.

### Step 4: Try (and fail) to route to a `MeshSubset`

The other half of the distinction: subsets can't be destinations. If you try to use one in a `backendRef`, the policy will be rejected at admission:

{% navtabs "subset-as-destination" %}
{% navtab "Kubernetes" %}
```bash
cat <<'EOF' | kubectl apply -f - || true
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: invalid-subset-route
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshService
        name: booking-engine
      rules:
        - default:
            backendRefs:
              - kind: MeshSubset       # <-- not allowed
                tags:
                  version: v2
EOF
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: invalid-subset-route
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: passenger-portal
  to:
    - targetRef:
        kind: MeshService
        name: booking-engine
      rules:
        - default:
            backendRefs:
              - kind: MeshSubset
                tags:
                  version: v2' | kumactl apply -f - || true
```
{% endnavtab %}
{% endnavtabs %}

You should see a validation error indicating `MeshSubset` isn't a supported `backendRef` kind. This is the rule from the Learn section made concrete: routing decisions require named `MeshService` resources, not tag-matched groups.

### Step 5: Clean up

```bash
kubectl delete meshtimeout regional-baseline -n kong-air-production
```

### What you did

- Applied a real cross-cutting policy with `MeshSubset` and confirmed it matched every `us-east-1` sidecar regardless of service.
- Saw how the same intent would be impractical to express with `MeshService` resources.
- Confirmed at admission time that `MeshSubset` isn't allowed in a `backendRef`.

### What's next

You now have the core mental model for {{site.mesh_product_name}}:

- **Where things run** — Control Plane / Data Plane, Global / Zone, scoping rules.
- **How to secure traffic** — mTLS, default-deny, explicit `MeshTrafficPermission`.
- **How every policy is shaped** — `targetRef` + `to`/`from` + `default`, with most-specific-wins precedence.
- **How to route traffic** — explicit `MeshService` resources + weighted `MeshHTTPRoute`.
- **Which target kind to use when** — `MeshSubset` for cross-cutting, `MeshService` for routing and named destinations.

The next paths in the {{site.mesh_product_name}} curriculum build directly on this foundation: observability, workload identity, multi-zone operations, and the advanced patterns like `MeshExternalService` and chaos engineering.
