---
title: Feature gates

description: |
  Learn how to customize {{ site.kic_product_name }}'s behavior using feature flags

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Reference

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
related_resources:
  - text: Stages of software availability
    url: /stages-of-software-availability/
  - text: Kubernetes
    url: https://kubernetes.io
  - text: Kubernetes feature gates
    url: https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/
  - text: Feature stages
    url: https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/#feature-stages
---


Feature gates enable contributors to add and manage new (and potentially experimental) functionality to the {{site.kic_product_name}} in a controlled way. The features will be "hidden" until they are generally available (GA) and the progress and maturity of features on their path to GA will be documented. Feature gates also create a clear path for deprecating features.

Upstream [Kubernetes](https://kubernetes.io) includes [feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/), which enable or disable features with flags and track the maturity of a feature using [feature stages](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/#feature-stages).
The same definitions of `feature gates` and `feature stages` from upstream Kubernetes are used to define KIC's list of features.


## Available feature gates

The following feature gates are available:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Default
    key: default
  - title: Stage
    key: stage
  - title: Since
    key: since
  - title: Until
    key: until
rows:
  - feature: GatewayAlpha
    default: '`false`'
    stage: Alpha
    since: 2.6.0
    until: TBD
  - feature: FillIDs
    default: '`true`'
    stage: Beta
    since: 3.0.0
    until: TBD
  - feature: RewriteURIs
    default: '`false`'
    stage: Alpha
    since: 2.12.0
    until: TBD
  - feature: KongServiceFacade
    default: '`false`'
    stage: Alpha
    since: 3.1.0
    until: TBD
  - feature: SanitizeKonnectConfigDumps
    default: '`true`'
    stage: Beta
    since: 3.1.0
    until: TBD
  - feature: FallbackConfiguration
    default: '`false`'
    stage: Alpha
    since: 3.2.0
    until: TBD
  - feature: KongCustomEntity
    default: '`false`'
    stage: Alpha
    since: 3.2.0
    until: 3.3.0
  - feature: KongCustomEntity
    default: '`true`'
    stage: Beta
    since: 3.3.0
    until: 3.4.0
  - feature: KongCustomEntity
    default: '`true`'
    stage: GA
    since: 3.4.0
    until: TBD
{% endtable %}

* The **since** and **until** columns refer to [KIC Releases](https://github.com/Kong/kubernetes-ingress-controller/releases).
* Features that are currently in alpha or beta states may become deprecated at any time. Deprecated features are removed during the next minor release.
* Until a feature becomes GA, there are no guarantees that it will continue being available. For more information, see the [changelog](https://github.com/Kong/kubernetes-ingress-controller/blob/main/CHANGELOG.md).

{:.warning}
>**Important:** To avoid disrupting your services, consider not using features until they have reached GA status.

### SanitizeKonnectConfigDumps

The `SanitizeKonnectConfigDumps` feature enables the sanitization of configuration dumps that are sent to {{site.konnect_short_name}}.
This means {{site.kic_product_name}} will obfuscate all sensitive information that your Kong config contains, such as
private keys in `Certificate` entities and `Consumer` entities' credentials.

{:.warning}
> **Warning:** `KongPlugin`'s and `KongClusterPlugin`'s `config` fields are not sanitized. If you have sensitive information
> in your `KongPlugin`'s `config` field, it will be sent to Konnect as is. To avoid this, use the
> [KongVault](/kubernetes-ingress-controller/reference/custom-resources/#kongvault) resource.


## Using feature gates

To enable feature gates, provide the `--feature-gates` flag when launching KIC, or set the `CONTROLLER_FEATURE_GATES` environment variable.

Feature gates consist of a comma-delimited set of `key=value` pairs. For example, if you wanted to enable `FillIDs` and `RewriteURIs`, you'd set `CONTROLLER_FEATURE_GATES=FillIDs=true,RewriteURIs=true`.

To enable features via Helm, set the following in your `values.yaml`:

{% navtabs chart %}
{% navtab "kong/ingress" %}
```yaml
controller:
  ingressController:
    env:
      feature_gates: FillIDs=true,RewriteURIs=true
```
{% endnavtab %}
{% navtab "kong/kong" %}
```yaml
ingressController:
  env:
    feature_gates: FillIDs=true,RewriteURIs=true
```
{% endnavtab %}
{% endnavtabs %}

To test a feature gate in an existing deployment, use `kubectl set env`.

```bash
kubectl set env -n kong deployment/kong-controller \
  CONTROLLER_FEATURE_GATES="FillIDs=true,RewriteURIs=true" \
  -c ingress-controller
```