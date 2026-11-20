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

This page lists the changes for users in recent {{site.kong_harnesses}} releases, newest first. A release with no changes for users, such as one with only build or documentation changes, is not listed. A release that had a release candidate, such as `0.18.0-rc.1`, lists only the changes after that candidate, so also read the release candidate sections of the same version.

If a release needs a step when you upgrade, that release lists the step under **⚠ BREAKING CHANGES**. Do these steps after you install the new release, before you use it.

A release can also change what `setup`, `profile activate` and `relay activate` write to a client's settings. The settings stay as the earlier release wrote them until you activate the profile again. `kong-harnesses status` reports these settings as `Set up by an earlier release or profile` and names `profile activate`, the command that applies the change. For a profile that you imported with `relay import`, `kong-harnesses relay status` reports them and names `relay activate`.

If your organization's managed settings set up Claude Code, `status` names no command for such a change. The administrator builds the managed settings again with `fleet build`, with the choices of the earlier build, and delivers the new build, and the release lists that step under **⚠ BREAKING CHANGES**.

{{ site.data.kong-harnesses.changelog.markdown }}
