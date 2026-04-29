---
title: "Configure an AWS managed cache for a Dedicated Cloud Gateway control plane"
content_type: how_to
permalink: /dedicated-cloud-gateways/aws-managed-cache-control-plane/
description: "Learn how to configure an AWS managed cache for a Dedicated Cloud Gateway control plane."
breadcrumbs:
  - /dedicated-cloud-gateways/ 
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure an AWS managed cache for my Dedicated Cloud Gateway control plane?
  a: |
    After your Dedicated Cloud Gateway AWS network is ready, send a `POST` request to the `/cloud-gateways/add-ons` endpoint to create your AWS managed cache. 
    {{site.konnect_short_name}} will automatically create a shared Redis configuration for control plane managed caches. 
    Use the Redis configuration in a [Redis-backed plugin](/gateway/entities/partial/#use-partials), specifying the {{site.konnect_short_name}} managed cache as the shared Redis configuration (for example: `konnect-managed-a188516a-b1a6-4fad-9eda-f9b1be1b7159`).
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Managed cache for Redis
    url: /dedicated-cloud-gateways/managed-cache/
  - text: Partials
    url: /gateway/entities/partial/
  - text: Dedicated Cloud Gateways network architecture
    url: /dedicated-cloud-gateways/network-architecture/
  - text: Dedicated Cloud Gateways private network architecture and security
    url: /dedicated-cloud-gateways/private-network/
  - text: Dedicated Cloud Gateways public network architecture and security
    url: /dedicated-cloud-gateways/public-network/
  - text: Multi-cloud Dedicated Cloud Gateway network architecture and security
    url: /dedicated-cloud-gateways/multi-cloud/
min_version:
  gateway: '3.13'
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways
      icon_url: /assets/icons/kogo-white.svg
faqs:
  - q: |
      {% include faqs/resize-managed-cache.md section='question' %}
    a: |
      {% include faqs/resize-managed-cache.md section='answer' %}    
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---

{% include_cached /sections/managed-cache-intro.md %}

{% include /gateway/managed-cache-recommendation-note.md %}

## Set up an AWS managed cache on a single control plane

{% include_cached /sections/managed-cache-cp-setup.md %}

## Configure Redis for plugins

{% include_cached /sections/managed-cache-cp-plugin-setup.md %}

## Validate

{% include_cached /sections/managed-cache-validate.md %}
