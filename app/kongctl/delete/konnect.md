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

kongctl provides the following tools for deleting {{site.konnect_short_name}} resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl delete konnect organization](/kongctl/delete/konnect/#kongctl-delete-konnect-organization)
    description: "Manage {{site.konnect_short_name}} system account resources."
  - command: |
      [kongctl delete konnect pat](/kongctl/delete/konnect/#kongctl-delete-konnect-pat)
    description: "Delete a {{site.konnect_short_name}} personal access token."
  - command: |
      [kongctl delete konnect spat](/kongctl/delete/konnect/#kongctl-delete-konnect-spat)
    description: "Delete a {{site.konnect_short_name}} system account access token."
{% endtable %}

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
