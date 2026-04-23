---
title: kongctl get event-gateway tls-trust-bundles
description: "Use the tls-trust-bundles command to list or retrieve TLS trust bundles for a specific {{site.event_gateway_short}}."
content_type: reference
layout: reference

beta: true
works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/
  - /kongctl/get/event-gateway/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
---

Use the `tls-trust-bundles` command to list or retrieve TLS trust bundles for a specific {{site.event_gateway_short}}.

TLS trust bundles define trusted certificate authorities used for mTLS client certificate verification and are referenced by TLS listener policies.

## Command usage

{% include_cached /kongctl/help/get/event-gateway/tls-trust-bundles.md %}
