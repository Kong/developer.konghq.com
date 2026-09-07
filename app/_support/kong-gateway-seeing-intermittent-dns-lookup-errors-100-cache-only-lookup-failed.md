---
title: "Kong Gateway: Seeing intermittent DNS lookup errors: \"100 cache only lookup failed\""
content_type: support
description: Intermittent "100 cache only lookup failed" DNS errors occur when a retried request's cached DNS record expires before the retry completes, and can be mitigated by tuning `dns_stale_ttl` or `dns_valid_ttl`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why do I see intermittent DNS lookup errors like `"100 cache only lookup failed"` in Kong Gateway?
  a: |
    This happens when a retried request's cached DNS entry expires before the retry completes — retries only check the existing cache and don't issue a fresh DNS query. Fix the underlying slow upstream or timeout causing the retries where possible, and consider raising `dns_stale_ttl` (defaults to `3600` seconds on current Kong Gateway) or `dns_valid_ttl` to reduce exposure to this race.
---

## Problem

We are intermittently seeing requests failing while being retried by the Kong Gateway. We see these types of errors in the logs:

```

upstream timed out (110: Operation timed out) while connecting to upstream
init.lua:393: execute(): DNS resolution failed: dns server error: 100 cache only lookup failed.
```

or

```

[error] 2159#0: *112214 [lua] init.lua:1064: balancer(): failed to retry the dns/balancer resolver for {hostname}' with: dns server error: 100 cache only lookup failed while connecting to upstream
```

## Cause

This behavior can be seen in a few circumstances, most often when there is low traffic volume and a service request is retried during the period where the relevant DNS record TTL has expired.

Retried requests will not initiate a new DNS query to the DNS servers; they will only do a lookup from the existing cache during the retry phase. If the DNS record TTL coincidentally expired in the time the request was being retried, then this will result in the "100 cache only lookup failed" errors since the DNS record was purged from cache during the time this request was being retried.

This is much more likely in an environment where there are few requests flowing through the Kong Gateway however can occur in high-traffic environments too if the DNS TTL is very low.

## Solution

Ideally the solution to such a scenario would be to prevent the requests from needing to be retried in the first place, as new requests would refresh the DNS cache and avoid this situation. This means looking at why the upstream is not responding quickly enough to where one of the timeout values are being hit which triggers the retry phase. This can be the upstream server/endpoint or even the network portion upstream from the Kong Gateway. This is the ultimate root cause and must be investigated. However there are also a few situations where we can help minimize the impact by setting relevant DNS properties in the Kong Gateway.

Recommended actions when the DNS "100 cache only lookup failed" errors are seen in the logs:

1. Determine why the timeout values are being hit in the first place and resolve the upstream issues with a slow backend/network. You can also temporarily work around this by modifying the timeout values as needed to compensate for a slow backend. Ideally though you want the connection timeout to still be a low value to "fail fast" as to not negatively impact further traffic.
2. Look into setting the `dns_stale_ttl` property in your Kong Gateway to allow Kong to keep the DNS entry in cache for a period of time past its TTL. **Update for Kong Gateway 3.14.0.0:** the default value of this setting is no longer 4 seconds — confirmed both in source (`kong_defaults.lua`) and live via the Admin API root response (`configuration.dns_stale_ttl`) — it now defaults to `3600` (1 hour). This means the specific failure mode described in this article (a retried request losing its cached DNS entry to TTL expiry) is considerably less likely to occur out of the box today than it was on older Kong Gateway versions with the old 4-second default, since Kong now tolerates an expired DNS record for up to an hour by default before it's actually evicted from cache. If you are still seeing this error on 3.14.0.0 with default settings, or if you've explicitly lowered `dns_stale_ttl`, raising it further (to a value comfortably larger than your realistic worst-case retry/timeout window) remains the correct fix — just be aware you may already be at a much more generous default than older documentation assumes. Be sure to test any change to this value in a test environment first to understand the potential impact to the environment.
3. If the DNS TTLs set by the DNS servers are very low (~30-60 seconds or less) and if their DNS records cannot be changed, there may be a benefit to overriding the DNS TTL to a higher value by setting the `dns_valid_ttl` property. Be sure to test these values in a test environment first to understand the potential impact to the environment.
