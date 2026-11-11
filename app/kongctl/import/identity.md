---
title: kongctl import identity
description: "Import Kong Identity resources."
content_type: reference
layout: reference


works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/import/

related_resources:
  - text: kongctl import commands
    url: /kongctl/import/
  - text: kongctl adopt identity
    url: /kongctl/adopt/identity/
  - text: kongctl get identity
    url: /kongctl/get/identity/
  - text: kongctl inspect identity
    url: /kongctl/inspect/identity/
  - text: kongctl list identity
    url: /kongctl/list/identity/
---

Import Kong Identity resources.

kongctl provides the following tools for importing Kong Identity data:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl import identity org-chart](/kongctl/import/identity/#kongctl-import-identity-org-chart)
    description: "Upload a complete organization-chart CSV and privately capture its report."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/import/identity/index.md %}

### kongctl import identity org-chart

Upload a complete organization-chart CSV and privately capture its report.

{% include_cached /kongctl/help/import/identity/org-chart.md %}
