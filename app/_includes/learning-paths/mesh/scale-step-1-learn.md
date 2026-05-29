Kong Air's services don't all live in one cluster. The reservation system runs on EKS in `us-east-1`, the legacy booking engine still lives on VMs in a Dallas data centre, and the EU customer-data services run on GKE in Frankfurt. {{site.mesh_product_name}}'s multi-zone fabric is what makes all of that look like one mesh from a policy and identity standpoint.

This step is the conceptual layer; Step 2 onwards is where you actually use it.

### The two-tier Control Plane

You already met this distinction in Fundamentals. To recap with the parts that matter for this path:

| Tier | Responsibility | Failure isolation |
| --- | --- | --- |
| **Global CP** | Authoritative for policies, `Mesh`, `MeshMultiZoneService`, and the global registry of zone-local services. | If it goes down, existing zones keep serving traffic with their last-known state — they don't get _new_ config until it returns. |
| **Zone CP** | Discovers local workloads, distributes xDS to local sidecars, exposes the local MADS endpoint for Prometheus, runs the local ZoneIngress and ZoneEgress. | One zone going down has no effect on other zones. |

The Global CP talks to each Zone CP over a long-lived gRPC channel called **KDS** — the Kuma Discovery Service. Policies you apply at the Global CP propagate down KDS to every zone. Service registrations in each zone propagate up KDS to the Global CP, which then redistributes them to peer zones.

### ZoneIngress: the inbound proxy for cross-zone traffic

When a sidecar in `us-east-1` calls a service that lives in `eu-west-1`, the traffic doesn't go directly to a remote pod IP — it goes to that zone's **ZoneIngress** first. The ZoneIngress is a dedicated Envoy proxy at the zone perimeter that:

- Accepts mTLS connections from sidecars in other zones.
- Looks at the SNI / SPIFFE ID and routes to the correct local pod.
- Advertises the local zone's services to the Global CP so they're discoverable from elsewhere.

In Kubernetes, {{site.mesh_product_name}} deploys and manages a ZoneIngress for you automatically. In Universal mode, you run it as a process on a host with a routable public address.

You don't apply policies to a ZoneIngress directly — it picks them up from the workloads it's serving. Think of it as a multiplexer, not a workload in its own right.

### ZoneEgress: optional, but recommended for compliance

A **ZoneEgress** is the mirror image: a centralized proxy for all _outbound_ traffic leaving the zone. It's optional, but turning it on gives you three things compliance teams routinely ask for:

- **Single exit point** — your network team can write firewall rules against one egress IP instead of every node.
- **Unified egress audit** — one place to capture access logs for every external call.
- **`MeshExternalService` enforcement** — policies that govern outbound traffic (covered in the Advanced Patterns path) execute at the egress, not in every sidecar.

If you don't deploy a ZoneEgress, each sidecar routes outbound traffic directly. That's simpler, but distributes your egress audit surface across every workload.

### `MeshMultiZoneService` (MMZS): one logical service, many zones

In a single-zone mesh, a `MeshService` resolves to a set of local endpoints. In a multi-zone mesh, you often want a service to span zones — a `check-in-api` instance in both `us-east-1` and `eu-west-1`, callable as one logical thing.

That's `MeshMultiZoneService`. It's a Global-CP resource that selects across `MeshService` resources in every zone:

```yaml
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
  ports:
    - port: 8080
      appProtocol: http
```

When a sidecar calls `check-in-api-all.mzsvc.kong-air-production.mesh.local`, the mesh resolves to endpoints in every zone that has a matching `MeshService`. Combined with `MeshLoadBalancingStrategy` (next), this is how you express "prefer local, fail over remote."

{% warning %}
Two MMZS gotchas worth knowing up front: (1) The `kuma.io/origin: global` label is **required** on every MMZS resource — without it, KDS won't sync it to other zones. (2) The port spec **must** include `appProtocol: http` (or `grpc`/`tcp`) — without it, the protocol defaults to `tcp` and `MeshHTTPRoute` policies that target the MMZS will be silently ignored.
{% endwarning %}

### Locality-aware load balancing

By default, when a sidecar has the choice between a same-zone and a remote-zone endpoint for the same service, it picks the same-zone one. This is locality-aware routing and it's on by default.

You shape the behaviour with **`MeshLoadBalancingStrategy`**:

- Toggle locality awareness on or off per destination.
- Configure cross-zone failover (`if all local endpoints fail, route to ANY remote zone`).
- Weight regions for active-active deployments.

You'll use this resource in Step 3 to add a safety net under the per-zone canary.

### Cross-zone discovery, traces, metrics, and logs

You don't need to do anything special for telemetry to work across zones. The MADS endpoint each Zone CP exposes is what makes that work:

- **Metrics**: A single Prometheus pointed at every Zone CP's MADS endpoint discovers every sidecar in every zone.
- **Traces**: Tracing context propagates through the ZoneIngress hop automatically — a single trace shows the full cross-zone path.
- **Logs**: `MeshAccessLog` at the Global CP applies in every zone. Point all zones at the same Loki/Splunk and you have one log surface for the whole fabric.

This is the same observability story from the previous path, just operating at multi-zone scale.

### Further reading

- [Multi-zone deployment guide](/mesh/multi-zone-deployment/)
- [`MeshMultiZoneService` reference](/mesh/policies/meshmultizoneservice/)
- [ZoneIngress and ZoneEgress reference](/mesh/zone-ingress-egress/)
- [`MeshLoadBalancingStrategy` reference](/mesh/policies/meshloadbalancingstrategy/)
