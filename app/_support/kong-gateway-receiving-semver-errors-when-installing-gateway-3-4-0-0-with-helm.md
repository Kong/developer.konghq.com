---
title: "\"Invalid Semantic Version\" SemVer error when installing or upgrading Kong Gateway with Helm using an invalid `image.tag` value"
content_type: support
description: "Explains the Helm SemVer validation error (`Invalid Semantic Version`) that occurs when the chart's `image.tag` value doesn't match the required version format for Enterprise or open source {{site.base_gateway}} images."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why do I get a SemVer validation error (`Invalid Semantic Version`) when installing or upgrading Kong Gateway with Helm?
  a: |
    The Helm chart validates the `image.tag` value in your values file against Kong's version format — `X.X.X.X` for Enterprise, `X.X.X` for open source. Any `image.tag` outside that format triggers the SemVer error; this isn't specific to any one Gateway version. Set `image.tag` to a correctly formatted version to resolve it.
---

## Problem

When we attempt to install/upgrade {{site.base_gateway}} with an invalid SemVer image tag, we see a SemVer validation error similar to the following:

```

Error: template: kong/templates/deployment.yaml:273:3: executing "kong/templates/deployment.yaml" at <include "kong.proxy.compatibleReadiness" .>: error calling include: template: kong/templates/_helpers.tpl:1637:12: executing "kong.proxy.compatibleReadiness" at <semverCompare "< 3.3.0" (include "kong.effectiveVersion" .Values.image)>: error calling semverCompare: Invalid Semantic Version
```

This is not specific to {{site.base_gateway}} 3.4.0.0 — it occurs with any invalid-SemVer `image.tag` value on any current chart version. Note that on current chart versions (e.g. 3.4.1) the failure now typically surfaces much earlier in the template rendering, from the `kong.metaLabels` helper's bare `semver` call (invoked by nearly every templated resource, including the proxy Service) rather than from `kong.proxy.compatibleReadiness`'s `semverCompare` call — so the exact template path, line numbers, and even which Sprig function (`semver` vs `semverCompare`) is named in the error you see may differ from the example above, though the root cause (an `image.tag` that fails Helm's SemVer parsing, reported as `Invalid Semantic Version`) is the same.

## Cause

Our helm chart performs several versioning checks against the provided `image.tag` in your values file. Those checks require the following version formats:

Enterprise Kong: `X.X.X.X`

Open Source Kong: `X.X.X`

If your `image.tag` field has anything outside of the above formatting, you will receive the above error.

## Solution

Working example:

```yaml
image:
  repository: kong/kong-gateway
  tag: 3.4.0.0
```

Broken example:

```yaml
image:
  repository: kong/kong-gateway
  tag: randomletters
```
