---
title: "Rate Limiting Advanced plugin showing WARN in logs when `sync_rate` set between 0 and 1"
content_type: support
description: "A `sync_rate` between 0 and 1 for the Rate Limiting Advanced plugin logs a WARN because values below 1 second are permitted but not recommended."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does the Rate Limiting Advanced plugin log a WARN when `sync_rate` is set between 0 and 1?"
  a: |
    Values below 1 second are permitted (as low as 0.02s) but not recommended, so Kong logs a WARN.
    A `sync_rate` under 1 second increases load on Kong and the backing Redis instance; only use it if both have sufficient resources.
related_resources:
  - text: "`rate-limiting-advanced`"
    url: /plugins/rate-limiting-advanced/
---

## Rate Limiting Advanced plugin showing WARN in logs when sync_rate set between 0 and 1

When configuring the Rate Limiting Advanced plugin with a `sync_rate` value between 0 and 1 you see WARN messages in the logs like the following:

```
2023/04/19 14:25:09 [warn] 37258#0: *6 [kong] handler.lua:231 Config option 'sync_rate' 0.5 is between 0 and 1; a config update is recommended, context: ngx.timer
```

As per the documentation, the minimum acceptable value for `sync_rate` is 0.02 seconds (20ms), why is this log entry seen?

While you can set this `sync_rate` value as low as 0.02 seconds, to allow for a `window_size` as small as 1 second, the minimum recommended value would be 1 second for the `sync_rate` parameter. Reducing the sync rate below 1 second increases the load on both Kong and the Redis instance backing the rate limit counters, and can lead to Kong being blocked while waiting for a response from Redis. Should you wish to utilize a `sync_rate` below 1 second you will need to ensure that your Kong and Redis instances have sufficient resources available to cope with this additional load.
