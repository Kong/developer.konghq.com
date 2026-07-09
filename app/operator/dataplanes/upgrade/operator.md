---
title: "Upgrade {{ site.operator_product_name }}"
description: "Upgrade {{ site.operator_product_name }} with Helm, including the manual CRD steps Helm doesn't handle for you"
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

---

{{ site.operator_product_name }} is installed and upgraded exclusively with the [`kong/kong-operator` Helm chart](https://github.com/Kong/charts/tree/main/charts/kong-operator). This guide walks through a safe, step-by-step upgrade.

The most important thing to know up front: **Helm installs Custom Resource Definitions (CRDs) on the first install, but it never updates them afterwards.** Any upgrade that ships new CRD fields requires you to apply the CRDs manually *before* you upgrade the release. Skipping this is the most common cause of a broken upgrade.

## Versioning and breaking changes

{{ site.operator_product_name }} follows [Semantic Versioning](https://semver.org/):

* **Patch and minor releases** (for example `2.0.0` → `2.0.1` or `2.0` → `2.1`) never contain breaking changes. Support for deprecated features is kept, and the chart prints a warning during `helm install/status/upgrade` when your configuration uses something obsolete.
* **Major releases** (for example `1.x` → `2.0`) may require manual intervention.

Any change that needs manual action is called out in the [changelog](/operator/changelog/) and the chart's [`UPGRADE.md`](https://github.com/Kong/charts/blob/main/charts/kong-operator/UPGRADE.md). If a version isn't listed in `UPGRADE.md`, it needs no version-specific steps.

## Before you upgrade

1. **Read the [changelog](/operator/changelog/)** for every version between your current version and the target, and check [`UPGRADE.md`](https://github.com/Kong/charts/blob/main/charts/kong-operator/UPGRADE.md) for version-specific steps.
1. **Check [version compatibility](/operator/reference/version-compatibility/)** with your Kubernetes and Gateway API versions.
1. **Back up your resources.** Your `Gateway`, `GatewayConfiguration`, `DataPlane`, `ControlPlane`, and `KonnectExtension` resources are the source of truth. Export them so you can restore if needed:

   ```bash
   kubectl get gateway,gatewayconfiguration,dataplane,controlplane,konnectextension \
     -A -o yaml > operator-backup.yaml
   ```

{:.warning}
> Migrating between major versions may need extra work. See the dedicated guides for [{{ site.kic_product_name }} to {{ site.operator_product_name }}](/operator/migrate/migrate-kic-to-ko/) and [1.6.x to 2.0.0](/operator/migrate/migrate-1.6.x-2.0.0/).

## Prerequisites

* [Helm 3](https://helm.sh/docs/intro/install/) and [`kubectl`](https://kubernetes.io/docs/tasks/tools/) installed and pointed at your cluster.
* [`kustomize`](https://kubectl.docs.kubernetes.io/installation/kustomize/) (or `kubectl` v1.14+, which bundles it) for applying CRDs.
* An existing {{ site.operator_product_name }} installation deployed with the `kong/kong-operator` chart.

## Step 1: Refresh the Helm repository

Pull the latest chart metadata so Helm can see new versions:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Step 2: Note your current version

Record what's running now so you can compare after the upgrade and roll back if needed:

```bash
helm list -n kong-system
kubectl -n kong-system get pods
```

To see which chart versions are now available:

```bash
helm search repo kong/kong-operator --versions
```

## Step 3: Upgrade the CRDs

{:.warning}
> Do this **before** upgrading the release. Helm does not update CRDs on `helm upgrade`, so new fields your target version depends on will be missing until you apply them manually.

Apply the {{ site.operator_product_name }} CRDs for your target version, pinning the ref to the version you're upgrading to:

```bash
kustomize build github.com/Kong/kong-operator/config/crd/gateway-operator?ref=v{{ site.data.operator_latest.release }} | kubectl apply --server-side -f -
```

If the release also bumps the Gateway API version, apply the matching Gateway API CRDs (this repo currently targets Gateway API `{{ site.gwapi_version }}`):

```bash
kustomize build "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v{{ site.gwapi_version }}" | kubectl apply --server-side -f -
```

## Step 4: Upgrade the release

Run `helm upgrade` against the `kong-system` namespace, setting `image.tag` to your target version. Because the command uses `--install`, it's safe to re-run:

{% konnect %}
content: |
  ```bash
  helm upgrade --install kong-operator kong/kong-operator -n kong-system \
    --set image.tag={{ site.data.operator_latest.release }} \
    --set env.ENABLE_CONTROLLER_KONNECT=true
  ```
{% endkonnect %}

{% on_prem %}
content: |
  ```bash
  helm upgrade --install kong-operator kong/kong-operator -n kong-system \
    --set image.tag={{ site.data.operator_latest.release }}
  ```
{% endon_prem %}

{:.info}
> Preserve any `--set` flags or `-f values.yaml` files you used at install time (for example `env.ENABLE_CONTROLLER_*` toggles). `helm upgrade` replaces the release configuration, so flags you drop are reset to their chart defaults. To reuse your existing values without re-listing them, add `--reuse-values`.

## Step 5: Validate the upgrade

Wait for the controller manager to become available again:

{% include prereqs/products/operator-validate-deployment.md %}

Then confirm the release and pods report the new version:

```bash
helm list -n kong-system
kubectl -n kong-system get pods
```

Your `DataPlane` gateways continue serving traffic during the upgrade; only the operator control plane restarts.

## Rolling back

If something goes wrong, roll the release back to the previous revision:

```bash
helm history kong-operator -n kong-system
helm rollback kong-operator <REVISION> -n kong-system
```

{:.warning}
> A Helm rollback restores the operator Deployment, but it does **not** remove CRD fields you applied in [Step 3](#step-3-upgrade-the-crds). CRDs are additive and backward-compatible within a major version, so leaving them in place is safe. For a major-version rollback, follow the relevant migration guide (for example [1.6.x to 2.0.0](/operator/migrate/migrate-1.6.x-2.0.0/)) in reverse.

## Version-specific notes

### Migrating from {{ site.gateway_operator_product_name }} (`kong/gateway-operator` chart)

Older installs used the `kong/gateway-operator` chart with a release name like `kgo`. The chart is now `kong/kong-operator`. Because Helm doesn't manage CRD updates across this move, apply the current CRDs with server-side apply before switching charts:

```bash
kustomize build github.com/kong/kong-operator/config/crd/gateway-operator | kubectl apply --server-side -f -
```

### Upgrading from 2.0 to 2.1

{{ site.operator_product_name }} 2.1 enables [Combine HTTP routes](/kubernetes-ingress-controller/faq/combining-httproutes/) by default, which automatically reduces the number of Services that share the same `backendRef`. During the 2.0 → 2.1 upgrade, expect **a couple of seconds of downtime** for affected Services as they are merged.

To keep the old behavior, set the following in your `GatewayConfiguration` before upgrading:

```yaml
spec:
  controlPlaneOptions:
    translation:
      combinedServicesFromDifferentHTTPRoutes: disabled
```

## See also

* [{{ site.operator_product_name }} changelog](/operator/changelog/)
* [Chart `UPGRADE.md`](https://github.com/Kong/charts/blob/main/charts/kong-operator/UPGRADE.md)
* [Version compatibility](/operator/reference/version-compatibility/)
* [Install {{ site.operator_product_name }}](/operator/get-started/gateway-api/install/)
* [Migrate {{ site.kic_product_name }} to {{ site.operator_product_name }}](/operator/migrate/migrate-kic-to-ko/)
