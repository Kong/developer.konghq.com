---
title: kong-harnesses credential
description: Return one short-lived access token, with lazy first login.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `credential` command returns one short-lived OIDC access token for a connection profile, creating the first login when none exists. Coding agents call it automatically to obtain credentials.

## Command usage

{% include_cached kong-harnesses/help/credential/index.md %}
