---
title: kong-harnesses profile
description: Manage connection profiles and the agent CLIs that use them.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `profile` command manages public connection profiles: building them with OIDC discovery, importing them, listing and showing them, activating a client to use one, cleaning up activation settings, and deleting them.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kong-harnesses profile create](/kong-harnesses/profile/create/)
    description: "Create a profile from your identity provider's details."
  - command: |
      [kong-harnesses profile import](/kong-harnesses/profile/import/)
    description: "Install a profile from a file or HTTPS URL."
  - command: |
      [kong-harnesses profile list](/kong-harnesses/profile/list/)
    description: "List installed profiles."
  - command: |
      [kong-harnesses profile get](/kong-harnesses/profile/get/)
    description: "Show the settings of an installed profile."
  - command: |
      [kong-harnesses profile default](/kong-harnesses/profile/default/)
    description: "Choose the profile that commands use when you do not give --profile."
  - command: |
      [kong-harnesses profile activate](/kong-harnesses/profile/activate/)
    description: "Set up the installed agent CLIs to use a profile."
  - command: |
      [kong-harnesses profile cleanup](/kong-harnesses/profile/cleanup/)
    description: "Remove the settings that kong-harnesses added."
  - command: |
      [kong-harnesses profile delete](/kong-harnesses/profile/delete/)
    description: "Delete an installed profile from this computer."
{% endtable %}

## Command usage

{% include_cached kong-harnesses/help/profile/index.md %}
