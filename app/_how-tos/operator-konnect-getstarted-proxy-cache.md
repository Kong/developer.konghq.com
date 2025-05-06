---
title: Enable Proxy Caching
description: Use the `KongPlugin` CRD to configure proxy caching for a route or service.
content_type: how_to
permalink: /operator/konnect/get-started/proxy-caching/
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
  q: How do I enable response caching with {{site.konnect_short_name}} CRDs?
  a: |
    Apply the `proxy-cache` plugin using the `KongPlugin` CRD.

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

@TODO