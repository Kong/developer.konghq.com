---
title: "Configure an Azure managed cache for a Dedicated Cloud Gateway control plane"
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-managed-cache-control-plane/
breadcrumbs:
  - /dedicated-cloud-gateways/ 
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure an Azure managed cache for my Dedicated Cloud Gateway control plane group?
  a: |
    After your Dedicated Cloud Gateway Azure network is ready, send a `POST` request to the `/cloud-gateways/add-ons` endpoint to create your Azure managed cache. {{site.konnect_short_name}} will automatically create a Redis partial for you for control plane managed caches. [Use the Redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) in a Redis-backed plugin, specifying the {{site.konnect_short_name}} managed cache as the shared Redis configuration (for example: `konnect-managed-a188516a-b1a6-4fad-9eda-f9b1be1b7159`).
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Partials
    url: /gateway/entities/partial/
min_version:
  gateway: '3.13'
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways
      icon_url: /assets/icons/kogo-white.svg
    
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

{% include_cached /sections/managed-cache-intro.md %}

## Set up an Azure managed cache on a single control plane

{% include_cached /sections/managed-cache-cp-setup.md %}

## Configure Redis for plugins

{% include_cached /sections/managed-cache-cp-plugin-setup.md %}

## Validate

{% include_cached /sections/managed-cache-validate.md %}
