---
title: 'HTTP status 409 "UNIQUE violation detected" error when upgrading KIC directly from 1.x to 2.1+'
content_type: support
description: "There are drastic changes on KIC that won't allow you to upgrade directly from KIC 1.x to 2.1+."
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Reference
    url: /kubernetes-ingress-controller/faq/upgrading-ingress-controller/
  - text: the KIC CHANGELOG
    url: https://github.com/Kong/kubernetes-ingress-controller/blob/main/CHANGELOG.md
tldr:
  q: 'Why do we get an HTTP status 409 "UNIQUE violation detected" error when upgrading KIC directly from 1.x to 2.1+?'
  a: |
    KIC has breaking changes starting at 2.0 that block a direct upgrade from 1.x to 2.1+, causing `HTTP status 409` "UNIQUE violation detected" errors during upgrade. Avoid this by upgrading through an intermediate version (for example 1.x to 2.0 to 2.x) instead of skipping directly across the major version boundary.
---

## Problem

We are upgrading from KIC 1.x directly to 2.5 and are running into the following error:

```

time="2026-09-07T14:19:13Z" level=error msg="could not update kong admin" error="1 errors occurred:\n\twhile processing event: {Create} route test.route failed: HTTP status 409 (message: \"UNIQUE violation detected on '{name=\\\"test.route\\\"}'\")\n" subsystem=dataplane-synchronize
time="2026-09-07T14:27:28Z" level=warning msg="exceeded Kong API timeout, consider increasing --proxy-timeout-seconds"
```

How can we prevent this from occurring on our systems?

## Cause

There are drastic changes on KIC that won't allow you to upgrade directly from KIC 1.x to 2.1+. This is due to the breaking changes implemented on KIC 2.0+.

## Solution

To avoid these errors we recommend upgrading to an intermediate version first.

Procedure:

```

Initial version 1.x > Upgrade to 2.0.
Next upgrade from 2.0 > 2.x
```

This guidance is scoped to the historical KIC 1.x-to-2.x upgrade specifically; current KIC releases are well past the 2.x line (see the changelog for the full, current breaking-changes history), but the general principle — never skip directly across a major KIC version boundary, upgrade through each intermediate major version instead — remains current guidance for any deployment several major versions behind.

Note: the KIC CHANGELOG's own GitHub-generated `#breaking-changes-N` anchors are not stable long-term — as new "Breaking changes" sections are added to the top of the changelog over time, the anchor numbering shifts and can silently point at an unrelated, newer release's breaking changes instead of the one originally intended. Link to a named upgrade guide (as above) rather than a numbered changelog anchor where possible.
