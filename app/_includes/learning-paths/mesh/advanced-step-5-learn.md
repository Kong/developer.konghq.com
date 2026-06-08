`MeshProxyPatch` is `{{site.mesh_product_name}}'s "escape hatch". Where every other policy in this curriculum gives you a structured way to express a piece of behaviour, `MeshProxyPatch` lets you reach into the raw Envoy configuration the Control Plane generates and modify it directly with JSON-Patch operations.

That's powerful. It's also the one policy that can crash sidecars across the whole mesh in production if you point it at `kind: Mesh` and ship a typo. Treat this step accordingly.

### When `MeshProxyPatch` is the right tool

A short, conservative list. If your need is on it, `MeshProxyPatch` is justified. If it isn't, the high-level policy you _think_ doesn't exist probably does — go look once more before reaching here.

- **A WASM filter** you've written that there's no `MeshWASM`-style policy for yet.
- **A Lua HTTP filter** for one-off request/response manipulation.
- **An exotic Envoy listener filter** like a TCP TLS inspector or proxy-protocol filter.
- **Custom cluster settings** like specific connection-pool tuning that the typed policies don't yet expose.
- **A bridge filter** for an unusual protocol the mesh doesn't natively understand.

If your need is "I want different retry budgets for two services", that's `MeshRetry`, not `MeshProxyPatch`. If your need is "I want extra headers added to outbound traffic for one service", that's frequently still possible with `MeshHTTPRoute` filters — check before reaching for the patch.

### What `MeshProxyPatch` can target

The policy modifies the xDS configuration the Control Plane generates for the sidecar. The three main targets are:

| Target | What it covers | Typical patches |
| --- | --- | --- |
| **LDS** (Listener Discovery Service) | Inbound and outbound listener configs and their filter chains | Adding Lua filters, custom TLS inspectors, proxy-protocol listeners |
| **CDS** (Cluster Discovery Service) | Upstream cluster definitions, connection pools, health checks | Custom connection-pool sizing, special LB algorithms |
| **RDS** (Route Discovery Service) | HTTP route tables | Adding routes that the mesh's `MeshHTTPRoute` doesn't yet generate |

You don't write Envoy proto messages directly — you write JSON-Patch operations (`add`, `replace`, `remove`, `move`) that mutate the generated config. The CP applies them after generation and ships the result via xDS.

### The "AddBefore" / "AddAfter" model for filter chains

The most common patch shape is "insert a filter before/after this named one". For example, to add a Lua filter just before the HTTP connection manager on every outbound listener:

```yaml
spec:
  targetRef:
    kind: Mesh
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
                  request_handle:headers():add("x-kong-air-tracer", "{% raw %}{{ .DataPlaneName }}{% endraw %}")
                end
```

The pieces:

- `networkFilter` — the patch operates on the network-filter chain.
- `operation: AddBefore` — where to insert relative to `match`.
- `match` — the existing filter to anchor against (`http_connection_manager` here).
- `match.origin` — `Inbound`, `Outbound`, or omitted to apply to both. This is non-obvious and easy to miss; getting it wrong means the patch silently applies to the wrong direction.
- `value` — the Envoy filter config to insert. This is raw Envoy YAML — you're responsible for it being valid.

### The mesh-wide blast-radius warning

A single bad patch at `kind: Mesh` propagates to every sidecar in the mesh on the next xDS push. The failure mode is exactly what you'd expect: every sidecar fails to load the new config, every sidecar reverts to the last known good (some do, some don't, depending on the Envoy version), and traffic across the mesh degrades.

You can mitigate this:

- **Always scope `MeshProxyPatch` as narrowly as possible.** Use `kind: MeshService` (one service) or `kind: Dataplane` with labels (one workload type), never `kind: Mesh` for an experiment.
- **Roll out via canary.** Apply the patch in a single zone first. Watch the metrics for that zone for 30+ minutes before promoting Global.
- **Inspect the resulting config-dump.** `kumactl inspect dataplane <pod> --type config-dump` shows you the post-patch Envoy config. Diff it against pre-patch and confirm only the intended fields changed.

### Conflicts with high-level policies

A subtle failure mode: if a high-level policy (e.g., `MeshHTTPRoute`) generates the same field that `MeshProxyPatch` then modifies, the resulting behaviour is **unpredictable**. The CP doesn't enforce non-overlap; it just generates the config and applies the patches in order.

The standard practice is "patches only for things no policy generates." If you find yourself patching a field a high-level policy already manages, take the indirect route: file a feature request for the missing policy capability and use a temporary patch as a stopgap, rather than letting the patch live alongside an overlapping policy.

### Verification: always config-dump

After applying a `MeshProxyPatch`, dump the Envoy config of an affected sidecar and visually confirm:

```bash
kumactl inspect dataplane flight-control-blu-xyz-0 --type config-dump
```

Diff against a sidecar that _isn't_ affected by the patch (a different service, or one with a label that excludes it). The diff should be only what you intended; if anything else changes, the patch's match block was too broad.

### Further reading

- [`MeshProxyPatch` reference](/mesh/policies/meshproxypatch/)
- [Envoy v3 API reference](https://www.envoyproxy.io/docs/envoy/latest/api-v3/api)
- [Inspecting xDS with `kumactl inspect dataplane`](/mesh/cli/inspect/)
