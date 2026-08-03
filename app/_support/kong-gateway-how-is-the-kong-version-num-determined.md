---
title: "How Kong Gateway's `kong.version_num` value is determined"
content_type: support
published: false
description: "Kong Gateway's `kong.version_num` PDK value encodes `major.minor.patch` as a single semantic-versioning-based integer (e.g., `3.14.0.0` -> `30014000`)."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "`kong.version_num` PDK reference"
    url: "/gateway/pdk/reference/#kong-version-num"
tldr:
  q: How is `kong.version_num` determined?
  a: |
    `kong.version_num` encodes Kong's `major.minor.patch` version as a single integer following semantic versioning, e.g. `3.10.0.0` -> `30010000` and `3.14.0.0` -> `30014000`.
---

## Problem

When implementing checks against the Kong version number using the PDK function `kong.version_num`, it's not clear what format to use for newer releases like 3.10 and 3.14+.

## Solution

Kong primarily follows semantic versioning. The format of this number is constructed as follows:

```
major.minor.patch

major * 100
minor * 10
patch
```

For example:

```
3.10.0.0 = 30010000
3.14.0.0 = 30014000
```
