---
title: Apply Rate Limiting
description: Add rate limiting policies to a service or route using the `KongPlugin` CRD.
content_type: how_to
permalink: /operator/konnect/get-started/rate-limiting/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: kgo-get-started
  position: 5

tldr:
  q: How do I configure rate limiting with {{site.konnect_short_name}} CRDs?
  a: |
    Use the `KongPlugin` resource to attach the `rate-limiting` plugin to a service or route.

products:
  - operator

works_on:
  - konnect

entities: []

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## About rate limiting

Rate limiting is used to control the rate of requests sent to an upstream service. It can be used to prevent DoS attacks, limit web scraping, and other forms of overuse. Without rate limiting, clients have unlimited access to your upstream services, which may negatively impact availability.

{{site.base_gateway}} imposes rate limits on clients through the [Rate Limiting plugin](/plugins/rate-limiting/). When rate limiting is enabled, clients are restricted in the number of requests that can be made in a configurable period of time. The plugin supports identifying clients as consumers based on authentication or by the client IP address of the requests.

{:.info}
> This tutorial uses the [Rate Limiting](/plugins/rate-limiting/) plugin. The [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin is also available. The advanced version provides additional features such as support for the sliding window algorithm and advanced Redis support for greater performance.

## Create a new `KongPlugin`

The `KongPlugin` resource lets you configure and attach plugins like `rate-limiting` to services or routes in {{site.konnect_short_name}}.

The following example enables rate limiting on a route with the following settings:

- 5 requests per minute
- Shared across consumers (no per-consumer limits)

<!-- vale off -->
{% konnect_crd %}
apiVersion: configuration.konghq.com/v1alpha1
kind: KongPlugin
metadata:
  name: rate-limiting
  namespace: kong
spec:
  name: rate-limiting
  config:
    minute: 5
    policy: local
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongPlugin
name: rate-limiting
{% endvalidation %}
<!-- vale on -->

After the plugin is applied, try sending more than 5 requests in a single minute to `echo-route`. You should begin receiving `429 Too Many Requests` responses once the limit is exceeded.
