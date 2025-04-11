---
title: "Version Support Policy"
description: "Understand the lifecycle and version support guidelines for {{site.mesh_product_name}}, including supported release timelines."
content_type: reference
layout: reference
products:
  - mesh

tags:
  - support
  - versions
  - lifecycle

works_on:
  - on-prem

related_resources:
  - text: "Version support policy for {{site.base_gateway}}"
    url: /gateway/version-support-policy/
  - text: "Version support policy for {{site.kic_product_name}}"
    url: /kubernetes-ingress-controller/support/

---
The support for {{site.mesh_product_name}} software versions is explained in this topic.

{% table %}
columns:
  - title: Version
    key: version
  - title: Latest Patch
    key: patch
  - title: Released Date
    key: released
  - title: End of Full Support
    key: support
rows:
  - version: 2.2.x
    patch: 2.2.9
    released: "2023-04-14"
    support: "2024-04-14"
  - version: 2.3.x
    patch: 2.3.7
    released: "2023-06-26"
    support: "2024-06-26"
  - version: 2.4.x
    patch: 2.4.10
    released: "2023-08-29"
    support: "2024-08-29"
  - version: 2.5.x
    patch: 2.5.11
    released: "2023-11-15"
    support: "2024-11-15"
  - version: 2.6.x
    patch: 2.6.15
    released: "2024-02-01"
    support: "2025-02-01"
  - version: 2.7.x
    patch: 2.7.13
    released: "2024-04-19"
    support: "2026-04-19"
  - version: 2.8.x
    patch: 2.8.8
    released: "2024-06-24"
    support: "2025-06-24"
  - version: 2.9.x
    patch: 2.9.5
    released: "2024-10-22"
    support: "2025-10-22"
  - version: 2.10.x
    patch: 2.10.1
    released: "2025-03-20"
    support: "2026-03-20"
  - version: 2.11.x
    patch: preview
    released: ""
    support: ""
{% endtable %}


> *Table 1: Version Support for {{site.mesh_product_name}}*

{% include_cached /support/support-policy.md %}