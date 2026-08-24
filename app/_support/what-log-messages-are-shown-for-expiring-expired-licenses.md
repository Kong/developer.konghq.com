---
title: Log messages shown for expiring and expired Kong Enterprise licenses
content_type: support
description: Kong logs warning, error, and two levels of critical messages as an Enterprise license approaches and passes its expiration date, so you can configure alerts in an external log tool.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What log messages are shown for expiring/expired licenses?
  a: |
    Kong logs a warning when an Enterprise license is within 90 days of expiring, an error within 30 days, and critical messages during and after the 30-day post-expiration grace period. Every message includes the expiration date except the grace-period one, which reports days remaining instead. The license status is also available from the `/` Admin API endpoint (`.license` in the JSON response) for external alerting.
related_resources: []
---

## Problem

When a Kong license has either expired, or is about to expire, Kong logs specific messages that can be used to configure alerts in an external log tool to prevent problems with expired licenses.

## Solution

There are four different levels of messages that are logged depending on the license validity and the current date:

1. When the license is going to expire within the next 90 days (`expiration_time < now + 90`) a Warning message is logged:

   ```
   2025/02/01 09:00:00 [warn] 45527#0: *9 [lua] license_helpers.lua:332: log_license_state(): The Kong Enterprise license will expire on 2025-05-02. Please contact <support@konghq.com> to renew your license., context: ngx.timer
   ```

2. When the license is going to expire within the next 30 days (`expiration_time < now + 30`) an Error message is logged:

   ```
   2025/04/02 09:00:00 [error] 45527#0: *9 [lua] license_helpers.lua:328: log_license_state(): The Kong Enterprise license will expire on 2025-05-02. Please contact <support@konghq.com> to renew your license., context: ngx.timer
   ```

3. When the license has expired, but is still within a 30-day post-expiration grace period, a Critical grace-period message is logged, and it does NOT repeat the "expired on X" wording — it instead reports the number of days left in the grace period:

   ```
   2025/05/15 09:00:00 [crit] 45527#0: *9 [lua] license_helpers.lua:317: log_license_state(): Your license is expired. You have 17 days left in the renewal grace period. Please contact <support@konghq.com> to renew your license., context: ngx.timer
   ```

4. Once the grace period has elapsed (`expiration_time < now`, grace period over) a Critical message is logged:

   ```
   2025/06/15 09:00:00 [crit] 45527#0: *9 [lua] license_helpers.lua:322: log_license_state(): The Kong Enterprise license expired on 2025-05-02. Please contact <support@konghq.com> to renew your license., context: ngx.timer
   ```

While the actual message logged will vary according to the specific expiry date, the " Please contact <support@konghq.com> to renew your license" message is constant between all messages.

It is also possible to retrieve the license expiration from the `/` endpoint if you wish to setup customized alerting (the `/kong` endpoint no longer exists):

```bash

curl -s -X GET 'https://api.kong.lan:8444/' | jq '.license'
{
  "admin_seats": "5",
  "customer": "KongInc",
  "dataplanes": "5",
  "license_creation_date": "2024-05-02",
  "license_expiration_date": "2025-05-02",
  "product_subscription": "Kong Enterprise Edition",
  "support_plan": "Pro"
}
```
