---
title: agent-auth-cli doctor
description: Check one profile end to end and report each fix beside each finding.

content_type: reference
layout: reference

tools:
  - agent-auth-cli

breadcrumbs:
  - /agent-auth-cli/
---

The `doctor` command checks one profile end to end: the profile, the sign-in, the client, and both endpoints. It reaches the network, reports each finding beside its fix, and can write the report as JSON.

## Command usage

{% include_cached agent-auth-cli/help/doctor/index.md %}
