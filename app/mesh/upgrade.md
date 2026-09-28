---
title: Upgrade {{site.mesh_product_name}}
description: Reference guide for upgrading {{site.mesh_product_name}} across versions. Covers compatibility rules, upgrade order, and considerations for single-zone and multi-zone deployments.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - upgrade

works_on:
  - on-prem

related_resources:
  - text: Check readiness for {{site.mesh_product_name}} 3
    url: /mesh/check-upgrade-readiness/
  - text: Version-specific upgrade notes
    url: /mesh/version-specific-upgrade-notes/
  - text: Version support policy
    url: /mesh/support-policy/

min_version:
  mesh: '2.6'
---

## Upgrade from 2.x to 3

Version 3 removes legacy policy APIs, mesh-wide mTLS configuration, and shared ZoneIngress and
ZoneEgress resources. Prepare those resources and traffic paths while the deployment is still on
2.14; this is more than a control plane and data plane rollout.

1. [Run the Mesh 3 readiness checker](/mesh/check-upgrade-readiness/) against the current 2.x
   deployment and save the report.
1. Bring every control plane and data plane proxy to the latest supported 2.14 patch. Follow the
   [version-specific upgrade notes](/mesh/version-specific-upgrade-notes/) for every intermediate
   release in the upgrade path.
1. Resolve the report using the migration guides for
   [mTLS and MeshIdentity](/mesh/migrate-mtls-to-meshidentity/),
   [mesh-scoped zone proxies](/mesh/migrate-zone-proxies-to-3/), and
   [policies](/mesh/migrate-policies-to-3/). The guides explain their dependencies and the order
   in which live traffic changes.
1. Rerun the readiness checker against the complete estate. Resolve every blocker and coverage
   gap, complete its manual checks, and validate representative traffic.
1. Upgrade a non-production zone first. Repeat the product and traffic checks before proceeding
   through the remaining zones.

Do not use the normal rolling-upgrade sequence below as a substitute for the 2.x-to-3 migration.
The readiness report identifies configuration visible through the control plane API; the migration
guides cover the live traffic behavior that the report cannot verify.

## Compatibility between minor versions

Starting with {{site.mesh_product_name}} 1.4.x, upgrades can be performed up to two minor versions. For example:
* You can upgrade from `2.12.x` to `2.13.x`
* You can upgrade from `2.11.x` to `2.13.x`
* To upgrade from `2.9.x` to `2.13.x`, first upgrade from `2.9.x` to `2.11.x`, then from `2.11.x` to `2.13.x`.

{:.warning}
> Some versions have specific upgrade instructions. Make sure to read the [version specific upgrade notes](/mesh/version-specific-upgrade-notes/) for more information.

{:.info}
> To avoid control plane downtime when restarting on the new version, make sure you have more than one instance of the control plane in each zone.

`kuma-dp` follows the above compatibility rules with `kuma-cp`. For example:
* You can connect `kuma-dp` `2.11.x` to `kuma-cp` `2.13.x`.
* You cannot connect `kuma-dp` `2.10.x` to `kuma-cp` `2.13.x`. It may cause undefined behavior.

The global control plane follows the above compatibility rules with zone control planes. For example:
* You can connect zone control plane `2.11.x` to global control plane `2.13.x`.
* You cannot connect zone control plane `2.10.x` to global control plane `2.13.x`. It may cause undefined behavior.

Although control planes within a zone don't connect to each other, they share a common [store](/mesh/control-plane-configuration/#store) (usually Kubernetes or PostgreSQL). Compatibility of the storage layer also follows the minor version rules:
* You can read any data written on control plane `2.11.x` with a control plane version `2.13.x`.
* You can read any data written on control plane `2.13.x` with a control plane version `2.11.x`.
* You cannot read data written on control plane `2.10.x` with a control plane version `2.13.x` or higher. It may cause undefined behavior.
* You cannot read data written on control plane `2.13.x` with a control plane version `2.10.x` or lower. It may cause undefined behavior.


{:warning}
> Some feature flags may not provide backward compatibility. When this is the case, it's clearly documented in the [control plane configuration](/mesh/reference/kuma-cp/) and will be part of the `experimental` section.
>
> To guarantee our compatibility policy, we will always wait at least two minor versions before making these features enabled by default.

## Single-zone

To upgrade {{site.mesh_product_name}} with a single-zone deployment, first upgrade the control plane, then upgrade data plane proxies.
To upgrade data plane proxies on Kubernetes, rollout the new deployment to allow the injector to inject the newest sidecar.

## Multi-zone

To upgrade {{site.mesh_product_name}} with a multi-zone deployment, first upgrade the global control plane. Then, upgrade the zone control planes. As a last step, upgrade data plane proxies by manually restarting them.
