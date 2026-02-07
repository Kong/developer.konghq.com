---
title: "Upgrade {{ site.operator_product_name }}"
description: "Deploy a new version of {{ site.operator_product_name }} using Helm"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Upgrading

---

{{ site.operator_product_name }} uses [Semantic Versioning](https://semver.org/) and will not make breaking changes between major releases.

To upgrade between minor releases, follow the steps shown in the [installation guide](/operator).

For major releases, consult the [changelog](/operator/changelog/) to see if there are any changes that require manual intervention before following the installation instructions.

When using the helm chart to install the operator please also consult the [`UPGRADE.md`](https://github.com/Kong/charts/blob/main/charts/gateway-operator/UPGRADE.md) file in the charts repository.
