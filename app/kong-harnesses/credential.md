---
title: agent-auth-cli credential
description: Return one short-lived access token, with lazy first login.

content_type: reference
layout: reference

tools:
  - agent-auth-cli

breadcrumbs:
  - /agent-auth-cli/
---

The `credential` command returns one short-lived OIDC access token for a connection profile, creating the first login when none exists. Coding agents call it automatically to obtain credentials.

## Command usage

{% include_cached agent-auth-cli/help/credential/index.md %}
