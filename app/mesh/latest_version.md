---
layout: none
skip_index: true
---
{%- assign latest = site.data.products.mesh.releases | find: "latest", true -%}
{{latest.version}}