---
title: How to retrieve the bearer token from your external IDP
content_type: support
description: You can retrieve and decode the token just creating a simple service and a route to httbin.org/anything and then enabling the OpenID Connect plugin to that route.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I retrieve and decode the bearer token issued by an external IdP?
  a: |
    Create a service and route to `httpbin.org/anything`, then enable the `openid-connect` plugin on that route. Authenticate through the route in a browser, and the IdP redirects back with the bearer token, which you can copy and decode at jwt.io.
---

## Overview

There may be a situation that I need to inspect or decode the token from the external IDP, for example when using OpenID Connect to authenticate the Dev Portal or Kong Manager. As the token isn't logged, how can I retrieve and decode the token?

## Steps

You can retrieve and decode the token just creating a simple service and a route to httbin.org/anything and then enabling the OpenID Connect plugin to that route.

1. Create a service and a route to httbin.org/anything

   ```bash
   curl -i http://<admin-api-host>:8001/services -H 'Kong-Admin-Token:<rbac-token>' \
   -d 'name=httpbin' \
   -d 'url=http://httpbin.org/'

   curl -i http://<admin-api-host>:8001/services/httpbin/routes -H 'Kong-Admin-Token:<rbac-token>' \
   -d 'name=httpbin' \
   -d 'paths[]=/httpbin'
   ```

2. Enable the OpenID Connect plugin on the route

   ```bash
   curl -i -X POST http://<admin-api-host>:8001/routes/httpbin/plugins -H 'Kong-Admin-Token:<rbac-token>' \
   -d 'name=openid-connect' \
   -d 'config.issuer=https://<issuer-host>/auth/realms/kong/.well-known/openid-configuration' \
   -d 'config.client_id=kong' \
   -d 'config.client_secret=<client-secret>'
   ```

3. Using a web browser, go to the route `http://<kong-proxy-host>:8000/httpbin/anything`. It will redirect to the external IDP. After the authentication, the browser will redirect back to your route and then you can see the bearer token:

4. Now you can copy the bearer token from the Authentication header and go to jwt.io to decode it:
