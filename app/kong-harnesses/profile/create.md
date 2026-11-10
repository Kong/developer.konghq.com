---
title: kong-harnesses profile create
description: Build and install a connection profile using OIDC discovery.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/profile/
---

The `profile create` command builds and installs a connection profile using OIDC discovery. Run it without flags to start the interactive three-step setup, or pass the issuer, client, gateway, and audience explicitly.

## Command usage

{% include_cached kong-harnesses/help/profile/create.md %}
