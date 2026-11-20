---
title: "{{site.kong_harnesses}} changelog"
description: "What changed in recent {{site.kong_harnesses}} releases, and the steps an upgrade needs."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - changelog
  - cli

search_aliases:
  - release notes
  - upgrade

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: "{{site.kong_harnesses}}"
    url: /kong-harnesses/
  - text: Release notes for all Kong products and tools
    url: /changelogs/
---

This page lists the changes for users in recent {{site.kong_harnesses}} releases, newest first.

If a release needs a step when you upgrade, that release lists the step under **⚠ BREAKING CHANGES**. Do these steps after you install the new release, before you use it.

A release can also change what `setup`, `profile activate` and `relay activate` write to a client's settings. The settings stay as the earlier release wrote them until you activate the profile again. `kong-harnesses status` reports these settings as `Set up by an earlier release or profile` and names the command that applies the change: `profile activate`, or `relay activate` for a profile that you imported with `relay import`.

{{ site.data.kong-harnesses.changelog.markdown }}
