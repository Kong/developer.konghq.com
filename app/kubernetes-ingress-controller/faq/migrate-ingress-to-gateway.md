---
title: Migrating from Ingress to Gateway API

description: |
  Which custom Ingress annotations are replaced with Gateway API features?

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
---

Kong contributed to the kubernetes-sigs project [`ingress2gateway`](https://github.com/kubernetes-sigs/ingress2gateway) by creating a Kong provider able to convert ingress resources into Gateway resources. The `ingress2Gateway` tool provides a `print` command that gets ingress resources and displays the Gateway API equivalent. The output of this operation can be either directly applied to the cluster, or it can generate a new set of YAML files containing the converted configuration.

## Supported Ingress features and annotations

{{ site.kic_product_name }} provides an extensive set of [annotations](/kubernetes-ingress-controller/reference/annotations). The `ingress2gateway` {{ site.base_gateway }} provider currently supports the following annotations:

{% table %}
columns:
- title: Annotation name
  key: annotation
- title: Conversion
  key: conversion

rows:
- annotation: |
    `kubernetes.io/ingress.class`
    <br>
    _required_
  conversion: "`gateway.spec.gatewayClassName`"

- annotation: "`konghq.com/methods`"
  conversion: "`httpRoute.spec.rules[*].matches[*].method`"

- annotation: "`konghq.com/headers._`"
  conversion: "`httpRoute.spec.rules[_].matches[*].headers`"

- annotation: "`konghq.com/plugins`"
  conversion: "`httpRoute.spec.rules[*].filters`"
{% endtable %}

## Features

### kubernetes.io/ingress.class

_[Annotation description](/kubernetes-ingress-controller/reference/annotations/#kubernetes-io-ingress-class)_

If configured on an Ingress resource, this value is used as the `gatewayClassName` set on the corresponding generated Gateway.

### konghq.com/methods

_[Annotation description](/kubernetes-ingress-controller/reference/annotations/#konghq-com-methods)_

If configured on an Ingress resource, this value is used to set the `HTTPRoute` method matching configuration. Since many methods can be set as a comma-separated list, each method creates a match copy. All the matches belonging to the same `HTTPRoute` rule are put in OR.

### konghq.com/headers.\*

_[Annotation description](/kubernetes-ingress-controller/reference/annotations/#konghq-com-headers)_

If configured on an Ingress resource, this value sets the `HTTPRoute` header matching configuration. Only exact matching is supported. Because many values can be set for the same header name as a comma-separated list, each header value is used to create a match copy. All the matches belonging to the same `HTTPRoute` rule are put in OR.

### konghq.com/plugins

> [Annotation description](/kubernetes-ingress-controller/reference/annotations/#konghq-com-plugins)

_[Annotation description](/kubernetes-ingress-controller/reference/annotations/#konghq-com-plugins)_

If configured on an Ingress resource, this value attaches plugins to Routes. Plugin references are converted into `HTTPRoute` `ExtensionRef` filters.  Each plugin annotation is converted into a {{ site.base_gateway }} Plugin instance.

Each value in the annotation must match the name of a [`KongPlugin`](/kubernetes-ingress-controller/reference/custom-resources/#kongplugin) or [`KongClusterPlugin`](/kubernetes-ingress-controller/reference/custom-resources/#kongclusterplugin).