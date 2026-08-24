---
title: "Kong Gateway: OIDC plugin - Troubleshooting High Redis Memory Usage"
content_type: support
description: "Explains why Redis memory usage grows unbounded when the OIDC plugin's bearer and session auth methods create redundant sessions, and how to fix it by tuning `session_rolling_timeout` and disabling sessions for bearer authentication."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Redis memory usage keep growing when the OIDC plugin has auth code, bearer, and session auth methods enabled together?
  a: |
    Redundant sessions created by validation requests are the primary cause. Reduce `session_rolling_timeout` to limit how long sessions stay active, and disable sessions for bearer authentication (either by dropping `session` from `auth_methods`, or more surgically by setting `config.disable_session` for the methods that don't need it) to stop the unbounded memory growth.
---

## Problem

I have "auth code", "bearer" and "session" auth methods enabled in the openid-connect plugin, the redis instance backing session storage for the OIDC experienced increasing memory usage until it could not operate. What could be the reasons causing this issue?

## Cause

This was primarily due to redundant sessions being created by validation requests.

## Solution

To mitigate this issue, the following steps were taken by modifying the OIDC plugin settings:

1. Adjust the `session_rolling_timeout` parameter.

   Initially, adjusting the `session_rolling_timeout` parameter to a smaller value was recommended to help manage the session lifetime and potentially reduce memory usage. This parameter dictates the duration a session remains active, and reducing its value can help in limiting the number of active sessions stored in Redis. The default value for this setting is 3600 seconds.

   ```
   session_rolling_timeout = 300 # Sets the timeout to 300 seconds (5 minutes)
   ```

2. Disable sessions for bearer authentication.

   The root cause of the memory issue was identified as redundant sessions created by validation requests. By disabling `session` in `auth_methods`, sessions for bearer token authentication were disabled, effectively eliminating the unbounded memory growth. This solution is particularly useful if sessions are not required for bearer token authentication in your implementation.

   ```
   auth_methods = ["bearer"]
   ```

   A more surgical alternative to fully removing `session` from `auth_methods` is to set `config.disable_session` for the auth methods that don't need it (e.g. `disable_session = ["bearer"]`). This stops the redundant session cookie from being created for those methods while leaving `session` available in `auth_methods` for the methods that do need it.

3. Disable the `session_store_metadata` setting if it is enabled and not required.

   ```
   session_store_metadata = false
   ```

It's important to consider the potential consequences of disabling sessions for bearer authentication. Disabling sessions could lead to a loss of session-based functionality if any part of the system relies on session data (e.g., user preferences, shopping carts). Additionally, relying solely on the bearer token for authorization increases the risk if the bearer token is compromised, as an attacker could potentially use it to impersonate the authorized user until the token expires.

These steps were effective in addressing the issue of increasing memory usage in Redis due to session storage with the OIDC plugin. By adjusting `session_rolling_timeout` and disabling sessions for bearer authentication, the unbounded memory growth was eliminated, allowing the system to operate efficiently.
