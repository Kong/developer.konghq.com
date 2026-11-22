---
title: kong-harnesses profile cleanup
description: Remove settings still owned by kong-harnesses.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/profile/
---

The `profile cleanup` command removes the settings values that kong-harnesses still owns in a supported client. Without a `--client` selector it reverses everything the tool owns in every supported client.
To also sign out, delete a profile, or uninstall kong-harnesses, see [Remove kong-harnesses](/kong-harnesses/remove-kong-harnesses/).

## Command usage

{% include_cached kong-harnesses/help/profile/cleanup.md %}
