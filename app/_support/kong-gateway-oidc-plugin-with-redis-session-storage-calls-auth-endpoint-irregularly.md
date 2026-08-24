---
title: "{{site.base_gateway}}: OIDC plugin with Redis session storage calls auth endpoint irregularly"
content_type: support
description: "Explains why the OIDC plugin's Redis-backed sessions re-authorize earlier than the Access Token TTL, caused by having both `session_idling_timeout` and `session_rolling_timeout` configured together, and how removing `session_idling_timeout` fixes it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the OIDC plugin with Redis session storage call the auth endpoint before the Access Token TTL expires?
  a: |
    Having both `session_idling_timeout` and `session_rolling_timeout` configured together causes premature re-authorization even though the Access Token TTL hasn't expired. Remove `session_idling_timeout` so only the Access Token TTL governs re-authorization.
---

## Problem

We have {{site.base_gateway}} deployed with OIDC (OpenID Connect) auth and we are using Redis as the session storage type. However, we have noticed that the auth endpoint is repeatedly called without the tokens actually expiring. Our Access Token TTL (time to live) is configured for 5 minutes however the auth requests occur every 2~ minutes. Each call to the test endpoint occurs every 30 seconds. How can we prevent this from occurring so frequently?

## Cause

If the Access Token TTL is configured for 5 minutes and its re-authorizing earlier than anticipated then there has to be another configuration in place causing it to re-authorize. The session module's timeout behavior is controlled by three separate settings: `session_idling_timeout` (formerly referred to as "Session Cookie Idletime"), `session_rolling_timeout` (formerly "Session Cookie Lifetime"), and `session_absolute_timeout`, which defaults to 24 hours and caps the overall session lifetime regardless of activity. For example having both `session_idling_timeout` and `session_rolling_timeout` configured will result in this issue.

## Solution

To resolve this, we need to remove the `session_idling_timeout` setting and retest. In this scenario after removing `session_idling_timeout` we can see the Access Token TTL is being utilized. Each request to the test endpoint occurs every 30 seconds. Now after 5 minutes a 401 occurs and a reauthorize is needed as expected.
