---
title: "{{site.operator_product_name}} version support policy"
description: "Check if your version of {{ site.operator_product_name }} is supported"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/

---

Kong primarily follows [semantic versioning](https://semver.org/) (SemVer) for its products.

At Kong’s discretion a specific minor version can be marked as a LTS version. The LTS version is supported on a given distribution for the duration of the distribution’s lifecycle, or for 3 years from LTS release whichever comes sooner. LTS only receives security fixes or certain critical patches at the discretion of Kong. Kong guarantees that at any given time, there will be at least 1 active LTS Kong version.

LTS versions of {{site.operator_product_name}} are supported for 3 years after release. Standard versions are supported for 1 year after release.

{:.info}
> {{site.operator_product_name}} is a recently released product and does not currently provide an LTS version.

{% support_policy operator %}

> *Table 1: Version Support for {{site.operator_product_name}}*

{% include support/support-policy.md %}

## Rapid releases

{{site.operator_product_name}} uses a rapid release channel. Some functionality, particularly {{site.ai_gateway_name}}, evolves faster than the quarterly minor release cadence that {{site.base_gateway}} functionality follows. Rapid releases let Kong ship that functionality when it's ready.

Rapid releases are fully supported, production grade releases. They aren't previews, betas, or experimental builds.

The two channels are cumulative, not alternatives. Every change in a rapid release is included in the next standard quarterly minor version, so you can choose the channel that suits your use case:

<!-- vale off -->
{% table %}
columns:
  - title: Channel
    key: channel
  - title: Cadence
    key: cadence
  - title: Supported versions
    key: supported
  - title: Use case
    key: suits
rows:
  - channel: "Rapid"
    cadence: "Between quarterly minor versions, as functionality is ready."
    supported: "The two most recent rapid releases. When a new rapid release ships, the third most recent one is no longer supported."
    suits: "Teams who want new {{site.ai_gateway_name}} functionality as soon as it ships and can upgrade often."
  - channel: "Standard"
    cadence: "Quarterly minor versions."
    supported: "1 year from release."
    suits: "Teams who prefer a fixed upgrade cadence and a longer support window."
{% endtable %}
<!-- vale on -->

See the [{{site.ai_gateway_name}} version support policy](/ai-gateway/version-support-policy/) for the support policy covering {{site.ai_gateway}} functionality.

### Versioning and installation

{%- assign rapid = site.data.products.operator.rapid %}

A rapid release is versioned as a pre-release of the standard minor version it leads into, for example {{site.operator_product_name}} `{{ rapid.app }}` on chart version `{{ rapid.chart }}`.

Helm therefore treats rapid releases as pre-releases and skips them unless you ask for one explicitly. Without `--version`, `helm install` gives you the latest stable chart, which doesn't include the functionality that has only shipped in a rapid release.

To list the rapid releases available in the chart repository:

```bash
helm search repo kong/kong-operator --devel --versions
```

To install a rapid release, or to move an existing installation onto a newer one, set the chart version explicitly. `--reuse-values` keeps the values you installed with:

```bash
helm upgrade kong-operator kong/kong-operator -n kong-system --version {{ rapid.chart }} --reuse-values
```

For a full install walkthrough, see [Install {{site.operator_product_name}}](/operator/install/).

## Version compatibility with Kubernetes

You can see the version compatibility matrix with Kubernetes versions in the [compatibility reference](/operator/reference/version-compatibility/).
