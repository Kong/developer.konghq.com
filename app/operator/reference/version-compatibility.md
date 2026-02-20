---
title: "Version compatibility"
description: "Understand which versions of Kubernetes and the Gateway API {{ site.operator_product_name }} works with"
content_type: reference
layout: reference

breadcrumbs:
  - /operator/
  - index: operator
    section: Reference

products:
  - operator

---

The following table presents the general compatibility of {{site.operator_product_name}} with {{ site.kic_product_name }} minor versions.

## Kubernetes

## {{ site.kic_product_name }}

{:.info}
> **Note:**
> {{ site.operator_product_name }} 2.0.0+ includes {{ site.kic_product_name }}. The table below is only relevant for {{ site.gateway_operator_product_name }} versions below 2.0.0.

{% version_compatibility_table %}
product: "{{ site.kic_product_name }}"
versions:
  - 2.11
  - 2.12
  - 3.0
  - 3.1
  - 3.2
  - 3.3
  - 3.4
compatible_product: "{{site.operator_product_name}}"
compatible_versions:
  1.0.x: [2.11, 2.12, 3.0, 3.1, 3.2, 3.3, 3.4]
  1.1.x: [2.11, 2.12, 3.0, 3.1, 3.2, 3.3, 3.4]
  1.2.x: [3.1, 3.2, 3.3, 3.4]
  1.3.x: [3.1, 3.2, 3.3, 3.4]
  1.4.x: [3.1, 3.2, 3.3, 3.4]
  1.5.x: [3.1, 3.2, 3.3, 3.4]
  1.6.x: [3.1, 3.2, 3.3, 3.4]
{% endversion_compatibility_table %}

### General

The following table presents the general compatibility of {{site.operator_product_name}} with specific Kubernetes versions.
Users should expect all the combinations marked with true to work and to be supported.

{% version_compatibility_table %}
product: "Kubernetes"
versions:
  - 1.27
  - 1.28
  - 1.29
  - 1.30
  - 1.31
  - 1.32
  - 1.33
  - 1.34
  - 1.35
compatible_product: "{{site.operator_product_name}}"
compatible_versions:
  2.0.x: [1.28, 1.29, 1.30, 1.31, 1.32, 1.33]
  2.1.x: [1.30, 1.31, 1.32, 1.33, 1.34, 1.35]
{% endversion_compatibility_table %}

### Gateway API

The following table presents the compatibility of {{site.operator_product_name}} with specific [Gateway API][gateway-api] versions.
As {{site.operator_product_name}} implements Gateway API features using the upstream
project, which defines [its own compatibility declarations][gateway-api-supported-versions], the expected compatibility
of Gateway API features might be limited to those.

{% version_compatibility_table %}
product: "Gateway API"
versions:
  - 1.0.0
  - 1.1.0
  - 1.2.0
  - 1.3.0
  - 1.4.0
compatible_product: "{{site.operator_product_name}}"
compatible_versions:
  2.0.x: [1.0.0, 1.1.0, 1.2.0, 1.3.0]
  2.1.x: [1.0.0, 1.1.0, 1.2.0, 1.3.0, 1.4.0]
{% endversion_compatibility_table %}

[gateway-api]: https://github.com/kubernetes-sigs/gateway-api
[gateway-api-supported-versions]:https://gateway-api.sigs.k8s.io/concepts/versioning/#supported-versions

### `kubernetes-configuration` CRDs

{:.info}
> **Note:**
> {{ site.operator_product_name }} 2.0.0+ moved the CRD definitions to its repository.
> With that `kubernetes-configuration` CRDs are not relevant for {{ site.operator_product_name }} 2.0.0+
> and the compatibility table below is only relevant for {{ site.gateway_operator_product_name }} versions below 2.0.0.

Starting with 1.5, {{ site.operator_product_name }} works with [`kubernetes-configuration`][kcfg] CRDs.
These CRDs are backwards compatible with CRDs from gateway-operator 1.4 and older unless stated otherwise in the release notes in [kuberentes-configuration CHANGELOG.md][kcfg_changelog].

Older versions of {{site.operator_product_name}} used `gateway-operator` CRDs, packaged with the operator helm chart.

Below table contains a compatibility matrix for `kubernetes-configuration` CRDs and {{ site.operator_product_name }} versions.

{% version_compatibility_table %}
product: "kubernetes-configuration"
versions:
  - 1.3.x
  - 1.4.x
compatible_product: "{{site.operator_product_name}}"
compatible_versions:
  1.4.x: []
  1.5.x: [1.3.x]
  1.6.x: [1.3.x, 1.4.x]
{% endversion_compatibility_table %}

[kcfg]: https://github.com/Kong/kubernetes-configuration
[kcfg_changelog]: https://github.com/Kong/kubernetes-configuration/blob/main/CHANGELOG.md
