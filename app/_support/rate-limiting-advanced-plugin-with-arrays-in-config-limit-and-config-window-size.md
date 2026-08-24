---
title: Rate Limiting Advanced plugin with arrays in `config.limit` and `config.window_size`
content_type: support
description: When using an Array in the `Config.Limit` and `Config.Window_size` it will cycle through the first limit condition inside the first window size.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Reference
    url: /plugins/rate-limiting-advanced/#multiple-limits-and-window-sizes
tldr:
  q: How does the rate limiting advanced plugin behave when `config.limit` and `config.window_size` are set to arrays?
  a: |
    Kong tracks a separate counter for each `config.limit` / `config.window_size` pair and enforces all of them at once. Under the default `sliding` window type, per-request behavior isn't deterministic; set `config.window_type` to `fixed` for clock-aligned counting, though window-boundary alignment still affects the exact results.
---

## Problem

It's not clear how the rate limiting advanced plugin behaves when `Config.Limit` and `Config.Window_size` are configured as arrays, for example `Config.Limit` = 2, 5 and `Config.Window_size` = 10, 60.

## Solution

When using an array in `config.limit` and `config.window_size`, the plugin tracks a separate counter for each (limit, window_size) pair and enforces all of them at the same time. Whether the request-by-request behavior is as deterministic as described below depends on `config.window_type`, which the plugin defaults to `sliding` and which this KB previously did not mention at all.

- Under the default `sliding` window type, the plugin evaluates a continuously moving window rather than fixed, clock-aligned buckets, so the walkthrough below does not hold as written.
- Under `window_type: fixed`, counters reset at fixed, clock-aligned boundaries, so the walkthrough below is representative, but it is still dependent on how your request timing aligns with the window boundaries — starting mid-window can let you send more or fewer requests than expected before hitting the limit.

For example, with `config.limit` = [2, 5] and `config.window_size` = [10, 60] under `window_type: fixed`, and assuming requests start aligned to a window boundary:

Every 10 seconds you can send 2 transactions. The 3rd prior to the 10 second window will fail. I can do this until I hit 5 transactions every 60 seconds.

1) Send 2 transactions. Hit limit. Wait 10 seconds.
2) Send 2 transactions. Hit limit again. Wait 10 seconds.
3) Send 1 transaction. Hit limit. Wait 60 seconds.

At this point we have hit the second limit in the second window size.

*Important Note* There must be a matching number of `config.limit` and `config.window_size` entries specified. If you need this kind of deterministic, clock-aligned counting, set `config.window_type` to `fixed` explicitly — the default `sliding` window type will not behave this way.
