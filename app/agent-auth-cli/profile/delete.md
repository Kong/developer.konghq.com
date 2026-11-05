---
title: agent-auth-cli profile delete
description: Remove one installed connection profile from this computer.

content_type: reference
layout: reference

tools:
  - agent-auth-cli

breadcrumbs:
  - /agent-auth-cli/
  - /agent-auth-cli/profile/
---

The `profile delete` command removes one installed connection profile from this computer. It removes the stored profile document only, and refuses while a sign-in or a client configuration still refers to the profile.

## Command usage

{% include_cached agent-auth-cli/help/profile/delete.md %}
