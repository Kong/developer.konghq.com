---
title: KIC and Konnect

description: |
  Why is my KIC instance read only in Konnect?

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: FAQs

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect

---

{{ site.kic_product_name }} provides an interface to configure {{ site.base_gateway }} entities using Kubernetes Custom Resource Definitions (CRDs).

As Kubernetes resources are considered the "source of truth" for configuring the {{ site.base_gateway }} in Kubernetes, when viewing the KIC instance in Konnect its configuration is marked as read-only.  

This reduces the chances that two different people or teams change the Gateway configuration as this would cause configuration drift from the Ingress or Kubernetes Gateway API.  

For example, if a Route is created in the Kubernetes Gateway API, and is then modified in the {{site.base_gateway}}, the Gateway changes would not be reflected in the CRD, and would go against the desired state defined in the CRD.

