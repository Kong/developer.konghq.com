Kong Air doesn't actually have one team; it has a passenger-services team, a flight-operations team, a security team, and a recently-acquired subsidiary (`KongAir-EU`) whose engineers have never seen the rest of the platform. Putting all of them on a single mesh is convenient — until it isn't. {{site.mesh_product_name}} supports two structural answers to "who shares the mesh", with very different operational profiles.

### Soft multi-tenancy: one mesh, many namespaces

Each team is assigned one or more namespaces (or Universal environments) inside a single mesh. Everyone gets a sidecar issued by the same CA, every workload shares a trust domain, and policies can target across team boundaries.

What this looks like in practice:

- **One Root CA** issues every certificate. Identity flows are direct and fast.
- **Policies are namespace-scoped** by convention — `MeshTrafficPermission` resources are applied in `kong-air-production`, `kong-air-eu`, etc., not in `kong-mesh-system`.
- **A central platform team** owns the `Mesh` resource, `MeshIdentity`, `MeshTrust`, and any mesh-wide baselines. Application teams own the policies that point at _their_ services.
- **Service-to-service calls between tenants** happen at full sidecar performance — no extra hop, no extra TLS termination — gated by `MeshTrafficPermission`.

This is the default. It's what every example so far has assumed.

### Hard multi-tenancy: one mesh per tenant

Each tenant gets a dedicated mesh. The clusters can be shared, but the mesh boundaries are absolute: a sidecar in mesh A literally cannot present a valid identity to a sidecar in mesh B without traversing an explicit cross-mesh gateway.

What this looks like in practice:

- **Separate Root CAs** per mesh. Trust domains are disjoint by default.
- **Separate policy surfaces** — a `MeshTrafficPermission` in mesh A is invisible to mesh B and vice versa.
- **Cross-mesh traffic goes through a gateway** — typically {{site.base_gateway}} configured as the mesh boundary, with explicit allowlisting.
- **Independent operational lifecycles** — mesh A can be on `{{site.mesh_product_name}} 2.10` while mesh B is on 2.12. Upgrades, certificate rotations, and policy changes happen on independent schedules.

### Side by side

| Concern | Soft (shared mesh) | Hard (isolated meshes) |
| --- | --- | --- |
| **Trust domain** | Single | One per mesh |
| **Identity scope** | Global across the mesh | Local to each mesh |
| **Tenant-to-tenant calls** | Direct, gated by `MeshTrafficPermission` | Via cross-mesh gateway |
| **Policy management** | Centralized + delegated | Fully decentralized |
| **CP overhead** | One Global + one Zone per cluster | One Global + N×Zones per cluster (per mesh) |
| **Upgrade coordination** | Single rolling upgrade | Each tenant on its own cadence |
| **Best for** | Internal microservices, intra-company teams | Regulated business units, B2B, M&A integrations |

### When to actually go hard

Soft multi-tenancy covers ~80% of real cases. Reach for hard multi-tenancy specifically when:

- **A regulator requires it** — for example, PCI-scoped workloads where the audit boundary needs to be mechanical, not policy-enforced.
- **An acquired company can't be re-platformed quickly** — give them their own mesh with their own CA, federate where you need to, defer full integration to a future quarter.
- **Two business units share infrastructure but not trust** — Kong Air's cargo and passenger divisions might share clusters but never have a reason to call each other's services.

If your reason for considering hard multi-tenancy is "two teams keep stepping on each other's policy changes", the better answer is usually **Kubernetes RBAC + soft multi-tenancy** — restrict who can edit which resources, not which mesh they live in.

### Decoupling delivery from mesh policy

Either model benefits from treating mesh policy as code in a separate-from-application-deploys pipeline. Two patterns worth adopting from the start:

#### Per-tenant CI/CD

Application teams own a `mesh/` directory in their service repo containing policies that target their own services (`MeshHTTPRoute`, `MeshRetry`, `MeshFaultInjection`). Their CI deploys those alongside their application manifests.

#### Platform-owned baselines

The platform team owns a separate repo for the mesh-wide policies: `MeshTLS`, `MeshTrust`, `MeshIdentity`, default `MeshTimeout`, default `MeshAccessLog`. Those changes go through a slower, more scrutinized release process.

In hard multi-tenancy, the platform repo branches per mesh. In soft multi-tenancy, the platform repo applies once at the Global CP, and Kubernetes RBAC keeps application teams out.

### Further reading

- [Multi-mesh deployments](/mesh/multi-mesh/)
- [Cross-mesh gateways](/mesh/cross-mesh-gateway/)
- [GitOps for {{site.mesh_product_name}}](/mesh/gitops/)
