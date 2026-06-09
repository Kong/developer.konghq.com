---
title: kongctl get event-gateway
description: "Use the get verb with the event-gateway command to query {{site.konnect_short_name}} {{site.event_gateway_short}}s."
content_type: reference
layout: reference


works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
---

Use the `get` verb with the `event-gateway` command to query {{site.konnect_short_name}} {{site.event_gateway_short}}s.

kongctl provides the following tools for retrieving resources and resource details for {{site.event_gateway_short}}:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get event-gateway backend-clusters](/kongctl/get/event-gateway/#kongctl-get-event-gateway-backend-clusters)
    description: "Use the `backend-clusters` command to list or retrieve backend clusters for a specific {{site.event_gateway_short}}."
  - command: |
      [kongctl get event-gateway data-plane-certificates](/kongctl/get/event-gateway/#kongctl-get-event-gateway-data-plane-certificates)
    description: "Use the `data-plane-certificates` command to list or retrieve data plane certificates for a specific {{site.event_gateway_short}}."
  - command: |
      [kongctl get event-gateway listener-policies](/kongctl/get/event-gateway/#kongctl-get-event-gateway-listener-policies)
    description: "Use the `listener-policies` command to list or retrieve listener policies for a specific {{site.event_gateway_short}} Listener."
  - command: |
      [kongctl get event-gateway listeners](/kongctl/get/event-gateway/#kongctl-get-event-gateway-listeners)
    description: "Use the `listeners` command to list or retrieve listeners for a specific {{site.event_gateway_short}}."
  - command: |
      [kongctl get event-gateway schema-registries](/kongctl/get/event-gateway/#kongctl-get-event-gateway-schema-registries)
    description: "Use the `schema-registries` command to list or retrieve schema registries for a specific {{site.event_gateway_short}}."
  - command: |
      [kongctl get event-gateway static-keys](/kongctl/get/event-gateway/#kongctl-get-event-gateway-static-keys)
    description: "Use the `static-keys` command to list or retrieve static keys for a specific {{site.event_gateway_short}}."
  - command: |
      [kongctl get event-gateway tls-trust-bundles](/kongctl/get/event-gateway/#kongctl-get-event-gateway-tls-trust-bundles)
    description: "Use the `tls-trust-bundles` command to list or retrieve TLS trust bundles for a specific {{site.event_gateway_short}}."
  - command: |
      [kongctl get event-gateway virtual-clusters](/kongctl/get/event-gateway/#kongctl-get-event-gateway-virtual-clusters)
    description: "Use the `virtual-clusters` command to list or retrieve virtual clusters for a specific {{site.event_gateway_short}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/event-gateway/index.md %}

### kongctl get event-gateway backend-clusters

Use the `backend-clusters` command to list or retrieve backend clusters for a specific {{site.event_gateway_short}}.

{% include_cached /kongctl/help/get/event-gateway/backend-clusters.md %}

### kongctl get event-gateway data-plane-certificates

Use the `data-plane-certificates` command to list or retrieve data plane certificates for a specific {{site.event_gateway_short}}.

{% include_cached /kongctl/help/get/event-gateway/data-plane-certificates.md %}

### kongctl get event-gateway listener-policies

Use the `listener-policies` command to list or retrieve listener policies for a specific {{site.event_gateway_short}} Listener.

{% include_cached /kongctl/help/get/event-gateway/listener-policies.md %}

### kongctl get event-gateway listeners

Use the `listeners` command to list or retrieve listeners for a specific {{site.event_gateway_short}}.

{% include_cached /kongctl/help/get/event-gateway/listeners.md %}

### kongctl get event-gateway schema-registries

Use the `schema-registries` command to list or retrieve schema registries for a specific {{site.event_gateway_short}}.

{% include_cached /kongctl/help/get/event-gateway/schema-registries.md %}

### kongctl get event-gateway static-keys

Use the `static-keys` command to list or retrieve static keys for a specific {{site.event_gateway_short}}.

{% include_cached /kongctl/help/get/event-gateway/static-keys.md %}

### kongctl get event-gateway tls-trust-bundles

Use the `tls-trust-bundles` command to list or retrieve TLS trust bundles for a specific {{site.event_gateway_short}}.

TLS trust bundles define trusted certificate authorities used for mTLS client certificate verification and are referenced by TLS listener policies.

{% include_cached /kongctl/help/get/event-gateway/tls-trust-bundles.md %}

### kongctl get event-gateway virtual-clusters

Use the `virtual-clusters` command to list or retrieve virtual clusters for a specific {{site.event_gateway_short}}.

{% include_cached /kongctl/help/get/event-gateway/virtual-clusters.md %}
