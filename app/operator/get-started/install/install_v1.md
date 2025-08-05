---

title: Install {{ site.kong_gateway_operator_product_name }}
content_type: how_to
description: |
  Install {{ site.kong_gateway_operator_product_name }} using Helm
products:
  - operator
breadcrumbs:
  - /operator/
tldr:
    q: Can I install {{ site.kong_gateway_operator_product_name }} using Kustomize or any other tools?
    a: |
        Currently, the only way to install {{ site.kong_gateway_operator_product_name }} is using Helm.

min_version:
  operator: '1.0'

max_version:
  operator: '2.0'

---

## Install {{ site.operator_product_name }}

{% include prereqs/products/operator.md raw=true v_maj=1 %}
