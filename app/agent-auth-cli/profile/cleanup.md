---
title: agent-auth-cli profile cleanup
description: Remove settings still owned by agent-auth-cli.

content_type: reference
layout: reference

tools:
  - agent-auth-cli

breadcrumbs:
  - /agent-auth-cli/
  - /agent-auth-cli/profile/
---

The `profile cleanup` command removes the settings values that agent-auth-cli still owns in a supported client. Without a `--client` selector it reverses everything the tool owns in every supported client.

## Command usage

{% include_cached agent-auth-cli/help/profile/cleanup.md %}
