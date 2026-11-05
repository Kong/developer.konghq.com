---
title: agent-auth-cli setup
description: Import one profile, sign in, and configure the client, in one run.

content_type: reference
layout: reference

tools:
  - agent-auth-cli

breadcrumbs:
  - /agent-auth-cli/
---

The `setup` command imports one profile, signs in, and configures the client, in one run. It is safe to run again: an unchanged source is not re-imported, a usable sign-in is left alone, and a configured client is left unchanged. It stops at the first step that fails, and running the same command again resumes there.

## Command usage

{% include_cached agent-auth-cli/help/setup/index.md %}
