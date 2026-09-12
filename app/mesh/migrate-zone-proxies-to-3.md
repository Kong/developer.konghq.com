---
title: "Migrate zone proxies to {{site.mesh_product_name}} 3"
description: Replace shared ZoneIngress and ZoneEgress deployments with mesh-scoped Dataplanes before upgrading zone control planes to Mesh 3.
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
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: Migrate mesh mTLS to MeshIdentity
    url: /mesh/migrate-mtls-to-meshidentity/
  - text: Migrate policies to Mesh 3
    url: /mesh/migrate-policies-to-3/
---

Replace legacy `ZoneIngress` and `ZoneEgress` proxies while your deployment still runs a
2.x version that supports both models. In {{site.mesh_product_name}} 3, zone proxies are
ordinary `Dataplane` resources with `ZoneIngress` or `ZoneEgress` listeners, and each belongs
to one mesh.

The [zone-proxy reference](/mesh/mesh-scoped-zone-proxies/) explains the new traffic paths
and policy model. This page covers the order of migration, when traffic switches, and what
to verify before removing the old proxies.

{:.warning}
> Migrate before upgrading a zone control plane to v3. The v3 control plane does not serve
> legacy standalone proxy types. An old proxy can lose service when it reconnects, even if
> it was running before the upgrade. A v3 Helm upgrade also removes the legacy proxy
> resources owned by that release because their templates no longer exist.

## Choose the transition release

Mesh-scoped zone proxies were introduced in 2.14. First bring the deployment to a supported
2.14.x release that includes the new deployment and policy functionality, following the
upgrade instructions for that release. Verify compatibility for the global control plane,
all affected zones and data plane versions before starting the traffic migration.

Do not treat the presence of the new API alone as proof that every required migration fix is
available in your installed patch release. Rehearse the sequence below with the exact chart
and images you plan to use. This guide does not replace the product's supported version
upgrade sequence.

In the 2.14 transition environment, mesh-scoped listener generation requires
`Mesh.spec.meshServices.mode: Exclusive`. Complete the move to resource-based services and
check their discovery before enabling that mode. In v3, the field is removed and the new
service model is unconditional; do not carry this setting forward as a v3 prerequisite.

## Understand when traffic switches

Deploying the replacements can change live traffic while legacy proxies are still running.
There is no separate promotion step that waits for you to delete the old resources.

| Path in the transition environment | What selects the new proxy | What to prepare first |
| --- | --- | --- |
| Remote `MeshService` traffic into a zone | A usable `MeshZoneAddress` for that mesh and zone takes precedence over the legacy ingress address. | Reachable ingress address, working listeners, destination discovery and workload permissions. |
| External-service traffic through egress | Ready mesh-scoped egress listener instances take precedence over the legacy egress pool. The pools are not mixed. | Egress identity and trust, external destinations, explicit permissions and capacity. |

These are discovery choices, not a weighted canary between old and new proxies. Start with a
test mesh or a limited production mesh and zone. Existing connections can remain on the old
path while new connections use updated endpoints; allow for draining and test long-lived
connections. Do not assume that coexistence guarantees a disruption-free migration.

## 1. Inventory every mesh the old proxies serve

A shared legacy deployment may serve several meshes. Create a migration checklist for each
mesh and zone before replacing it:

- Ingress addresses, ports, load balancers, DNS records and firewall rules.
- Cross-zone workload destinations and registered external services, including their protocols.
- Identity issuers, trust bundles and required caller-to-destination permissions.
- Proxy replica counts, resource limits, autoscaling, disruption budgets and placement rules.
- Helm values or Universal startup configuration, authentication, dashboards and alerts.

Save the current manifests and deployment configuration, including resources managed by
GitOps. Record successful and intentionally denied requests as your baseline. Keep the legacy
deployment available until every mesh that depends on it has passed the migration checks.

## 2. Prepare identities, destinations and policies

Complete the relevant [MeshIdentity migration](/mesh/migrate-mtls-to-meshidentity/) and
ensure the new egress proxies will match an identity selector. Include the clients that will
connect to them and establish the required trust before allowing traffic.

Use `MeshExternalService` for external destinations served by the new egress. Legacy
`ExternalService` configuration is not consumed by its listener generator. Verify the
destination endpoints and upstream TLS settings rather than copying only the service name.

Prepare policies that select the new Dataplanes, using the computed ingress or egress role
labels and, where needed, a zone label and listener `sectionName`. See
[selecting zone proxies](/mesh/mesh-scoped-zone-proxies/#select-the-proxy-then-select-its-traffic).

For egress, apply explicit `MeshTrafficPermission` allows for the required callers and
destinations. Without a matching allow, traffic is denied. A legacy mesh-wide external-access
toggle is not a replacement for these permissions. Review existing broad allows and denies
too: they can make a narrow rule less restrictive than expected or prevent it from allowing
traffic at all.

Keep permission enforcement for cross-zone workload traffic on the destination workload
proxy. The new ingress forwards workload mTLS without terminating it; assigning ingress an
identity does not make it authenticate the original caller.

Prepare the policy form supported by your transition release. Coordinate any later v3 schema
rewrites with the [policy migration guide](/mesh/migrate-policies-to-3/); do not assume a v3
manifest is accepted unchanged by every 2.x version.

## 3. Deploy replacements while retaining the legacy proxies

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

This is a values fragment, not a replacement for the installation's full values file. Keep
the control plane connection settings and other meshes. Add an entry for each mesh that
needs proxies and carry over the capacity and availability settings that apply to it.

Use distinct names and listening addresses for the replacements. Do not point an existing
load balancer at both models as a substitute for the control plane's discovery transition:
the models can use different destination names and TLS identities.

Check the ingress Service's published address before relying on it. New ingress publication
uses `MeshZoneAddress`, derived from the Service and ready endpoints. Legacy Pod annotations
for ingress public address and port do not configure that resource. Configure the Service's
load balancer, NodePort or external IP as appropriate for the network.

Remember that publication can switch incoming traffic immediately. Prepare firewall rules,
DNS and backend reachability before the new address becomes discoverable.

### Universal

Start a separate ordinary `kuma-dp` with a new `Dataplane` name and the required
`networking.listeners`. Do not restart the legacy process in place as your first test.
Use a dataplane token bound to the replacement proxy rather than a legacy ingress, egress
or zone token.

For ingress, publish the reachable address using `MeshZoneAddress` on the zone control
plane only when the new proxy is ready for incoming traffic. For egress, a ready listener can
enter discovery as soon as the Dataplane is available, so its identity and permissions must
already be prepared.

The [zone-proxy reference](/mesh/mesh-scoped-zone-proxies/#universal) contains the Dataplane
and address examples. Keep the old processes, credentials and address configuration available
for rollback during the transition.

## 4. Verify the new proxies carry traffic

For each migrated mesh and zone:

1. Inspect the replacement Dataplanes and confirm their role labels, mesh, listener names and
   accepted Envoy configuration. An accepted resource or running Pod is not sufficient.
1. Inspect the endpoints in a calling proxy. Confirm that cross-zone traffic uses the new
   ingress address and that external traffic uses the new egress instances.
1. Send a fresh cross-zone request and verify the destination workload and zone. Confirm
   that the replacement ingress's connection counters or logs change.
1. Send an allowed external-service request and verify activity on the replacement egress.
   Test a disallowed caller and destination as well as the successful case.
1. Check TLS validation, upstream errors, latency and telemetry against the baseline. Exercise
   representative HTTP, gRPC and TCP traffic and reconnect long-lived clients where relevant.
1. Allow the old connections to drain. Confirm that no other mesh still depends on the shared
   legacy deployment before removing it.

Pause the rollout if configuration is rejected, expected traffic fails, or denied traffic is
unexpectedly allowed. Investigate on the transition release rather than upgrading to v3 to
try to resolve the failure.

## 5. Remove legacy configuration, then upgrade to v3

After all affected meshes pass validation, retire the legacy deployments through the tool that
owns them. Review the planned removals before applying a Helm or GitOps change.

| Legacy configuration | Replacement or action |
| --- | --- |
| `kuma.ingress` and `kuma.egress` Helm blocks | Use `kuma.meshes[].ingress` and `kuma.meshes[].egress`. Remove the old blocks before the v3 chart upgrade. |
| `--proxy-type=ingress` or `--proxy-type=egress` | Run an ordinary Dataplane with zone listeners. Remove the corresponding proxy-type environment override. |
| Zone-proxy tokens and `dpServer.authn.zoneProxy` settings | Use the data plane authentication model. Kubernetes uses the configured service account authentication; Universal commonly uses dataplane tokens. |
| `Mesh.routing.defaultForbidMeshExternalServiceAccess` | Express external access with `MeshTrafficPermission`; the toggle is removed in v3. |
| `Mesh.routing.zoneEgress` | Remove for v3. Do not use the old switch to disable or roll back the new topology. |
| Standalone zone-proxy inspection endpoints and commands | Inspect the replacement as a Dataplane, using `/meshes/{mesh}/dataplanes/{name}/{xds,stats,clusters}`. |
| Universal `runtime.universal.zoneResourceCleanupAge` | Review `runtime.universal.dataplaneCleanupAge`, which now also governs zone proxies and defaults to 72 hours. |

Do not copy every old Helm field under the new mesh entry. Several legacy options, including
`drainTime`, custom probes and `service.nodePort`, have no same-named per-mesh equivalent.
Review the target chart's values; drain and probe behavior now follows the sidecar injection
configuration. The unrelated `controlPlane.ingress` settings still configure access to the
control plane API and GUI, not cross-zone traffic.

Proceed with the supported v3 upgrade sequence only after traffic no longer depends on
standalone zone proxies. Repeat the traffic checks after each zone upgrade and update
dashboards that still query legacy proxy resources or insight endpoints.

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
changes do not move established connections instantly; plan for draining or reconnection.

Once a zone control plane runs v3, restarting a legacy proxy is not a rollback strategy.
Any return to v2 requires the product's supported control plane and data recovery procedure,
not just restoration of the old Deployment.
