---
title: kong-harnesses login
description: Sign in to, repair, or diagnose one profile.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `login` command signs in to one connection profile.
It can also repair a saved sign-in, or run in diagnostics mode to report why a sign-in fails.
When the profile doesn't have a usable sign-in, diagnostics mode tries to sign in, so it can ask to remove the saved sign-in and open the browser.

## Command usage

{% include_cached kong-harnesses/help/login/index.md %}
