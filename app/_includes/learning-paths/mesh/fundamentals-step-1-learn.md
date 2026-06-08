{{site.mesh_product_name}} is an enterprise service mesh with a unified control plane that manages services across Kubernetes, VMs, and bare metal. Unlike traditional meshes that require platform-specific configuration, the same policies work everywhere. Throughout this path, you'll follow **Kong Air** — a global airline modernizing its flight-critical infrastructure — from securing their first check-in service to splitting traffic for a booking-engine rollout.

### The control plane and the data plane

{{site.mesh_product_name}} separates the **Control Plane** (the brain) from the **Data Plane** (the muscle):

- **Data Plane (DP)** — an Envoy sidecar that runs alongside each application instance. It intercepts all inbound and outbound traffic, enforces mTLS, retries, and rate limits, and gives the service a stable identity.
- **Control Plane (CP)** — the management layer that discovers workloads, holds the policy state, and pushes xDS configuration to every Data Plane.

### Global CP and Zone CP

For distributed environments, the Control Plane splits into two tiers:

- **Global Control Plane** — the single source of truth for policies and mesh-wide resources. It's where you create the `Mesh` resource and any global configuration.
- **Zone Control Plane** — one per cluster, region, or data center. Zone CPs discover local workloads and distribute xDS to the sidecars in their zone. They receive a read-only copy of Global resources via the **Kuma Discovery Service (KDS)** sync protocol.

This separation is what lets a single mesh span multiple Kubernetes clusters and legacy VM data centers without becoming a single point of failure: if a zone loses its connection to the Global CP, every Data Plane in that zone keeps serving traffic with its last-known configuration.

### A Kong Air–shaped diagram

{% mermaid %}
flowchart TD
    subgraph Global["Central management"]
        GCP[Global Control Plane]
        GUI["Konnect / kumactl"]
    end

    subgraph Zone1["Zone: Kubernetes (cloud)"]
        Z1CP[Zone Control Plane]
        subgraph SvcA["Check-in service (K8s)"]
            P1[Envoy sidecar]
            App1[Check-in app]
        end
    end

    subgraph Zone2["Zone: Legacy data center (VM)"]
        Z2CP[Zone Control Plane]
        Z2Ingress[ZoneIngress]
        subgraph SvcB["Flight control (VM)"]
            P2[Envoy sidecar]
            App2[Booking API]
        end
    end

    GUI --- GCP
    GCP ==>|Sync policies| Z1CP
    GCP ==>|Sync policies| Z2CP
    Z1CP -.->|xDS| P1
    Z2CP -.->|xDS| P2
    App1 --> P1
    P1 == Cross-zone tunnel ==> Z2Ingress
    Z2Ingress --> P2
    P2 --> App2
{% endmermaid %}

### One policy model, three target kinds

Where other meshes fragment behaviour across `VirtualService`, `DestinationRule`, `ServiceEntry`, and `Gateway` resources, {{site.mesh_product_name}} consolidates onto a single shape — the `targetRef` policy. You'll dive into the mechanics in Step 3; for now, just notice the three things a policy can point at:

| Target kind | Scope | Kong Air example |
| --- | --- | --- |
| `Mesh` | Every sidecar in the mesh | Baseline mTLS and request logging for all of Kong Air. |
| `MeshSubset` | A tag-matched group of sidecars | Tighter timeouts for everything in `region: us-east-1`. |
| `MeshService` | A specific service | A 10% canary on `booking-engine-v2`. |

### Where resources live: scoping rules

In multi-zone mode, every resource has an authoritative "source of truth" CP. Apply it to the wrong one and you'll either get an error or silently overwrite Global state from a Zone.

**Global CP only:**

- `Mesh` — defines mesh structure and the mTLS backend.
- `MeshMultiZoneService` — declares services that span zones.

**Global CP _or_ Zone CP:**

- `MeshIdentity`, `MeshTrust`, `MeshTrafficPermission`, `MeshTLS`, `MeshFaultInjection`, `MeshPassthrough`, and most other policies. Applying at the Global CP propagates the policy to every zone; applying at a Zone CP keeps it local.

{% tip %}
**Standalone mode** is the third option: a single Control Plane with no Global/Zone distinction. Scoping rules don't apply because there's only one tier. The examples in this path work in either standalone or multi-zone mode — anywhere you see `(Global CP)` in a code tab, that's the CP to target in multi-zone deployments.
{% endtip %}

### The Kubernetes system-namespace rule

On Kubernetes, infrastructure-level identity resources (`MeshIdentity`, `MeshTrust`) **must** live in the system namespace — typically `kong-mesh-system`. This isn't cosmetic:

1. **Access control** — only platform engineers have RBAC on the system namespace, so application developers can't accidentally rewrite trust roots.
2. **Clear authority** — putting infrastructure resources next to application resources blurs ownership; the system namespace makes the line explicit.

Universal mode doesn't have Kubernetes namespaces, so resources are identified by `name` and `mesh` fields instead, and the target CP is determined by which API `kumactl` is pointed at.

### Documentation tab conventions

Throughout this path, code samples show both Kubernetes and Universal mode side by side. The tab labels indicate where to run each command:

- **`Kubernetes (Global CP)`** — `kubectl` against your Global CP kubeconfig.
- **`Universal (Global CP)`** — `kumactl` pointed at the Global CP API.
- **`Kubernetes`** — `kubectl` against any zone CP, or your standalone cluster.
- **`Universal`** — `kumactl` against any Universal zone CP or standalone deployment.

### Further reading

- [{{site.mesh_product_name}} architecture overview](/mesh/)
- [Control plane vs. data plane reference](/mesh/control-plane/)
- [Multi-zone deployments](/mesh/multi-zone-deployment/)
