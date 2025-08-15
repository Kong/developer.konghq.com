---
title: decK version support policy

description: The decK version support policy outlines the decK versioning scheme and version lifecycle.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck
tags: 
  - support-policy
search_aliases:
  - decK support policy
breadcrumbs:
  - /deck/

related_resources:
  - text: Tools for managing {{ site.base_gateway }} and {{ site.konnect_short_name }}
    url: /tools/
---

## {{site.konnect_short_name}}

decK is an officially supported way to configure {{ site.konnect_short_name }} deployments.

**The minimum version required to configure Konnect is decK v1.40.0**.

The {{ site.konnect_short_name }} API returns the most recent {{ site.base_gateway }} API response. If you are experiencing issues with decK and {{ site.konnect_short_name }}, update decK to the latest available version.

## Self-managed {{site.base_gateway}}

decK guarantees compatibility with all supported {{ site.base_gateway }} versions.

Changes to {{ site.base_gateway }} may result in changes to decK. We recommend updating decK regularly, as the most recent version will work with both old versions of {{ site.base_gateway }} _and_ the latest version simultaneously.
