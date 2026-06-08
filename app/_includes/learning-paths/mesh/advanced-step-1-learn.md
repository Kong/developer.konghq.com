Out of the box, a {{site.mesh_product_name}} sidecar lets a workload reach _any_ external destination. If `flight-control` decides to phone home to `attacker.example.com:443`, the sidecar happily proxies the connection — that's the "Original Destination" cluster Envoy ships with by default. Permissive defaults are great for getting started; they're a poor production posture for a company that runs flight-critical infrastructure.

`MeshPassthrough` is the policy that flips this from open to closed.

### Three modes, two questions

`MeshPassthrough` has exactly one knob — `passthroughMode` — with three settings. The decision tree is:

| Mode | Behaviour | Use when |
| --- | --- | --- |
| `All` | Allow any outbound destination. **Default.** | Dev meshes, getting started, environments where you trust every workload. |
| `None` | Block any outbound destination that isn't a known mesh service or `MeshExternalService`. | Zero-trust production posture. |
| `Matched` | Allow only the destinations enumerated in `appendMatch`. | Most real production — `None` is too tight, `All` is too loose. |

The `Matched` mode is what most real meshes settle on. `None` is theoretically purer but means every external dependency has to be a `MeshExternalService` (Step 2 of this path), which is more setup than is justified for simple cases.

### What `Matched` matches on

You enumerate destinations as a list of `appendMatch` entries, each with a `type`, `value`, `port`, and `protocol`:

```yaml
default:
  passthroughMode: Matched
  appendMatch:
    - type: IP
      value: "1.2.3.4/32"
      port: 443
      protocol: tls
    - type: Domain
      value: "*.googleapis.com"
      port: 443
      protocol: tls
    - type: Domain
      value: "*.cloudwatch.amazonaws.com"
      port: 443
      protocol: https
```

The `type` field accepts:

- `IP` for a single address or CIDR (`1.2.3.4`, `10.0.0.0/8`).
- `Domain` for an exact hostname (`api.example.com`) or wildcard (`*.example.com`). Wildcard matches one DNS label.
- `Port` for matching by port number alone, regardless of destination — rarely the right tool.

{% warning %}
`Domain`-type entries **require** a `protocol` field (`http`, `tls`, `grpc`, etc.). The Control Plane rejects the resource at admission if you leave it off. This is the single most common shape error people hit with `MeshPassthrough`.
{% endwarning %}

### Where the policy executes

This matters more than it looks like it should. There are two execution sites for the passthrough decision:

#### Direct mode (no ZoneEgress)

The decision happens inside the **calling sidecar**. Every workload's Envoy has a copy of the policy and decides locally whether each outbound destination is allowed.

- Pro: low latency, no extra hop.
- Con: every sidecar emits its own access log for blocked traffic; aggregating across the whole zone is a manual exercise.

#### Egress mode (with ZoneEgress)

The decision happens at the **ZoneEgress** — the centralized outbound proxy you may have deployed in the previous path's Step 1.

- Pro: one central exit point to monitor and audit; firewall rules can lock down outbound network access to "only the egress IP."
- Pro: easy to scope `MeshPassthrough` to "the egress" rather than every sidecar, simplifying policy lifecycle.
- Con: extra hop; more capacity to manage at the egress tier.

For regulated environments (PCI, HIPAA, SOC2 outbound-control requirements) the egress-mode pattern is almost always required.

### Layering: broad default + service-specific exceptions

Like every other {{site.mesh_product_name}} policy, `MeshPassthrough` resolves with "most specific wins" precedence. The pattern that scales is:

1. **Mesh-level default of `None`** — every service blocked by default.
2. **`MeshService`-level exceptions** for the few workloads that legitimately need broader access.

For example: most of Kong Air's services should reach only mesh-internal destinations and a handful of named SaaS providers. The `data-warehouse-loader` job, on the other hand, needs to upload to many S3 buckets across multiple AWS accounts. Rather than enumerating every bucket as a domain match, you'd apply a `MeshService`-level passthrough on `data-warehouse-loader` that allows `*.s3.amazonaws.com:443` while the mesh-wide policy stays `None`.

```yaml
spec:
  targetRef:
    kind: MeshService
    name: data-warehouse-loader   # Override only this service
  default:
    passthroughMode: Matched
    appendMatch:
      - type: Domain
        value: "*.s3.amazonaws.com"
        port: 443
        protocol: tls
```

### `MeshPassthrough` vs. `MeshExternalService`

Both control outbound traffic; they solve different problems.

| | `MeshPassthrough` | `MeshExternalService` |
| --- | --- | --- |
| What it does | Allowlists raw destinations | Makes the destination feel like an internal service |
| Naming | Use the external hostname directly | Use a friendly mesh hostname (`aeropay.ext.svc`) |
| Observability | Counted in egress metrics; no per-service breakdown | Full per-service metrics and traces |
| Policy targets | None | Can apply `MeshRetry`, `MeshTimeout`, `MeshCircuitBreaker`, etc. |
| Use when | Many low-value destinations; CIDR ranges; "lots of S3 buckets" | A few critical dependencies; you want resilience policies |

In a mature mesh, you typically use both: `MeshPassthrough` provides the broad allowlist, `MeshExternalService` (next step) elevates the critical dependencies.

### Further reading

- [`MeshPassthrough` reference](/mesh/policies/meshpassthrough/)
- [ZoneEgress configuration](/mesh/zone-egress/)
- [`MeshExternalService` (Step 2 of this path)](/learning-paths/mesh/advanced-patterns/step-2/)
