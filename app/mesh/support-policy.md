---
title: "{{site.mesh_product_name}} version support policy"
description: "Understand the lifecycle and version support guidelines for {{site.mesh_product_name}}, including supported release timelines."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - support-policy
  - versioning

works_on:
  - on-prem

related_resources:
  - text: "Version support policy for {{site.base_gateway}}"
    url: /gateway/version-support-policy/
  - text: "Version support policy for {{site.kic_product_name}}"
    url: /kubernetes-ingress-controller/support/

---
The support for {{site.mesh_product_name}} software versions is explained in this topic.

## {{site.mesh_product_name}} release policy

Kong adopts a structured approach to versioning its products. {{site.mesh_product_name}} follow a pattern of {MAJOR}.{MINOR}.{PATCH}.

{% capture long_term_support %}
{% table %}
columns:
  - title: LTS Version
    key: version
  - title: Planned release date
    key: date
rows:
  - version: "2.13"
    date: January 2026
  - version: "2.17"
    date: January 2027
  - version: "2.21"
    date: January 2028
{% endtable %}
{% endcapture%}

{:.info}
> **Long Term Support Policy Update**
> <br><br>
> Beginning in January 2026, we plan to release 4 minor versions per year, every year: one in January, one in April, one in July, and the last one in October.
> Each year, the first version we release will become an LTS release.
> Starting from 2.13, we will have 1 LTS release every year, in January of that year.
> <br><br>
> Example of planned LTS schedule for next 4 years:
> {{long_term_support | strip | replace: "
", "
> "}}


{:.info}
> Each LTS is supported for 2 years from the date of release.
> This will allow adjacent LTS releases to have a support overlap of 1 year in which customers can plan their upgrades.
> <br><br>
> _* Release timeframes are subject to change._

## Supported versions

The following table explains which versions of {{site.mesh_product_name}} are supported:

{% include support/mesh.md %}
> *Table 1: Version support for {{site.mesh_product_name}}*

{% include_cached /support/support-policy.md %}
