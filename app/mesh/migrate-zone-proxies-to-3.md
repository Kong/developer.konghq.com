---
title: "Migrate zone proxies to {{site.mesh_product_name}} 3.x"
description: Replace shared ZoneIngress and ZoneEgress deployments with mesh-scoped Dataplanes before upgrading zone control planes to {{site.mesh_product_name}} 3.x.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - migration
  - upgrade
  - multi-zone
related_resources:
  - text: Check upgrade readiness for {{site.mesh_product_name}} 3.x
    url: /mesh/check-upgrade-readiness/
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: Migrate mesh mTLS to MeshIdentity
    url: /mesh/migrate-mtls-to-meshidentity/
  - text: Migrate policies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-policies-to-3/
  - text: Upgrade {{site.mesh_product_name}}
    url: /mesh/upgrade/
min_version:
  mesh: '3.0'
---

Replace legacy `ZoneIngress` and `ZoneEgress` proxies while your deployment still runs a
2.x version that supports both models. In {{site.mesh_product_name}} 3.x, zone proxies are
ordinary `Dataplane` resources with `ZoneIngress` or `ZoneEgress` listeners, and each belongs
to one mesh.

The [zone-proxy reference](/mesh/mesh-scoped-zone-proxies/) explains the new traffic paths
and policy model. This page covers the order of migration, when traffic switches, and what
to verify before removing the old proxies.

For the full migration sequence, see [Upgrade from 2.x to 3.x](/mesh/upgrade/#upgrade-from-2x-to-3x).

{:.warning}
> Migrate before upgrading a zone control plane to 3.x. The 3.x control plane does not serve
> legacy standalone proxy types. An old proxy can lose service when it reconnects, even if
> it was running before the upgrade. A 3.x Helm upgrade also removes the legacy proxy
> resources owned by that release because their templates no longer exist.

## Reasons for the mesh-scoped model

The legacy `ZoneIngress` and `ZoneEgress` resources were shared across meshes in a zone.
Sharing made them different from workload proxies: they didn't belong to the mesh whose
identity, permissions and observability policies operators wanted to apply.

Mesh-scoped proxies bring those concerns together:

- **Identity belongs to the mesh.** 
  * Ian receive a workload identity through
  `MeshIdentity` and authenticate callers before forwarding external traffic.
- **Policies target the proxy directly.** You select the `Dataplane` that enforces a permission,
  records a log or applies a limit, instead of relying on separate zone-proxy configuration.
- **Operations are scoped to a mesh.** Each mesh can have its own proxy capacity, telemetry
  and rollout, using the same `Dataplane` inspection and authentication model as workloads.

The tradeoff is more infrastructure: separate meshes need separate proxy capacity and can
need separate ingress load balancers. The mesh-scoped model provides a clearer configuration and operational
boundary, not automatic network isolation or permission to access another mesh.

Because of this, the migration is a deployment and traffic migration, not just a resource rename.

## Choose the transition release

Start by [running the {{site.mesh_product_name}} 3.x readiness checker](/mesh/check-upgrade-readiness/) against the
complete estate. Its report identifies legacy `ZoneIngress` and `ZoneEgress` resources, related
`Mesh` settings, and version or control plane configuration that blocks the upgrade. Save the
report as the baseline for the migration.

{{site.mesh_product_name}} 2.14 introduced mesh-scoped zone proxies. First bring the deployment to the latest
supported 2.14 patch, following the upgrade instructions for that release. Verify compatibility for the global control plane,
all affected zones and data plane versions before starting the traffic migration.

In the 2.14 transition environment, mesh-scoped listener generation requires
`Mesh.spec.meshServices.mode: Exclusive`. Complete the move to resource-based services and
check their discovery before enabling that mode. In 3.x the mode is always `Exclusive` and the
field is deprecated. Set `meshServices.mode: Exclusive` on every mesh, including meshes that
never set it, before upgrading the global control plane. 2.x zones treat a missing field as
`Disabled`, and 3.x zones reject a mesh with any other mode. Drop the field from your manifests
after the upgrade.

## Traffic switchover

Deploying the replacements can change live traffic while legacy proxies are still running.
There is no separate promotion step that waits for you to delete the old resources.

{% table %}
columns:
  - title: Path in the transition environment
    key: path
  - title: What selects the new proxy
    key: what
  - title: What to prepare first
    key: first
rows:
  - path: "Remote `MeshService` traffic into a zone"
    what: "A usable `MeshZoneAddress` for that mesh and zone takes precedence over the legacy ingress address."
    first: |
      * Reachable ingress address
      * Working listeners
      * Destination discovery
      * Workload permissions
  - path: "External-service traffic through egress"
    what: "Ready mesh-scoped egress listener instances take precedence over the legacy egress pool. The pools aren't mixed."
    first: |
      * Identity and trust
      * External destinations
      * Explicit permissions and capacity
{% endtable %}

Start with a
test mesh or a limited production mesh and zone. Existing connections can remain on the old
path while new connections use updated endpoints; allow for draining and test long-lived
connections.

## Step 1. Inventory every mesh the old proxies serve

A shared legacy deployment may serve several meshes. Create a migration checklist for each
mesh and zone before replacing it:

- Ingress addresses, ports, load balancers, DNS records and firewall rules
- Cross-zone workload destinations and registered external services, including their protocols
- Identity issuers, trust bundles and required caller-to-destination permissions
- Proxy replica counts, resource limits, autoscaling, disruption budgets and placement rules
- Helm values or Universal startup configuration, authentication, dashboards and alerts

Save the current manifests and deployment configuration, including resources managed by
GitOps. Record successful and intentionally denied requests as your baseline. Keep the legacy
deployment available until every mesh that depends on it has passed the migration checks.

## Step 2. Prepare identities, destinations and policies

Prepare the identity and trust configuration described in the
[MeshIdentity migration](/mesh/migrate-mtls-to-meshidentity/). Give the new egress proxies an
issuing identity, and prepare permissions for the clients that connect to them.

Don't complete the application identity rollout before deploying egress. Workloads using
`MeshExternalService` need mesh-scoped zone egress when they switch to `MeshIdentity`. Deploy
and validate the egress first, then switch a canary client and test its external-service calls
before migrating the remaining clients.

Use `MeshExternalService` for external destinations served by the new egress. Its listener
generator doesn't consume legacy `ExternalService` configuration. Verify the
destination endpoints and upstream TLS settings rather than copying only the service name.

Prepare policies that select the new `Dataplane` resources, using the computed ingress or egress
role labels and, where needed, a zone label and listener `sectionName`. For more information, see
[Proxy and traffic selection](/mesh/mesh-scoped-zone-proxies/#proxy-and-traffic-selection).

For egress, apply explicit `MeshTrafficPermission` allows for the required callers and
destinations. Without a matching allow, egress denies traffic. A legacy mesh-wide external-access
toggle isn't a replacement for these permissions. Review existing broad allows and denies
too: they can make a narrow rule less restrictive than expected or prevent it from allowing
traffic at all.

Keep permission enforcement for cross-zone workload traffic on the destination workload
proxy. The new ingress forwards workload mTLS without terminating it; assigning ingress an
identity doesn't make it authenticate the original caller.

Prepare the policy form supported by your transition release. Coordinate any later 3.x schema
rewrites with the [policy migration guide](/mesh/migrate-policies-to-3/).

## Step 3. Deploy replacements while retaining the legacy proxies

### Kubernetes

Add per-mesh settings to the zone's existing Helm values. On the transition release, retain
the legacy `kuma.ingress` and `kuma.egress` settings while adding the new entries:

```yaml
kuma:
  meshes:
    - name: default
      ingress:
        enabled: true
      egress:
        enabled: true
```

Keep the control plane connection settings and other meshes, add an entry for each mesh that
needs proxies, and carry over the capacity and availability settings that apply to it.

Use distinct names and listening addresses for the replacements. Don't point an existing
load balancer at both models as a substitute for the control plane's discovery transition:
the models can use different destination names and TLS identities.

Check the ingress Service's published address before relying on it. New ingress publication
uses `MeshZoneAddress`, derived from the Service and ready endpoints. Legacy Pod annotations
for ingress public address and port don't configure that resource. Configure the Service's
load balancer, NodePort or external IP as appropriate for the network.

Remember that publication can switch incoming traffic immediately. Prepare firewall rules,
DNS and backend reachability before the new address becomes discoverable.

### Universal

Start a separate ordinary `kuma-dp` with a new `Dataplane` name and the required
`networking.listeners`. Don't restart the legacy process in place as your first test.
Use a dataplane token bound to the replacement proxy rather than a legacy ingress, egress
or zone token.

For ingress, publish the reachable address using `MeshZoneAddress` on the zone control
plane only when the new proxy is ready for incoming traffic. For egress, a ready listener can
enter discovery as soon as the `Dataplane` is available, so you must prepare its identity and
permissions beforehand.

The [zone-proxy reference](/mesh/mesh-scoped-zone-proxies/#universal) contains the `Dataplane`
and address examples. Keep the old processes, credentials and address configuration available
for rollback during the transition.

## Step 4. Verify traffic through the new proxies

For each migrated mesh and zone:

1. Inspect the replacement `Dataplane` resources and confirm their role labels, mesh, listener
   names and accepted Envoy configuration. An accepted resource or running Pod isn't sufficient.
1. Inspect the endpoints in a calling proxy. Confirm that cross-zone traffic uses the new
   ingress address and that external traffic uses the new egress instances.
1. Send a fresh cross-zone request and verify the destination workload and zone. Confirm
   that the replacement ingress's connection counters or logs change.
1. Send an allowed external-service request and verify activity on the replacement egress.
   Test a disallowed caller and destination as well.
1. Check TLS validation, upstream errors, latency and telemetry against the baseline. Exercise
   representative HTTP, gRPC and TCP traffic and reconnect long-lived clients where relevant.
1. Allow the old connections to drain. Confirm that no other mesh still depends on the shared
   legacy deployment before removing it.

Pause the rollout if configuration is rejected, expected traffic fails, or denied traffic is
unexpectedly allowed. Investigate on the transition release rather than upgrading to 3.x to
try to resolve the failure.

## Step 5. Remove legacy configuration, then upgrade to 3.x

After all affected meshes pass validation, retire the legacy deployments through the tool that
owns them. Review the planned removals before applying a Helm or GitOps change.

{% table %}
columns:
  - title: Legacy configuration
    key: legacy
  - title: Replacement or action
    key: replacement
rows:
  - legacy: "`kuma.ingress` and `kuma.egress` Helm blocks"
    replacement: "Use `kuma.meshes[].ingress` and `kuma.meshes[].egress`. Remove the old blocks before the 3.x chart upgrade."
  - legacy: "`--proxy-type=ingress` or `--proxy-type=egress`"
    replacement: "Run an ordinary `Dataplane` with zone listeners. Remove the corresponding proxy-type environment override."
  - legacy: "Zone-proxy tokens and `dpServer.authn.zoneProxy` settings"
    replacement: "Use the data plane authentication model. Kubernetes uses the configured service account authentication; Universal commonly uses dataplane tokens."
  - legacy: "`Mesh.routing.defaultForbidMeshExternalServiceAccess`"
    replacement: "Express external access with `MeshTrafficPermission`; the toggle is removed in 3.x."
  - legacy: "`Mesh.routing.zoneEgress`"
    replacement: "Remove for 3.x. Don't use the old switch to disable or roll back the new topology."
  - legacy: "Standalone zone-proxy inspection endpoints and commands"
    replacement: "Inspect the replacement as a `Dataplane`, using `/meshes/{mesh}/dataplanes/{name}/{xds,stats,clusters}`."
  - legacy: "Universal `runtime.universal.zoneResourceCleanupAge`"
    replacement: "Review `runtime.universal.dataplaneCleanupAge`, which now also governs zone proxies and defaults to 72 hours."
{% endtable %}

Don't copy every old Helm field under the new mesh entry. Several legacy options, including
`drainTime`, custom probes and `service.nodePort`, have no same-named per-mesh equivalent.
Review the target chart's values; drain and probe behavior now follows the sidecar injection
configuration. The unrelated `controlPlane.ingress` settings still configure access to the
control plane API and GUI, not cross-zone traffic.

Before the first zone upgrade, rerun the
[{{site.mesh_product_name}} 3.x readiness checker](/mesh/check-upgrade-readiness/) while all control planes are still on
the latest supported 2.14 patch. Resolve every remaining legacy zone-proxy finding and coverage
gap. The report can't verify addresses, firewall rules, capacity, or live traffic, so it doesn't
replace the checks in this guide.

Proceed with the supported 3.x upgrade sequence only after traffic no longer depends on
standalone zone proxies: upgrade the global control plane first, then the zones. Repeat the
traffic checks after each zone upgrade and update dashboards that still query legacy proxy
resources or insight endpoints.

{:.warning}
> **Publish each zone's `MeshZoneAddress` as soon as that zone runs 3.x.** In 3.x, other zones
> reach a zone's ingress only through its `MeshZoneAddress`, and the resource cannot be created
> before the zone control plane runs 3.x. Cross-zone `MeshService` and `MeshMultiZoneService`
> traffic into the zone is down until the resource exists and has synced to the other zones.
> On Kubernetes, the upgraded zone control plane creates it from the ingress Service; check that
> it appears. On Universal, create it on the zone control plane immediately after the upgrade.

{:.warning}
> **Restart the zone proxies after upgrading a zone control plane.** A zone proxy Pod keeps
> the data plane image it was admitted with, so upgrading the control plane alone leaves it
> running the previous `kuma-dp`. {{site.mesh_product_name}} 3.x removed state-of-the-world xDS,
> and a proxy whose bootstrap still requests it never receives configuration at all:
>
> ```text
> StreamAggregatedResources gRPC config stream closed: 12, unsupported
> SOTW/state-of-the-world xDS StreamAggregatedResources; restart the proxy with a
> delta-capable bootstrap to use Delta ADS
> ```
> {:.no-copy-code}
>
> The Pod stays `Running` and `Ready` while this repeats, and its listeners keep whatever
> they last held, so the failure surfaces only as cross-zone requests returning `503`.
> Restart the ingress and egress Deployments, then confirm the new Pods run the expected
> image and that the SOTW gRPC config stream error has stopped. Replace `default` with the mesh
> name:
>
> ```sh
> kubectl -n {{site.mesh_namespace}} rollout restart deploy/kong-mesh-default-ingress deploy/kong-mesh-default-egress
> ```
>
> Then check the ingress proxy logs for the SOTW error:
>
> ```sh
> kubectl -n {{site.mesh_namespace}} logs deploy/kong-mesh-default-ingress -c kuma-sidecar | grep SOTW
> ```

## Roll back while both models are supported

Prepare and rehearse rollback before enabling the replacements. The legacy proxies must
still be healthy and the control planes must still support them.

For ingress, withdraw the new `MeshZoneAddress` from discovery so the transition control
plane can fall back to the legacy address. On Kubernetes, change the controller-owned
deployment or Service configuration responsible for publication: deleting only the generated
resource can cause the controller to recreate it. Verify address withdrawal in the consuming
zones before considering rollback complete.

For egress, withdraw the replacement's ready listeners from discovery. The transition control
plane falls back to the legacy pool only when it resolves no mesh-scoped egress instances.
Leaving another ready replacement instance can keep traffic on the new path.

Restore and verify the earlier traffic behavior, including trust and permissions. Endpoint
changes don't move established connections instantly; plan for draining or reconnection.

Once a zone control plane runs 3.x, restarting a legacy proxy isn't a rollback strategy.
Any return to 2.x requires the product's supported control plane and data recovery procedure,
not only restoration of the old Deployment.
