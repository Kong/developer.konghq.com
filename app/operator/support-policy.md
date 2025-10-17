---
title: "{{site.operator_product_name}} version support policy"
description: "Check if your version of {{site.operator_product_name}} is supported"
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

{% include kong-support-policy.md %}

## Version compatibility with Kubernetes

You can see the version compatibility matrix with Kubernetes versions in the [compatibility reference](/operator/reference/version-compatibility/).
