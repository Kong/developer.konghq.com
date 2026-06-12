---
title: kongctl delete konnect
description: "Delete {{site.konnect_short_name}} tokens."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/delete/

related_resources:
  - text: kongctl delete commands
    url: /kongctl/delete/
---

Delete {{site.konnect_short_name}} tokens.

## Command usage

{% include_cached /kongctl/help/delete/konnect/index.md %}

### kongctl delete konnect organization

Manage {{site.konnect_short_name}} system account resources.

{% include_cached /kongctl/help/delete/konnect/organization.md %}

### kongctl delete konnect pat

Delete a {{site.konnect_short_name}} [personal access token](/konnect-api/#konnect-api-authentication).

{% include_cached /kongctl/help/delete/konnect/pat.md %}

### kongctl delete konnect spat

Delete a {{site.konnect_short_name}} [system account access token](/konnect-api/#konnect-api-authentication).

{% include_cached /kongctl/help/delete/konnect/spat.md %}
