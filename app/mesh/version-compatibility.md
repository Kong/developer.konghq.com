---
title: "{{site.mesh_product_name}} version compatibility"
description: "Learn about the versions of {{site.mesh_product_name}} compatible with specific versions of Kubernetes and Envoy."
content_type: policy
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - compatibility
works_on:
  - on-prem

related_resources:
  - text: "{{site.mesh_product_name}} version support policy"
    url: /mesh/support-policy/
  - text: "{{site.mesh_product_name}} resource sizing guidelines"
    url: /mesh/resource-sizing-guidelines/
---

{{site.mesh_product_name}} is compatible with different versions of Kubernetes and Envoy.

## Kubernetes

The following table presents the general compatibility of {{site.mesh_product_name}} with specific Kubernetes versions.

{% version_compatibility_table %}
product: "{{site.mesh_product_name}}"
versions:
  - 2.7
  - 2.8
  - 2.9
  - 2.10
  - 2.11
  - 2.12
  - 2.13
compatible_product: Kubernetes
compatible_versions:
  "1.34": [2.13]
  "1.33": [2.13]
  "1.32": [2.11, 2.12, 2.13]
  "1.31": [2.7, 2.9, 2.10, 2.11, 2.12, 2.13]
  "1.30": [2.7, 2.8, 2.9, 2.10, 2.11, 2.12]
  "1.29": [2.7, 2.8, 2.9, 2.10, 2.11, 2.12]
  "1.28": [2.7, 2.8, 2.9, 2.10, 2.11, 2.12]
  "1.27": [2.7, 2.8, 2.9, 2.10, 2.11, 2.12]
  "1.26": [2.7, 2.8, 2.9, 2.10]
  "1.25": [2.7, 2.8, 2.9, 2.10]
  "1.24": [2.7, 2.8]
  "1.23": [2.7, 2.8]
{% endversion_compatibility_table %}

## Envoy

The following table presents the general compatibility of {{site.mesh_product_name}} with specific Envoy versions.
By default, each version of {{site.mesh_product_name}} uses the latest compatible Envoy version, and supports
Envoy versions used in the two previous minor versions of {{site.mesh_product_name}}.

{% version_compatibility_table %}
product: "{{site.mesh_product_name}}"
versions:
  - 2.7
  - 2.8
  - 2.9
  - 2.10
  - 2.11
  - 2.12
  - 2.13
compatible_product: Envoy
compatible_versions:
  "1.36": [2.13]
  "1.35": [2.13, 2.12]
  "1.34": [2.13, 2.12, 2.11]
  "1.33": [2.12, 2.11, 2.10, 2.9, 2.8, 2.7]
  "1.31": [2.10, 2.9, 2.8]
  "1.29": [2.9, 2.8, 2.7]
{% endversion_compatibility_table %}

## Architecture

{{site.mesh_product_name}} supports machines with `x86_64` and `arm64` architecture.