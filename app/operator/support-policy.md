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

{% table %}
columns:  
  - version: "2.0.x"
    release: "2025-09-09"
    support: "2026-09-09"
  - version: "1.6.x"
    release: "2025-05-07"
    support: "2026-05-07"
  - version: "1.5.x"
    release: "2025-03-11"
    support: "2026-03-11"
  - version: "1.4.x"
    release: "2024-10-31"
    support: "2025-10-31"
  - version: "1.3.x"
    release: "2024-06-24"
    support: "2025-06-24"
  - version: "1.2.x"
    release: "2024-03-15"
    support: "2025-03-15"
  - version: "1.1.x"
    release: "2023-11-20"
    support: "2024-11-20"
  - version: "1.0.x"
    release: "2023-09-27"
    support: "2024-09-29"
{% endtable %}

## Version compatibility with Kubernetes

You can see the version compatibility matrix with Kubernetes versions in the [compatibility reference](/operator/reference/version-compatibility/).
