---
title: "Upgrade {{ site.operator_product_name }} with Helm"
description: "Step-by-step instructions for upgrading {{ site.operator_product_name }} with Helm, including the manual CRD steps Helm doesn't handle for you."
content_type: how_to

permalink: /operator/dataplanes/how-to/upgrade-operator/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - konnect
  - on-prem

prereqs:
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: kubectl and kustomize
      content: |
        [`kubectl`](https://kubernetes.io/docs/tasks/tools/) installed and pointed at your cluster, and [`kustomize`](https://kubectl.docs.kubernetes.io/installation/kustomize/) installed for applying CRDs (or use `kubectl kustomize` with `kubectl` v1.14+ instead).
    - title: An existing {{ site.operator_product_name }} installation
      content: |
        Deployed with the `kong/kong-operator` Helm chart. See [Install {{ site.operator_product_name }}](/operator/get-started/gateway-api/install/) if you haven't installed it yet.

tldr:
  q: How do I upgrade {{ site.operator_product_name }} with Helm?
  a: Apply the updated CRDs with `kubectl apply --server-side`, then run `helm upgrade` against the `kong-operator` release.

related_resources:
  - text: "Upgrade {{ site.operator_product_name }}"
    url: /operator/dataplanes/upgrade/operator/
  - text: "{{ site.operator_product_name }} changelog"
    url: /operator/changelog/
  - text: "Chart UPGRADE.md"
    url: https://github.com/Kong/charts/blob/main/charts/kong-operator/UPGRADE.md
  - text: "Version compatibility"
    url: /operator/reference/version-compatibility/

faqs:
  - q: How do I roll back an upgrade?
    a: |
      If something goes wrong, roll the release back to the previous revision:

      ```bash
      helm history kong-operator -n kong-system
      helm rollback kong-operator REVISION -n kong-system
      ```

      {:.warning}
      > A Helm rollback restores the operator Deployment, but it does **not** remove CRD fields you applied when [upgrading the CRDs](#upgrade-the-crds). CRDs are additive and backward-compatible within a major version, so leaving them in place is safe. For a major-version rollback, follow the relevant migration guide (for example [1.6.x to 2.0.0](/operator/migrate/migrate-1.6.x-2.0.0/)) in reverse.

---

## Review the changelog and complete pre-upgrade checks

Read the [changelog](/operator/changelog/) for every version between your current version and the target, and complete the [before-you-upgrade checks](/operator/dataplanes/upgrade/operator/#before-you-upgrade) (version compatibility and resource backups).

## Refresh the Helm repository

Pull the latest chart metadata so Helm can see new versions:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Note your current version

Record what's running now so you can compare after the upgrade and roll back if needed:

```bash
helm list -n kong-system
kubectl -n kong-system get pods
```

To see which chart versions are now available:

```bash
helm search repo kong/kong-operator --versions
```

## Upgrade the CRDs

{:.warning}
> Do this **before** upgrading the release. Helm does not update CRDs on `helm upgrade`, so new fields your target version depends on will be missing until you apply them manually.

Apply the {{ site.operator_product_name }} CRDs for the version you're upgrading to. The command below uses the latest operator version (v{{ site.data.operator_latest.release }}); if you're upgrading to a different version, replace the ref:

```bash
kustomize build "github.com/Kong/kong-operator/config/crd/gateway-operator?ref=v{{ site.data.operator_latest.release }}" | kubectl apply --server-side -f -
```

If the release also bumps the Gateway API version, apply the matching Gateway API CRDs (this repo currently targets Gateway API `{{ site.gwapi_version }}`):

```bash
kustomize build "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v{{ site.gwapi_version }}" | kubectl apply --server-side -f -
```

## Upgrade the release

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

## Validation

Wait for the controller manager to become available again:

{% include prereqs/products/operator-validate-deployment.md %}

Then confirm the release and pods report the new version:

```bash
helm list -n kong-system
kubectl -n kong-system get pods
```

Your `DataPlane` gateways continue serving traffic during the upgrade; only the operator control plane restarts.
