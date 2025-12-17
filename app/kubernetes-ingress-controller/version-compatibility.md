---
title: Version compatibility

description: |
  Learn about the versions of {{ site.kic_product_name }} compatible with specific versions of {{ site.base_gateway }}, Kubernetes, Gateway API and Istio.

content_type: reference
layout: reference
breadcrumbs: 
  - /kubernetes-ingress-controller/
products:
  - kic

works_on:
  - on-prem
  - konnect
related_resources:
  - text: "{{ site.kic_product_name }} support policy"
    url: /kubernetes-ingress-controller/support/
  - text: "{{site.base_gateway}} version support"
    url: /gateway/version-support-policy/
  - text: "{{site.konnect_short_name}} compatibility"
    url: /konnect-platform/compatibility/
    
tags:
  - compatibility

faqs:
  - q: Why is my KIC instance read-only in {{site.konnect_short_name}}?
    a: |
      Because Kubernetes resources are the source of truth for configuring {{ site.base_gateway }} in Kubernetes, the KIC instance configuration in {{site.konnect_short_name}} is marked as read-only. This prevents configuration drift in {{ site.base_gateway }} caused by changes made outside the Ingress or Kubernetes Gateway API.

      For example, if a Route is created via the Kubernetes Gateway API and then modified in {{site.base_gateway}}, those changes wouldn't be reflected in the CRD and would conflict with the desired state defined in the CRD.
---


{{ site.kic_product_name }} is compatible with different versions of {{ site.base_gateway }}, Kubernetes, and Istio.

## {{ site.base_gateway }}

The following table shows the compatibility of {{ site.kic_product_name }} with {{ site.base_gateway }} versions:

{% version_compatibility_table %}
product: "{{ site.kic_product_name }}"
versions:
  - 2.12
  - 3.0
  - 3.1
  - 3.2
  - 3.3
  - 3.4
  - 3.5
compatible_product: "{{ site.base_gateway }}"
compatible_versions:
  2.8.x: [2.12]
  3.4.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.5.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.6.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.7.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.8.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.9.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.10.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.11.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  3.12.x: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
{% endversion_compatibility_table %}

## Kubernetes

{{site.kic_product_name}} compatibility with Kubernetes depends on Kubernetes and Gateway API versions.

### General

The following table presents the general compatibility of {{site.kic_product_name}} with specific Kubernetes versions.

{% version_compatibility_table %}
product: "{{ site.kic_product_name }}"
versions:
  - 2.12
  - 3.0
  - 3.1
  - 3.2
  - 3.3
  - 3.4
  - 3.5
compatible_product: Kubernetes
compatible_versions:
  "1.34": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  "1.33": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  "1.32": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  "1.31": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  "1.30": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  "1.29": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  "1.28": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  "1.27": [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
{% endversion_compatibility_table %}

### Gateway API

The following table presents the compatibility of {{site.kic_product_name}}'s [Gateway API](https://github.com/kubernetes-sigs/gateway-api) with specific Kubernetes minor versions. As {{site.kic_product_name}} implements Gateway API features using the upstream project, which defines [its own compatibility declarations](https://gateway-api.sigs.k8s.io/concepts/versioning/#supported-versions), the expected compatibility of Gateway API features might be limited to those.

{% version_compatibility_table %}
product: "{{ site.kic_product_name }}"
versions:
  - 2.12
  - 3.0
  - 3.1
  - 3.2
  - 3.3
  - 3.4
  - 3.5
compatible_product: Gateway API
compatible_versions:
  1.3: [3.5]
  1.2: [3.4, 3.5]
  1.1: [3.2, 3.3, 3.4, 3.5]
  1.0: [3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  0.8: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4]
{% endversion_compatibility_table %}

For specific Gateway API resources support, see the [Gateway API](/kubernetes-ingress-controller/gateway-api/) page.

## Istio

The {{site.kic_product_name}} can be integrated with an [Istio Service Mesh](https://istio.io) to use {{site.base_gateway}} as an ingress gateway for application traffic into the mesh network.

We run tests for each {{site.kic_product_name}} release to verify this documentation with upcoming versions of KIC and Istio. The following table lists the tested combinations:

{% version_compatibility_table %}
product: "{{ site.kic_product_name }}"
versions:
  - 2.12
  - 3.0
  - 3.1
  - 3.2
  - 3.3
  - 3.4
  - 3.5
compatible_product: Istio
compatible_versions:
  1.26: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  1.25: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  1.24: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  1.23: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  1.22: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
  1.21: [2.12, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
{% endversion_compatibility_table %}