---
title: Upgrading {{ site.kic_product_name }} using Helm

description: |
  Upgrade {{ site.kic_product_name }} safely, taking in to account Gateway API version changes

content_type: reference
layout: reference
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: FAQs
products:
  - kic

search_aliases:
  - upgrade kic
works_on:
  - on-prem
  - konnect

related_resources:
  - text: Upgrading {{ site.base_gateway }}
    url: /kubernetes-ingress-controller/faq/upgrading-gateway/

tags:
  - upgrade
  - helm
---

{:.warning}
> If you are upgrading from {{ site.kic_product_name }} 2.12, read the [upgrading to 3.0 section first](#upgrade-to-kong-ingress-controller-3-0)

## Prerequisites

1. Ensure that you installed {{ site.kic_product_name }} 3.0 or above, using [Helm](https://github.com/Kong/charts/).

1. Fetch the latest version of the Kong Helm chart using `helm repo update`.

1. Update your `values.yaml` file to use the latest version of {{ site.kic_product_name }}. The values to set are different depending on if you've installed with the `kong/ingress` chart or the `kong/kong` chart. You can find which chart you're using by running `helm list -A -o yaml | grep chart`.

{% capture the_code %}
{% navtabs helm %}
{% navtab "kong/ingress" %}
```yaml
controller:
  ingressController:
    image:
      tag: {{ site.data.kic_latest.release }}
```
{% endnavtab %}
{% navtab "kong/kong" %}
```yaml
ingressController:
  image:
    tag: {{ site.data.kic_latest.release }}
```
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}
{{ the_code | indent }}

## Update custom resource definitions

Custom resource definitions (CRDs) are not upgraded when running `helm upgrade`. To manually upgrade the CRDs in your cluster, run the following command:

```bash
kubectl kustomize https://github.com/kong/kubernetes-ingress-controller/config/crd?ref=v{{ site.data.kic_latest.release }} | kubectl apply -f -
```

## Gateway API versions

Gateway API resources are constantly evolving, and {{ site.kic_product_name }} is updated to use the latest version of the Gateway API CRDs with each release.

{{ site.kic_product_name }} 3.2, 3.4, and 3.5 contain Gateway API changes that require operator intervention.

### {{ site.kic_product_name }} 3.2

Starting from version 3.2, {{ site.kic_product_name }} supports Gateway API version 1.1.
The primary change in Gateway API v1.1 is the promotion of `GRPCRoute` from v1alpha2 to v1.

If you have been using the Standard Channel of the Gateway API, then you don't need to do anything extra.
Download the latest version of the CRD from the Standard Channel and install it in your cluster directly.

If you installed the Experimental Channel of Gateway API v1.0, complete the following steps to upgrade to version v1.1 of the CRD.

1. Install the Experimental Channel of Gateway API v1.1:

   ```sh
   kubectl apply --force=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/experimental-install.yaml
   ```

   `--force=true` is necessary because upstream updated the CRD directly for the alpha stage
   [without preserving the definition of the old version](https://github.com/kubernetes-sigs/gateway-api/issues/3086).

1. Update all your manifests to use `v1` instead of `v1alpha2`.
1. [Upgrade to {{ site.kic_product_name }} v3.2](#upgrade-kong-ingress-controller).

### {{ site.kic_product_name }} 3.4

Starting in {{ site.kic_product_name }} 3.4, {{ site.kic_product_name }} supports Gateway API version 1.2.
Gateway API 1.2 introduces a breaking change by removing the `v1alpha2` versions of `GRPCRoute` and `ReferenceGrant.`

If you are using Gateway API v1.1 with {{ site.kic_product_name }} 3.2 or later, and you do not have any `GRPCRoute` or `ReferenceGrant` resources in the `v1alpha2` version, you can upgrade directly to Gateway API v1.2.
You can use the following script to ensure your `GRPCRoute` and `ReferenceGrant` CRDs aren't using `v1alpha2` storage version:

```bash
kubectl get grpcroutes -A -o jsonpath='{.items[*].apiVersion}' | tr ' ' '\n' | sort | uniq -c
kubectl get referencegrants -A -o jsonpath='{.items[*].apiVersion}' | tr ' ' '\n' | sort | uniq -c
```

If the output contains `v1alpha2`, it means that there are one or more `GRPCRoute` or `ReferenceGrant` (or both) using `v1alpha2` storage version and you must update the manifests before upgrading.

Otherwise, upgrade Gateway API and {{ site.kic_product_name }} following these steps:

1. Ensure you are using Gateway API 1.1 (you can upgrade by following the steps in the section above).
2. Ensure you are using {{ site.kic_product_name }} version 3.2 or later.
3. Update all `GRPCRoute` manifests to use `v1` instead of `v1alpha2`, and all `ReferenceGrant` manifests to use `v1beta1` instead of `v1alpha2`. You can follow the [Gateway API upgrade guide](https://gateway-api.sigs.k8s.io/guides/?h=v1.2#v12-upgrade-notes) for detailed steps.
4. Install the standard or experimental channel of Gateway API 1.2.

### {{ site.kic_product_name }} 3.5

Starting from {{ site.kic_product_name }} 3.5, several Kong-specific resources have been deprecated in favor of their Gateway API equivalents, and CRDs are now managed separately.

#### Resource Deprecations

{{ site.kic_product_name }} 3.5 deprecates several Kong-specific ingress resources. While these resources continue to function, you will see deprecation warnings when using them. The recommended migration paths are:

* `KongIngress` → `KongUpstreamPolicy`
* `TCPIngress` → `TCPRoute` (from Gateway API)
* `UDPIngress` → `UDPRoute` (from Gateway API)

These deprecated resources will be removed in a future version. We recommend migrating to the Gateway API equivalents as soon as possible.

#### Gateway API Support

Starting from {{ site.kic_product_name }} 3.5, {{ site.kic_product_name }} supports Gateway API version 1.3.

To upgrade Gateway API from 1.2 to 1.3:

1. Ensure you are using {{ site.kic_product_name }} version 3.5 or later.
2. Install Gateway API 1.3 CRDs:

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
   ```

   For experimental features like CORS filters, install the experimental channel:

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml
   ```

3. [Upgrade to {{ site.kic_product_name }} v3.5](#upgrade-kong-ingress-controller).

#### New Features

The {{ site.kic_product_name }} 3.5 release introduces several new features:

* **Combined HTTP Routes (GA):** Now generally available, this feature allows you to consolidate multiple `HTTPRoute` resources into a single {{ site.base_gateway }} service. Enable with the `--combined-services-from-different-httproutes` flag.
* **Connection Draining:** Ensures graceful handling of client connections when pods terminate. Enable with the `--enable-drain-support` flag.

## Upgrade {{ site.kic_product_name }}

Run the following command, specifying the old release name, the namespace where you've configured {{site.base_gateway}}, and the existing `values.yaml` configuration file.

{% navtabs helm %}
{% navtab "kong/ingress" %}
```shell
 helm upgrade $YOUR_RELEASE_NAME kong/ingress \
  --namespace $YOUR_NAMESPACE \
  -f ./values.yaml
```
{% endnavtab %}
{% navtab "kong/kong" %}
```shell
 helm upgrade $YOUR_RELEASE_NAME kong/kong \
  --namespace $YOUR_NAMESPACE \
  -f ./values.yaml
```
{% endnavtab %}
{% endnavtabs %}

After the upgrade completes, there's a brief period of time before the new resources are online. You can wait for the relevant Pod resources to cycle by watching them in your release namespace:

```shell
 kubectl -n $YOUR_RELEASE_NAMESPACE get pods -w
```

Once the new pods are in a `Ready` state, the upgrade is complete.

## Rollback

If you run into problems during or after the upgrade, Helm provides a rollback mechanism to revert to a previous revision of the release.

```shell
 helm rollback --namespace $YOUR_RELEASE_NAMESPACE $YOUR_RELEASE_NAME
```

You can wait for the rollback to complete by watching the relevant Pod resources:

```shell
 kubectl -n $YOUR_RELEASE_NAMESPACE get pods -w
```

After a rollback, if you run into issues in production, consider using a testing environment to identify and correct these issues, or reference the [troubleshooting documentation](/index/kubernetes-ingress-controller/#troubleshooting).

## Upgrade to {{ site.kic_product_name }} 3.0

Upgrading from {{ site.kic_product_name }} 2.12 to 3.x+ is a major version change which contains breaking changes. To safely upgrade, follow these steps.

1. **Switch to Helm as your deployment mechanism.**

    As of {{ site.kic_product_name }} 3.0, [Helm](https://github.com/Kong/charts/) is the only officially supported install method.

1. **Upgrade Kong to version 3.4.1 or later.**

    {{ site.kic_product_name }} 3.0 requires {{site.base_gateway}} 3.4.1 or later. You must upgrade your {{site.base_gateway}} instances to 3.4.1 before you upgrade to {{ site.kic_product_name }} 3.0.

1. **Update the {{ site.kic_product_name }} CRDs.**

    Helm does not upgrade CRDs automatically. You must apply the 3.x CRDs before you upgrade your releases.

    ```bash
    kubectl kustomize https://github.com/Kong/kubernetes-ingress-controller/config/crd/?ref=v3.0.0 | kubectl apply -f -
    ```

1. **Convert `KongIngress` `route` and `service` fields to annotations.**

    Route (Ingress) and Service (Service) configuration fields previously available in `KongIngress` are now all handled via [dedicated annotations](/kubernetes-ingress-controller/reference/annotations/) and will not be respected if set in `KongIngress`.

    For example, if you set the `route.https_redirect_status_code` in a `KongIngress` resource, you should now use the `konghq.com/https-redirect-status-code` annotation on an Ingress or HTTPRoute resource.

1. **Remove the `CombinedRoutes` and `CombinedServices` feature gates if set.**

    The `CombinedRoutes` and `CombinedServices` feature gates have been enabled by default since versions 2.8.0 and 2.11.0, respectively. Version 3.x removes these feature gates and the combined generators are now the only option. You must remove these flags from the `CONTROLLER_FEATURE_GATES` environment variable if they are present.

1. **Remove the `Knative` feature gate if set.**

    As KNative is [no longer supported](https://github.com/Kong/kubernetes-ingress-controller/issues/2813), you need to use another controller for KNative Ingress resources if you use them.

1. **Remove or rename outdated CLI arguments and `CONTROLLER_*` environment variables.**

    Version 3.0 removes or renames several flags that were previously deprecated, removed due to other changes, or retained temporarily for compatibility after their functionality was removed.

    The CLI argument versions of these flags are listed below. If you use the equivalent `CONTROLLER_` environment variables (for example, `CONTROLLER_SYNC_RATE_LIMIT` for `--sync-rate-limit`), you must update those as well.

    * `--sync-rate-limit` is now `--proxy-sync-seconds`.
    * `--konnect-runtime-group-id` is now `--konnect-control-plane-id`.
    * `--stderrthreshold` and `--debug-log-reduce-redundancy` were removed
      following changes to the logging system.
    * `--log-level` no longer accepts the `warn`, `fatal`, and `panic` values due
      to [consolidation of log levels](#logging-changes).
    * `--update-status-on-shutdown` was removed after its earlier
      functionality was removed.
    * `--kong-custom-entities-secret` was removed after its
      functionality was removed in 2.0.
    * `--leader-elect` was removed. The controller automatically configures
      its leader election mode based on other settings.
    * `--enable-controller-ingress-extensionsv1beta1` and
      `--enable-controller-ingress-networkingv1beta1` were removed following
      removal of support for older Ingress API versions.

### Notable changes

The following changes are not considered breaking changes. However, they are notable changes from the previous version and are documented here for completeness.

#### Expression Router

{{site.base_gateway}} 3.0 introduced a new [expression-based routing engine](/gateway/routing/expressions/). This engine allows {{ site.kic_product_name }} to set some match criteria and route matching precedence not possible under the original {{site.base_gateway}} routing engine. This functionality is necessary to implement some aspects of the Gateway API specification.

DB-less configurations in the Helm chart now use the `expressions` [`router_flavor` kong.conf setting][expression-kong-conf] by default to take advantage of this functionality. DB-backed configurations use `traditional_compatible` instead for backwards compatibility, as existing route configuration from older versions cannot yet be migrated in DB mode.

Use of the new routing engine should not change route matching outside of cases where route precedence did not match the [Gateway API specification][gateway-api-precedence]. The new engine does have different performance characteristics than the old engine, but should improve matching and configuration update speed for most configurations.

[expression-kong-conf]: https://github.com/Kong/kong/blob/3.4.2/kong.conf.default#L1589-L1621
[gateway-api-precedence]: https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.HTTPRouteRule

#### Logging changes

{{ site.kic_product_name }} 3.0 uses a new logging engine to unify the logging implementation across all its subsystems. Earlier versions used different logging engines in different subsystems, which led to some logs using a different format than others and some logs appearing at incorrect log levels.

The new logging system consolidates log levels into `debug`, `info`, and `error`. Logs that were previously logged at the `warn` level are now logged at `error`, as the conditions that triggered `warn` level logs were infrequent and should not occur under normal circumstances. `fatal` and `panic` levels were available in configuration, but were not actually used.

The new logging system changes the default `console` format. In earlier versions, console logs used a `key=value` format:

```text
time="2023-09-21T23:07:26Z" level=info msg="the ingress class name has been set" logger=setup value=kong othervalue=pong
```

In 3.0, `console` is a mixture of unlabeled tab-delimited fields (for standard keys such as timestamp, log level, and log section) and JSON (for fields specific to individual log entries):

```text
2023-09-22T00:38:16.026Z        info    setup   the ingress class name has been set     {"value": "kong","othervalue":"pong"}
```

The `json` format is unchanged except for the order of fields. Earlier versions printed fields in alphabetical order:

```json
{"level":"info","logger":"setup","msg":"the ingress class name has been set","time":"2023-09-21T23:15:15Z","value":"kong"}
```

{{site.kic_product_name}} 3.0 or later prints standard log fields first and entry-specific fields in the order they were added in code:

```json
{"level":"info","time":"2023-09-22T00:28:13.006Z","logger":"setup","msg":"the ingress class name has been set","value":"kong"}
```

Although the default log setting is still `console`, `json` should be used for production systems, or any other systems that need machine-parseable logs.
