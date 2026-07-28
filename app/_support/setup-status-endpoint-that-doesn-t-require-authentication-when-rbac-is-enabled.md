---
title: "Set up a status endpoint that doesn't require authentication when RBAC is enabled"
content_type: support
description: Since the `/status` endpoint is exposed via the Admin API, once RBAC is enabled the request will require a valid RBAC token to get status.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Is there a status endpoint that can be used for healthchecks without requiring an RBAC token when RBAC is enabled?
  a: |
    There's no Admin API endpoint that bypasses RBAC entirely, but you can create a Kong Proxy route that loops back to the Admin API's `/status` endpoint and use the `request-transformer-advanced` plugin to inject a valid `kong-admin-token` header (from an RBAC user with monitor-level access) on the client's behalf — making the endpoint effectively unauthenticated from the client's perspective.
---

## Problem

There is no status endpoint that can be used for healthchecks without authentication once RBAC is enabled on the Admin API.

## Cause

Since the `/status` endpoint is exposed via the Admin API, once RBAC is enabled the request will require a valid RBAC token to get status. There is no Admin API endpoint that is always unauthenticated.

## Solution

That being said, we can use the Kong Proxy to proxy this request to the Admin API so that we can provide an 'unauthenticated' status endpoint from the clients perspective.

Here are the steps to configure a loopback route to the Admin API that will inject the required rbac token header. I used httpie in the example Admin API request:

1. Create an rbac user with `monitor` level access, or skip these steps and use an existing RBAC user/token with appropriate permissions:

   ```bash
   http http://kong-admin-api:8001/rbac/roles name=readOnlyStatus kong-admin-token:<token>

   http http://kong-admin-api:8001/rbac/roles/readOnlyStatus/endpoints endpoint=/status actions=read kong-admin-token:<token> -f

   http http://kong-admin-api:8001/rbac/users name=monitor  user_token=token kong-admin-token:<token>

   http http://kong-admin-api:8001/rbac/users/monitor/roles roles=readOnlyStatus kong-admin-token:<token> -f
   ```

2. Create a Kong service that loops back to your Admin API `/status` endpoint

   ```bash
   http http://kong-admin-api:8001/services name=status url=http://localhost:8001/status kong-admin-token:<token>
   ```

3. Add a route to expose the `/status` path on your Kong Proxy

   ```bash
   http http://kong-admin-api:8001/services/status/routes name=status paths=/status kong-admin-token:<token> -f
   ```

4. Add the request transformer plugin to inject the RBAC `kong-admin-token` header for all requests to the `/status` endpoint. This should be the token you defined in step 1 when creating your rbac user or an existing rbac token that has enough permissions to access the `/status` endpoint.

   ```bash
   http http://kong-admin-api:8001/routes/status/plugins name=request-transformer-advanced config.add.headers=kong-admin-token:token kong-admin-token:<token> -f
   ```

5. Finally, confirm that you can access the `/status` endpoint that is now exposed via the Kong Proxy.

   ```bash
   http GET http://kong-proxy:8000/status
   ```
