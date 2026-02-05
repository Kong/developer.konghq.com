---
title: Configure the Admin API with {{ site.base_gateway }} on Kubernetes
short_title: Configure the Admin API
description: Expose the {{ site.base_gateway }} Admin API through an Ingress Controller
content_type: how_to
permalink: /gateway/install/kubernetes/on-prem/admin/
breadcrumbs:
  - /gateway/
  - /gateway/install/

series:
  id: gateway-k8s-on-prem-install
  position: 2

products:
  - gateway

works_on:
  - on-prem

entities: []

tldr: null

prereqs:
  skip_product: true

automated_tests: false
---

{{ site.base_gateway }} is now running on Kubernetes. The Admin API is a `NodePort` service, which means it's not publicly available. The proxy service is a `LoadBalancer` which provides a public address.

To make the admin API accessible without using `kubectl port-forward`, you can create an internal load balancer on your chosen cloud. This is required to use [Kong Manager]({{ page.navigation.next.url }}) to view or edit your configuration.

{% include k8s/helm-ingress-setup.md service="admin" release="cp" type="private" %}
