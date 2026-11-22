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
A release with no changes for users, such as one with only build or documentation changes, is not listed.
A release that had a release candidate, such as `0.18.0-rc.1`, lists only the changes after that candidate, so also read the release candidate sections of the same version.

If a release needs a step when you upgrade, that release lists the step under **⚠ BREAKING CHANGES**.
Do these steps after you install the new release, before you use it.

A release can also change what `setup`, `profile activate` and `relay activate` write to a client's settings.
The settings stay as the earlier release wrote them until you activate the profile again.
`kong-harnesses status` reports these settings as `Set up by an earlier release or profile` and names `profile activate`, the command that applies the change.
For a profile that you imported with `relay import`, `kong-harnesses relay status` reports them and names `relay activate`.

If your organization's managed settings set up Claude Code, `status` doesn't name a command for such a change.
The administrator runs `fleet build` again into a new or empty output folder, with every flag of the earlier build that they keep, the record and the MDM policy or managed settings that the computers have now, and, for a build with `--mcp-servers exclusive`, the `managed-mcp.json` that the computers have now with `--mcp-config`.
Then the administrator delivers the new build, as [Keep a Claude Code fleet on tested versions](/kong-harnesses/maintain-a-claude-code-fleet/) describes.
The release lists that step under **⚠ BREAKING CHANGES**.

{{ site.data.kong-harnesses.changelog.markdown }}
