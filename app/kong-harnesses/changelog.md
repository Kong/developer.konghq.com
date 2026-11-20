---
title: "{{site.kong_harnesses}} changelog"
description: "What changed in each {{site.kong_harnesses}} release, and the steps an upgrade needs."
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

This page lists the changes in each {{site.kong_harnesses}} release, newest first.

If a release needs a step when you upgrade, that release lists the step under **⚠ BREAKING CHANGES**. Do these steps after you install the new release, before you use it.

A release can also change what `setup` and `profile activate` write to a client's settings. The settings stay as the earlier release wrote them until you activate the profile again. `kong-harnesses status` reports these settings as `Set up by an earlier release or profile` and names the `profile activate` command that applies the change.

{% include_cached kong-harnesses/changelog.md %}
