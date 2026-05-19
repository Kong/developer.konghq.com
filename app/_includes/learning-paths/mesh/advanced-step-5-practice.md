You'll inject a Lua filter that adds a header to every outbound request from a single Kong Air service. Then you'll inspect the post-patch Envoy config to confirm exactly what changed, and rehearse the "narrowest possible scope" pattern.

### Step 1: Pick a single workload to patch

Don't apply `MeshProxyPatch` to the whole mesh as an experiment. Pick one service that genuinely needs the custom filter — for this exercise, the legacy `crew-portal` service that needs a custom audit header injected into every outbound request.

### Step 2: Apply the patch, scoped to one service

`targetRef.kind: MeshService` limits the blast radius to a single service. The patch adds a Lua HTTP filter before the HTTP connection manager on outbound listeners only.

{% navtabs "proxy-patch" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshProxyPatch
metadata:
  name: crew-portal-audit-header
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: crew-portal
  default:
    appendModifications:
      - networkFilter:
          operation: AddBefore
          match:
            name: envoy.filters.network.http_connection_manager
            origin: Outbound
          value: |
            name: envoy.filters.http.lua
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
              inline_code: |
                function envoy_on_request(request_handle)
                  request_handle:headers():add("x-kong-air-audit", "crew-portal")
                end' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshProxyPatch
name: crew-portal-audit-header
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: crew-portal
  default:
    appendModifications:
      - networkFilter:
          operation: AddBefore
          match:
            name: envoy.filters.network.http_connection_manager
            origin: Outbound
          value: |
            name: envoy.filters.http.lua
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
              inline_code: |
                function envoy_on_request(request_handle)
                  request_handle:headers():add("x-kong-air-audit", "crew-portal")
                end' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Inspect the post-patch Envoy config

Pick a `crew-portal` pod and dump its sidecar's running config. Filter for the Lua filter to confirm it was applied:

```bash
POD=$(kubectl get pod -n kong-air-production -l app=crew-portal -o jsonpath='{.items[0].metadata.name}')
kumactl inspect dataplane "$POD" --type config-dump \
  | jq '.. | objects | select(.["@type"]? | strings | endswith(".Lua"))'
```

You should see:

```json
{
  "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua",
  "inline_code": "function envoy_on_request(request_handle)\n  request_handle:headers():add(\"x-kong-air-audit\", \"crew-portal\")\nend\n"
}
```

### Step 4: Confirm a non-targeted sidecar is unchanged

Pick a `flight-control` pod (not patched) and run the same dump:

```bash
OTHER_POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
kumactl inspect dataplane "$OTHER_POD" --type config-dump \
  | jq '.. | objects | select(.["@type"]? | strings | endswith(".Lua"))'
```

The output should be empty. The patch is correctly scoped to only `crew-portal` — everything else gets the unmodified config.

### Step 5: Verify the runtime behaviour

Send a request through a `crew-portal` workload and confirm the header is added:

```bash
kubectl exec -n kong-air-production "$POD" -- \
  curl -s http://httpbin.org/headers
```

The response (assuming you allow `httpbin.org` through `MeshPassthrough` or `MeshExternalService`) should include `"X-Kong-Air-Audit": "crew-portal"` in the echoed headers. If it doesn't, the filter loaded but isn't on the request path — likely a mismatch between `origin: Outbound` and the actual traffic direction.

### Step 6: Diff the full Envoy config (sanity check)

For any real-world patch, capture the config-dump diff before and after. Here's the recipe:

```bash
# Before applying the patch (use --dry-run or capture pre-patch state)
kumactl inspect dataplane "$POD" --type config-dump > /tmp/post-patch.json

# Diff against a similar non-patched workload as a proxy for pre-patch state
kumactl inspect dataplane "$OTHER_POD" --type config-dump > /tmp/unpatched.json

diff <(jq -S . /tmp/post-patch.json) <(jq -S . /tmp/unpatched.json) | head -60
```

The diff should show only the Lua filter insertion — nothing else. If you see other unexpected differences, your patch's `match` block was too broad and is anchoring against more than one location in the config.

### Step 7: Roll back

A patch is just a resource. Deleting it removes the modification and reverts the sidecar to the unpatched config on the next xDS push (within seconds).

```bash
kubectl delete meshproxypatch crew-portal-audit-header -n kong-air-production
```

Confirm with a fresh config-dump that the Lua filter is gone.

### Step 8: An anti-pattern to avoid

Just to make the danger concrete: this is what you _should not_ do, ever:

```yaml
spec:
  targetRef:
    kind: Mesh                # <-- DANGER: every sidecar in the mesh
  default:
    appendModifications:
      - networkFilter:
          operation: Patch
          # ... a patch you haven't tested ...
```

A `Mesh`-scoped patch goes out via xDS to every sidecar within seconds. If the patch produces invalid Envoy config, every sidecar in the mesh either rejects the update (best case — stale config) or crashes (worst case — outage). Always start narrow.

### What you did

- Applied a `MeshProxyPatch` scoped to one service (`crew-portal`), injecting a Lua HTTP filter on outbound listeners only.
- Inspected the resulting Envoy config to confirm the patch landed on the target and nothing else.
- Verified the runtime behaviour by observing the injected header on a real outbound request.
- Practiced the diff-against-unpatched-baseline pattern for sanity-checking any future patch.
- Rolled the patch back cleanly.

### What's next

You've now covered the full Kong Mesh curriculum: fundamentals, security and observability, multi-zone operations, and these five advanced patterns. The two comparison docs that didn't fit the path structure ([Kong Mesh vs. Istio Ambient](/mesh/scenarios/kong-mesh-vs-ambient/) and [Migrating from Istio to Kong Mesh](/mesh/scenarios/istio-to-kong-mesh/)) live under `/mesh/scenarios/` as reference material — useful when you're making platform decisions or planning a migration.
