---
title: "Version compatibility"
description: "Understand which versions of {{ site.kic_product_name }}, Kubernetes and the Gateway API {{ site.operator_product_name }} works with"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    section: Reference

---

The following table presents the general compatibility of {{site.kgo_product_name}} with {{ site.kic_product_name }} minor versions.

## Kubernetes

## {{ site.kic_product_name }}

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
compatible_product: "{{site.kgo_product_name}}"
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

The following table presents the general compatibility of {{site.kgo_product_name}} with specific Kubernetes versions.
Users should expect all the combinations marked with true to work and to be supported.

{% version_compatibility_table %}
product: "Kubernetes"
versions:
  - 1.25
  - 1.26
  - 1.27
  - 1.28
  - 1.29
  - 1.30
  - 1.31
  - 1.32
compatible_product: "{{site.kgo_product_name}}"
compatible_versions:
  1.0.x: [1.25, 1.26, 1.27, 1.28, 1.29, 1.30, 1.31, 1.32]
  1.1.x: [1.25, 1.26, 1.27, 1.28, 1.29, 1.30, 1.31, 1.32]
  1.2.x: [1.25, 1.26, 1.27, 1.28, 1.29, 1.30, 1.31, 1.32]
  1.3.x: [1.25, 1.26, 1.27, 1.28, 1.29, 1.30, 1.31, 1.32]
  1.4.x: [1.28, 1.29, 1.30, 1.31, 1.32]
  1.5.x: [1.28, 1.29, 1.30, 1.31, 1.32]
  1.6.x: [1.28, 1.29, 1.30, 1.31, 1.32]
{% endversion_compatibility_table %}

### Gateway API

The following table presents the compatibility of {{site.kgo_product_name}} with specific [Gateway API][gateway-api] versions.
As {{site.kgo_product_name}} implements Gateway API features using the upstream
project, which defines [its own compatibility declarations][gateway-api-supported-versions], the expected compatibility
of Gateway API features might be limited to those.

{% version_compatibility_table %}
product: "Gateway API"
versions:
  - 0.8.1
  - 1.0.0
  - 1.1.0
  - 1.2.0
  - 1.3.0
compatible_product: "{{site.kgo_product_name}}"
compatible_versions:
  1.0.x: [0.8.1, 1.0.0, 1.1.0]
  1.1.x: [0.8.1, 1.0.0, 1.1.0]
  1.2.x: [0.8.1, 1.0.0, 1.1.0]
  1.3.x: [0.8.1, 1.0.0, 1.1.0]
  1.4.x: [0.8.1, 1.0.0, 1.1.0, 1.2.0]
  1.5.x: [0.8.1, 1.0.0, 1.1.0, 1.2.0]
  1.6.x: [0.8.1, 1.0.0, 1.1.0, 1.2.0, 1.3.0]
{% endversion_compatibility_table %}

[gateway-api]: https://github.com/kubernetes-sigs/gateway-api
[gateway-api-supported-versions]:https://gateway-api.sigs.k8s.io/concepts/versioning/#supported-versions

### `kubernetes-configuration` CRDs

Starting with 1.5, {{ site.kgo_product_name }} works with [`kubernetes-configuration`][kcfg] CRDs.
These CRDs are backwards compatible with CRDs from gateway-operator 1.4 and older unless stated otherwise in the release notes in [kuberentes-configuration CHANGELOG.md][kcfg_changelog].

Older versions of {{site.kgo_product_name}} used `gateway-operator` CRDs, packaged with the operator helm chart.

Below table contains a compatibility matrix for `kubernetes-configuration` CRDs and {{ site.kgo_product_name }} versions.

{% version_compatibility_table %}
product: "kubernetes-configuration"
versions:
  - 1.3.x
  - 1.4.x
compatible_product: "{{site.kgo_product_name}}"
compatible_versions:
  1.4.x: []
  1.5.x: [1.3.x]
  1.6.x: [1.3.x, 1.4.x]
{% endversion_compatibility_table %}

[kcfg]: https://github.com/Kong/kubernetes-configuration
[kcfg_changelog]: https://github.com/Kong/kubernetes-configuration/blob/main/CHANGELOG.md
