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

The `profile` command manages public connection profiles: building them with OIDC discovery, importing them, listing and showing them, activating a client to use one, cleaning up activation settings, and deleting them. See the [profile subcommands](/kong-harnesses/profile/create/) for each command.

## Command usage

{% include_cached kong-harnesses/help/profile/index.md %}
