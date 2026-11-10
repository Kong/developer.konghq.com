---
title: kong-harnesses profile activate
description: Configure one or every detected agent CLI to use one profile.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/profile/
---

The `profile activate` command configures one agent CLI, or every agent CLI detected on this machine, to use one connection profile. It ends by running the `doctor` checks for the profile and printing the findings that are not ok.

## Command usage

{% include_cached kong-harnesses/help/profile/activate.md %}
