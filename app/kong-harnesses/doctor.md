---
title: kong-harnesses doctor
description: Check one profile end to end and report each fix beside each finding.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `doctor` command checks one profile end to end: the profile, the sign-in, the client, and both endpoints. It reaches the network, reports each finding beside its fix, and can write the report as JSON.

## Command usage

{% include_cached kong-harnesses/help/doctor/index.md %}
