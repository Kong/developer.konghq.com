---
title: "Upgrade {{ site.operator_product_name }}"
description: "Understand how {{ site.operator_product_name }} versioning works, what to check before upgrading, and version-specific upgrade notes"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Upgrading

related_resources:
  - text: "Upgrade {{ site.operator_product_name }} with Helm"
    url: /operator/dataplanes/how-to/upgrade-operator/
  - text: "{{ site.operator_product_name }} changelog"
    url: /operator/changelog/
  - text: "Chart UPGRADE.md"
    url: https://github.com/Kong/charts/blob/main/charts/kong-operator/UPGRADE.md
  - text: "Version compatibility"
    url: /operator/reference/version-compatibility/
  - text: "Install {{ site.operator_product_name }}"
    url: /operator/get-started/gateway-api/install/
  - text: "Migrate {{ site.kic_product_name }} to {{ site.operator_product_name }}"
    url: /operator/migrate/migrate-kic-to-ko/

---

{{ site.operator_product_name }} is installed and upgraded exclusively with the [`kong/kong-operator` Helm chart](https://github.com/Kong/charts/tree/main/charts/kong-operator). This page covers what to know before you upgrade; for the step-by-step procedure, see [Upgrade {{ site.operator_product_name }} with Helm](/operator/dataplanes/how-to/upgrade-operator/).

The most important thing to know is that Helm installs Custom Resource Definitions (CRDs) on the first install, but it never updates them afterwards. Any upgrade that ships new CRD fields requires you to apply the CRDs manually before you upgrade the release. Skipping this is the most common cause of a broken upgrade.

## Versioning and breaking changes

{{ site.operator_product_name }} follows [Semantic Versioning](https://semver.org/):

* **Patch and minor releases** (for example `2.0.0` → `2.0.1` or `2.0` → `2.1`) never contain breaking changes. Support for deprecated features is kept, and the chart prints a warning during `helm install/status/upgrade` when your configuration uses something obsolete.
* **Major releases** (for example `1.x` → `2.0`) may require manual intervention.

Any change that needs manual action is called out in the [changelog](/operator/changelog/) and the chart's [`UPGRADE.md`](https://github.com/Kong/charts/blob/main/charts/kong-operator/UPGRADE.md). If a version isn't listed in `UPGRADE.md`, it needs no version-specific steps.

## Before you upgrade

1. Read the [changelog](/operator/changelog/) for every version between your current version and the target, and check [`UPGRADE.md`](https://github.com/Kong/charts/blob/main/charts/kong-operator/UPGRADE.md) for version-specific steps.
1. Read the [chart changelog](https://github.com/Kong/charts/blob/main/charts/kong-operator/CHANGELOG.md) for every chart version between your current version and the one including the {{site.operator_product_name}} version bump.
1. Check [version compatibility](/operator/reference/version-compatibility/) with your Kubernetes and Gateway API versions.
1. Back up your resources. Your `Gateway`, `GatewayConfiguration`, `DataPlane`, `ControlPlane`, and `KonnectExtension` resources are the source of truth. Export them so you can restore if needed:

   ```bash
   kubectl get gateway,gatewayconfiguration,dataplane,controlplane,konnectextension \
     -A -o yaml > operator-backup.yaml
   ```

{:.warning}
> Migrating between major versions may need extra work. See the dedicated guides for [{{ site.kic_product_name }} to {{ site.operator_product_name }}](/operator/migrate/migrate-kic-to-ko/) and [1.6.x to 2.0.0](/operator/migrate/migrate-1.6.x-2.0.0/).

## Version-specific notes

### Migrating from {{ site.gateway_operator_product_name }} (`kong/gateway-operator` chart)

Older installs used the `kong/gateway-operator` chart with a release name like `kgo`. The chart is now `kong/kong-operator`. Because Helm doesn't manage CRD updates across this move, apply the current CRDs with server-side apply before switching charts:

```bash
kustomize build github.com/kong/kong-operator/config/crd/gateway-operator | kubectl apply --server-side -f -
```

### Upgrading from 2.0 to 2.1

{{ site.operator_product_name }} 2.1 enables [Combine HTTP routes](/kubernetes-ingress-controller/faq/combining-httproutes/) by default, which automatically reduces the number of Services that share the same `backendRef`. During the 2.0 → 2.1 upgrade, expect a couple of seconds of downtime for affected Services as they are merged.

To keep the old behavior, set the following in your `GatewayConfiguration` before upgrading:

```yaml
spec:
  controlPlaneOptions:
    translation:
      combinedServicesFromDifferentHTTPRoutes: disabled
```
