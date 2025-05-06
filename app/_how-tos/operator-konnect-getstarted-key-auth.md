---
title: Key Authentication
description: Secure an API using the `key-auth` plugin and credentials from a `KongConsumer`.
content_type: how_to
permalink: /operator/konnect/get-started/key-authentication/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: kgo-get-started
  position: 6

tldr:
  q: How do I secure an API with key authentication using {{site.konnect_short_name}} CRDs?
  a: |
    Apply the `key-auth` plugin to a route and attach credentials using the `KongConsumer` and `KongCredentialAPIKey` CRDs.

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
@todo