---
title: kong-harnesses profile default
description: Choose the profile that commands use when you do not give --profile.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/profile/
---

The `profile default` command chooses the profile that other commands use when no `--profile` flag is given. Until you choose one, the default is the first profile in `profile list`. Changing the default changes no agent CLI settings, because each agent CLI names its own profile.

## Command usage

{% include_cached kong-harnesses/help/profile/default.md %}
