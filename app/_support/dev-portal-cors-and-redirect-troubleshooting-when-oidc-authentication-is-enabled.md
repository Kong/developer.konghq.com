---
title: Dev Portal CORS and continuous redirect troubleshooting when OIDC authentication is enabled
content_type: support
description: A CORS error in the Dev Portal browser console can be benign, appearing during a routine session check against the IdP before any login is attempted, but it can also point to the portal API failing to save its session.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why do I see CORS errors or redirect loops in the Dev Portal when OIDC authentication is enabled?
  a: |
    A CORS error in the browser console can be benign — the GUI does a session check against the IdP and the portal API, so it can appear before any developer has attempted to log in.

    If login or registration genuinely isn't working, the portal API is usually failing to save its session, for one of these reasons:

    - `consumer_claim` points to the wrong claim name in the access/ID token.
    - The developer hasn't been approved in Kong Manager yet.
    - Cookies/headers shared between the portal GUI, IdP, and portal API exceed Kong's default buffer size.
    - `authorization_cookie_path` and/or `session_cookie_path` aren't set correctly when the portal is proxied on a non-root path.
    - `redirect_uri` in the OIDC config doesn't point to the portal API.
    - A workspace isn't present in all of the OIDC config's `redirect_uri` values.
---

## Problem

When configuring OIDC authentication with the on-prem Dev Portal, it is common to see the following error occur in the dev tools console in the browser:

```
Access to XMLHttpRequest at 'https://mytrial.okta.com/oauth2/default/v1/authorize?code_...' (redirected from 'https://kong-dev-portal-api-address.com/api/default/session') from origin 'https://kong-dev-portal-ui.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

Additionally, the browser can return with too many redirects, indicating that the portal API and the IdP `/authorize` endpoints are redirecting repeatedly to each other until the browser intervenes.

## Cause

The CORS error can be benign and appear even when login and authentication are working, as the GUI will do a session check against the IdP and the portal API, therefore it can occur before any developer has actually attempted login yet.

However if login or registration is not working and these behaviors can be seen, then it is likely that the inability to save the sessions is to blame. This can occur for a range of reasons, and the common ones are listed below:

## Solution

1. **Consumer claim cannot be found.**

   While the IdP authentication is successful, the `portal-api` error logs indicate that the consumer cannot be found in the Access or ID tokens.

   This can be due to the `consumer_claim` value pointing to the wrong claim name in the access/ID tokens.

   If the consumer claim is not known, then the ID/Access tokens can be retrieved and added to the request headers via these two config options:

   - `downstream_id_token_header`
   - `downstream_access_token_header`

   By putting names in these fields, the ID and access tokens will be added to the requests between the browser and the portal API/IdP and can then be analyzed for the base64 encoded token values. Those JWT tokens can then be analyzed with JWT.io to reveal which claim the consumer's username or email is in.

   Example of the `x-id-token` header set to show the ID token using Chrome dev tools to inspect the requests:

2. **A new consumer is found and identified in the token as per the `portal-api` error logs, but login still fails.**

   This can be a symptom of the developer not being approved in Kong Manager.

   Dev Portal developer sign-ups have a secondary requirement that the developer needs approving by a Kong Manager admin.

   Ensure the developer is approved and allowed to log in.

3. **Headers are too large to be processed by Kong.**

   If the `portal-api` and `portal-gui` are proxied through Kong itself via ingress or routing rules, the cookies shared between the `portal-gui` and the IdP/`portal-api` can be too big for Kong's default configuration.

   The Kong proxy error log will indicate that headers are too big and need adjusting accordingly.

   As a starting point, use the following buffer settings to allow larger 16k headers than the default 4k:

   ```conf
   nginx_proxy_proxy_buffers: 8 16k
   nginx_proxy_proxy_buffer_size: 16k
   nginx_proxy_proxy_busy_buffers_size: 112k
   ```

4. **Cookie paths are set incorrectly.**

   The authorization code flow has two different sessions that need to be saved:

   - The authorization session between the browser and the `portal-api`.
   - The portal session, which is used between the browser and the `portal-gui`.

   By default, both sessions are stored with a path of `/`, however when either the `portal-gui` or `portal-api` are accessed through a proxy with a non-root path (`/`), then `authorization_cookie_path` and/or `session_cookie_path` will need adjusting in the OIDC config, for the browser to send the cookie to the correct backend.

5. **Redirect URI is not pointing to the portal-api.**

   Ensure that the `redirect_uri` parameter in the OIDC config is pointing to the correct address/port/path of the `portal-api`, not the `portal-gui`.

6. **Ensure the workspace is present in all `redirect_uri` values in the OIDC config.**

   ```json
   "forbidden_redirect_uri": [ "https://portal.local.docker:8446/default/unauthorized" ],
   "login_redirect_uri": [ "https://portal.local.docker:8446/default" ],
   "logout_redirect_uri": [ "https://portal.local.docker:8446/default" ],
   "redirect_uri": [ "https://portal-api.local.docker:8447/default/auth" ]
   ```
