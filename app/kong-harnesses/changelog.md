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

This page lists the changes for users in each {{site.kong_harnesses}} release, newest first.
A release with only build or documentation changes isn't listed.

If you must do something when you upgrade, the release lists the step under **⚠ BREAKING CHANGES**.
Do the step after you install the new release and before you use it.

A release that had a release candidate, such as `0.18.0-rc.1`, lists only the changes since that candidate.
To see every change in the release, also read the sections of its release candidates.

A release can also change the client settings that `setup`, `profile activate` and `relay activate` write.
Your current settings don't change until you activate the profile again.
To apply the new settings:

* Run `kong-harnesses status`.
  If a client shows `Set up by an earlier release or profile`, run the `profile activate` command that the `Next` line names.
* For a profile that you imported with `relay import`, run `kong-harnesses relay status`, then run the `relay activate` command that it names.

If your organization's managed settings set up {{site.claude_code}}, `status` doesn't name a command.
In this case, the release lists a step for your administrator under **⚠ BREAKING CHANGES**.
The administrator makes a new fleet build and delivers it, as described in [Keep a {{site.claude_code}} fleet on tested versions](/kong-harnesses/maintain-a-claude-code-fleet/).

{{ site.data.kong-harnesses.changelog.markdown }}
