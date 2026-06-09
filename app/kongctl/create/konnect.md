---
title: kongctl create konnect
description: "Create {{site.konnect_short_name}} access tokens"
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/create/

related_resources:
  - text: kongctl create commands
    url: /kongctl/create/
---

kongctl provides for creating {{site.konnect_short_name}} access tokens.

## Command usage

{% include_cached /kongctl/help/create/konnect/index.md %}

### kongctl create konnect organization

Manage {{site.konnect_short_name}} system account resources.

{% include_cached /kongctl/help/create/konnect/organization.md %}

### kongctl create konnect pat

Create a {{site.konnect_short_name}} [personal access token](/konnect-api/#konnect-api-authentication).

{% include_cached /kongctl/help/create/konnect/pat.md %}

### kongctl create konnect spat

Create a {{site.konnect_short_name}} [system account access token](/konnect-api/#konnect-api-authentication).

{% include_cached /kongctl/help/create/konnect/spat.md %}
