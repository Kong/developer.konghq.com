---
title: kongctl create organization
description: "Manage {{site.konnect_short_name}} system accounts."
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
  - text: kongctl adopt organization
    url: /kongctl/adopt/organization/
  - text: kongctl delete organization
    url: /kongctl/delete/organization/
  - text: kongctl get organization
    url: /kongctl/get/organization/
  - text: kongctl list organization
    url: /kongctl/list/organization/
---

kongctl provides tools for managing {{site.konnect_short_name}} organization resources.

## Command usage

{% include_cached /kongctl/help/create/organization/index.md %}

### kongctl create organization system-account

Create {{site.konnect_short_name}} [system accounts](/konnect-api/#konnect-api-authentication).

{% include_cached /kongctl/help/create/organization/system-account.md %}
