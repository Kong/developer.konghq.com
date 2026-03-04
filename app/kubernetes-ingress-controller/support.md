---
title: "{{site.kic_product_name}} version support policy"

description: |
  The {{site.kic_product_name}} version support policy outlines the {{site.kic_product_name}} versioning scheme and version lifecycle, from release to sunset support.

content_type: policy
layout: reference
tags:
  - support-policy
search_aliases: 
  - kic support policy
products:
  - kic
breadcrumbs:
  - /kubernetes-ingress-controller/
works_on:
  - on-prem
  - konnect
---

Learn about the support for {{site.kic_product_name}} software versions.

## Version support for {{site.kic_product_name}}

Kong primarily follows [semantic versioning](https://semver.org/) (SemVer) for its products.

At Kong’s discretion a specific minor version can be marked as a LTS version. The LTS version is supported on a given distribution for the duration of the distribution’s lifecycle, or for 3 years from LTS release whichever comes sooner. LTS only receives security fixes or certain critical patches at the discretion of Kong. Kong guarantees that at any given time, there will be at least 1 active LTS Kong version.

LTS versions of {{site.kic_product_name}} are supported for 3 years after release. Standard versions are supported for 1 year after release.

## Supported versions

{{site.kic_product_name}} can run on supported [Kubernetes distributions certified by the CNCF](https://www.cncf.io/training/certification/software-conformance/). The following table lists {{site.kic_product_name}} compatibility with versions of other dependencies.

{:.info}
> **Note**: The {{site.base_gateway}} versions listed here may or may not be currently supported by Kong. 
See the [{{site.base_gateway}} support policy](/gateway/version-support-policy/) for the full list of supported Gateway versions and their expected EOL dates.
> <br><br>
> If a Gateway version is out of support, we recommend [upgrading to a newer {{site.kic_product_name}} version](/kubernetes-ingress-controller/faq/upgrading-ingress-controller/).

{% include_cached k8s/supported-versions.md show_kic=true %}

> _Table 1: Version support for dependencies of {{site.kic_product_name}}_

## {{site.kic_product_name}} versions

The following {{site.kic_product_name}} versions are currently supported by Kong.

{:.info}
> LTS releases are marked **bold**, and are supported for 3 years from release.

{% table %}
columns:
  - title: Version
    key: version
  - title: Release Date
    key: release
  - title: End of Support
    key: support
rows:
  - version: "3.5.x"
    release: "2025-07-04"
    support: "2027-12-18"
  - version: "**3.4.x**"
    release: "**2024-12-18**"
    support: "**2027-12-18**"
  - version: "**2.12.x**"
    release: "**2023-09-25**"
    support: "**2026-09-25**"
{% endtable %}
> _Table 2: Currently supported versions of {{site.kic_product_name}}_

These versions of {{site.kic_product_name}} have reached the end of full support:

{% table %}
columns:
  - title: Version
    key: version
  - title: Release Date
    key: release
  - title: End of Support
    key: support
rows:
  - version: "3.3.x"
    release: "2024-08-26"
    support: "2025-08-26"
  - version: "3.2.x"
    release: "2024-06-12"
    support: "2025-06-12"
  - version: "3.1.x"
    release: "2024-02-07"
    support: "2025-02-07"
  - version: "3.0.x"
    release: "2023-11-03"
    support: "2024-11-03"
  - version: "2.11.x"
    release: "2023-08-09"
    support: "2024-08-09"
  - version: "2.10.x"
    release: "2023-06-02"
    support: "2024-06-02"
  - version: "2.9.x"
    release: "2023-03-09"
    support: "2024-03-09"
  - version: "2.8.x"
    release: "2022-12-19"
    support: "2023-12-19"
  - version: "2.7.x"
    release: "2022-09-27"
    support: "2023-09-27"
  - version: "2.6.x"
    release: "2022-09-15"
    support: "2023-09-15"
  - version: "**2.5.x**"
    release: "**2022-07-11**"
    support: "**2025-03-01**"
  - version: "2.4.x"
    release: "2022-06-15"
    support: "2023-06-15"
  - version: "2.3.x"
    release: "2022-04-05"
    support: "2023-04-05"
  - version: "2.2.x"
    release: "2022-02-04"
    support: "2023-02-04"
  - version: "2.1.x"
    release: "2022-01-05"
    support: "2023-01-05"
  - version: "2.0.x"
    release: "2021-10-07"
    support: "2022-10-07"
  - version: "1.3.x"
    release: "2021-05-27"
    support: "2022-05-27"
  - version: "1.2.x"
    release: "2021-03-24"
    support: "2022-03-24"
  - version: "1.1.x"
    release: "2020-12-09"
    support: "2021-12-09"
  - version: "1.0.x"
    release: "2020-10-05"
    support: "2021-10-05"
  - version: "0.x.x"
    release: "2018-06-02"
    support: "2019-06-02"
{% endtable %}
> _Table 3: Unsupported versions of {{site.kic_product_name}}_

{% include support/support-policy.md %}

## Helm chart compatibility

The [Helm chart](https://github.com/Kong/charts/) is designed to be version-agnostic with regards to support for any particular {{site.base_gateway}},
{{site.kic_product_name}}, or Kubernetes version. When possible, it detects
those versions and disables incompatible functionality.

While the Helm chart indicates a single app version, this is just the default
{{site.base_gateway}} release that chart release uses. Helm's app version
metadata doesn't support indicating a range.

New chart releases are tested against only a select group of recent
dependency and Kubernetes versions, and may have unknown compatibility problems
with older versions. If you discover a set of incompatible versions where
dependencies aren't past their end of support, [file an
issue](https://github.com/Kong/charts/issues/) with your {{site.base_gateway}},
{{site.kic_product_name}}, and Kubernetes versions and any special `values.yaml`
configuration needed to trigger the problem. Some issues may require using an
older chart version for LTS releases of other products, in which case Kong can
backport fixes to an older chart release as needed.

### CRD upgrades

The chart includes [custom resource definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
(CRDs) that aren't compatible with older Kubernetes versions.

{% include k8s/kic-crd-upgrades.md %}

## See also

- [Version support policy for {{site.base_gateway}}](/gateway/version-support-policy/)
- [Version support policy for {{site.mesh_product_name}}](/mesh/support-policy/)
