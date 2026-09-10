---
title: "Setup status endpoint that doesn't require authentication when RBAC is enabled"
content_type: support
description: "{{site.base_gateway}}'s built-in `status_listen` endpoint (port 8100 by default) provides unauthenticated health checks even when RBAC is enabled; expose the Admin API's `/status` endpoint through the proxy only if you specifically need it there."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Is there a status endpoint that can be used for healthchecks without requiring authentication when RBAC is enabled?
  a: |
    Yes — {{site.base_gateway}}'s native `status_listen` endpoint (port 8100 by default) is always unauthenticated and unaffected by RBAC, so use `http://<node>:8100/status` directly for healthchecks. If you need the status information exposed through the Kong Proxy itself instead, add a loopback route to the Admin API's `/status` endpoint with a `request-transformer-advanced` plugin that injects an RBAC `kong-admin-token`.
---

## Problem

Is there a status endpoint that can be used for healthchecks that doesn't require authentication when I have enabled RBAC?

## Solution

Since the `/status` endpoint is exposed via the Admin API, once RBAC is enabled the request will require a valid RBAC token to get status. However, {{site.base_gateway}} also has a separate, native status endpoint (`status_listen`, on port 8100 by default) that is always unauthenticated and requires zero additional configuration — it is unaffected by RBAC because it's not part of the Admin API. For healthchecks, prefer hitting `http://<node>:8100/status` directly; this works out of the box on both Control Planes and Data Planes.

If you specifically need the unauthenticated status information exposed through the Kong Proxy itself (rather than a direct connection to port 8100), the loopback recipe below can be used instead. Note this recipe only works on standalone nodes — in hybrid mode, Data Planes have no Admin API listener at all, so the loopback route will 502 there.

Here are the steps to configure a loopback route to the Admin API that will inject the required RBAC token header. I used `httpie` in the example Admin API request:

1. Create an RBAC user with `monitor` level access, or skip these steps and use an existing RBAC user/token with appropriate permissions:

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

4. Add the request transformer plugin to inject the RBAC `kong-admin-token` header for all requests to the `/status` endpoint. This should be the token you defined in step 1 when creating your RBAC user or an existing RBAC token that has enough permissions to access the `/status` endpoint.

   ```bash

   http http://kong-admin-api:8001/routes/status/plugins name=request-transformer-advanced config.add.headers=kong-admin-token:token kong-admin-token:<token> -f
   ```

5. Finally, confirm that you can access the `/status` endpoint that is now exposed via the Kong Proxy.

   ```bash

   http GET http://kong-proxy:8000/status
   ```
