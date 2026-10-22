---
title: "Migrate gateways to {{site.mesh_product_name}} 3.x"
description: Replace the removed gateway annotation, labels, and built-in gateway with an API gateway and an ordinary sidecar before upgrading to {{site.mesh_product_name}} 3.x.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - migration
  - upgrade
related_resources:
  - text: Check upgrade readiness for {{site.mesh_product_name}} 3.x
    url: /mesh/check-upgrade-readiness/
  - text: Application ingress
    url: /mesh/application-ingress/
  - text: Migrate policies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-policies-to-3/
  - text: Upgrade {{site.mesh_product_name}}
    url: /mesh/upgrade/
min_version:
  mesh: '3.0'
---

{{site.mesh_product_name}} 2.x called an API gateway with a mesh sidecar a delegated gateway.
In {{site.mesh_product_name}} 3.x, the gateway joins the mesh through an ordinary sidecar.
The `kuma.io/gateway` annotation and label, the `networking.gateway` block, and the built-in
gateway are removed. Keep the API gateway and sidecar architecture, but replace its special
gateway configuration.

[Application ingress](/mesh/application-ingress/) describes how a gateway connects to the mesh
in 3.x. This page covers the changes to make before or during the upgrade. For the changes to
policies that select a gateway, see the [policy migration guide](/mesh/migrate-policies-to-3/).

## Update a delegated gateway

1. Inventory every listening port and Service on the gateway and any injected controller.
   Decide which ports accept traffic directly and which remain mesh-protected.
1. Before or together with the 3.x upgrade, replace the `kuma.io/gateway` Pod annotation with
   `traffic.kuma.io/exclude-inbound-ports`. Add `kuma.io/ignore: "true"` to gateway Services
   that shouldn't become mesh destinations. Roll out new Pods with the updated injector.
1. On Universal, remove the `kuma.io/gateway` label and old `networking.gateway` block, set the
   inbound port exclusions, and remove those ports from the `Dataplane`'s declared inbounds.
1. Replace policy selectors and locality keys that depend on `kuma.io/gateway` with labels
   you manage. Move any required custom tags from `networking.gateway.tags` to labels too.
1. Update dashboards and inspection automation. These proxies now report as ordinary
   `Dataplane` resources: `MeshMetric` reports `sidecar` rather than `gateway` for `kuma.proxy_role`,
   gateway insight counters are removed, and gateway-specific inspection filters are gone.
1. Verify public traffic, readiness probes, backend permissions, and outbound policies before
   completing the rollout. Rehearse with the exact versions you plan to deploy.

{:.warning}
> The removed `kuma.io/gateway` annotation is ignored, not rejected. A Pod can start successfully
> while public traffic is redirected through Envoy instead of reaching the gateway directly.
> Also, stored gateway labels are removed on the next `Dataplane` write, so selectors that still
> depend on them can stop matching later. Replace both the interception settings and selectors.

## Replace a built-in gateway

The steps for a delegated gateway don't cover a former built-in gateway.
{{site.mesh_product_name}} 3.x no longer reconciles `MeshGatewayInstance` deployments. Replace
that architecture with an independently managed gateway and sidecar, including its public
routes and certificates, before upgrading. [Application ingress](/mesh/application-ingress/)
describes the gateway and sidecar setup to move to.

## Validate

Follow the checks in [Verify the gateway and mesh separately](/mesh/application-ingress/#verify-the-gateway-and-mesh-separately).
Probe traffic is no longer specially exempted for gateways. If the gateway or its controller fails readiness checks
after the migration, review the probe configuration and port exclusions on each injected deployment.
