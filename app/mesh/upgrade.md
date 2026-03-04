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
  - text: Version-specific upgrade notes
    url: /mesh/version-specific-upgrade-notes/
  - text: Version support policy
    url: /mesh/support-policy/

min_version:
  mesh: '2.6'
---

Since {{site.mesh_product_name}} 1.4.x upgrades can be performed up to two minor versions. For example:
* You can upgrade from `2.12.x` to `2.13.x`
* You can upgrade from `2.11.x` to `2.13.x`
* To upgrade from `2.9.x` to `2.13.x`, first upgrade from `2.9.x` to `2.11.x`. Then from `2.11.x` to `2.13.x`.

{:.warning}
> Some versions have specific upgrade instructions. Make sure to read the [version specific upgrade notes](/mesh/version-specific-upgrade-notes/) for more information.

{:.info}
> To avoid control plane downtime when restarting on the new version make sure you have more than one instance of the control plane in each zone.

`kuma-dp` follows the above compatibility rules with `kuma-cp`. For example:
* You can connect `kuma-dp` `2.11.x` to `kuma-cp` `2.13.x`
* You cannot connect `kuma-dp` `2.10.x` to `kuma-cp` `2.13.x`. It may cause undefined behavior.

The global control plane follows the above compatibility rules with zone control planes. For example:
* You can connect zone control plane `2.11.x` to global control plane `2.13.x`.
* You cannot connect zone control plane `2.10.x` to global control plane `2.13.x`. It may cause undefined behavior.

Although control planes within a zone don't connect to each other, they share a common [store](/mesh/control-plane-configuration/#store) (usually Kubernetes or Postgres). Compatibility of the storage layer follows the above rules too:
* You can read any data written with a control plane `2.11.x` with a control plane version `2.13.x`.
* You can read any data written with a control plane `2.13.x` with a control plane version `2.11.x`.
* You cannot read data written with a control plane `2.10.x` with a control plane version `2.13.x` or higher. It may cause undefined behavior.
* You cannot read data written with a control plane `2.13.x` with a control plane version `2.10.x` or lower. It may cause undefined behavior.


{:warning}
> Some feature flags may not provide backward compatibility. When this is the case, it's clearly documented in the [control plane configuration](/mesh/reference/kuma-cp/) and will be part of the `experimental` section.
>
> To guarantee our compatibility policy we will always wait at least two minor versions before making these features enabled by default.

## Single-zone

To upgrade {{site.mesh_product_name}} with a single-zone deployment, first upgrade the control plane, then upgrade data plane proxies.
To upgrade data plane proxies on Kubernetes, rollout the new deployment to allow the injector to inject the newest sidecar.

## Multi-zone

To upgrade {{site.mesh_product_name}} with a multi-zone deployment, first upgrade the global control plane. Then, upgrade the zone control planes. As a last step, upgrade data plane proxies by manually restarting them.

## Version-specific upgrade notes

{% embed UPGRADE.md %}