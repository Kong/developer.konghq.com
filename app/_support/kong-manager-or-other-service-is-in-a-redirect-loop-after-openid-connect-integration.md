---
title: Kong Manager or other Service is in a redirect loop after OpenID Connect integration
content_type: support
description: There are a number of possible causes for this behavior where a redirect loop is seen when using the OpenID-Connect (OIDC) plugin for authentication.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong Manager (or another service) get stuck in a redirect loop after integrating with the OpenID Connect plugin?
  a: |
    A post-OIDC redirect loop usually has one of three causes: the `SameSite` cookie attribute set to `Strict` instead of `Lax`, a missing or incorrect `redirect_uri`, or an unreachable Redis server used for session storage. Set `cookie_samesite=Lax`, confirm `redirect_uri` matches the environment, and verify Redis connectivity to resolve it.
---

## Problem

I configured Kong Manager for access via the OpenID Connect plugin, however now Kong Manager logins result in a redirect loop. Why is this loop happening and how do we resolve it? My web browser terminates after around a dozen redirects, declaring that there were too many redirects or stating that `This webpage has a redirect loop`, and Chrome errors out with a `ERR_TOO_MANY_REDIRECTS` message.

## Solution

There are a number of possible causes for this behavior where a redirect loop is seen when using the OpenID-Connect (OIDC) plugin for authentication. The three most popular are below for reference:

1. `SameSite` cookie attribute is set to `Strict` when it may need to be `Lax` for the environment.
2. The `redirect_uri` variable is either missing or incorrectly set to the wrong endpoint.
3. Redis server used for session storage is inaccessible

For situation #1 above with the `SameSite` cookie attribute, this may need to set this to `Lax` to see it work again in the environment. We recommend customers familiarize themselves with the `SameSite` attribute and then when ready to make the change it can be done by setting `cookie_samesite=Lax` as referenced in the Kong OIDC plugin documentation.

For situation #2 above with the `redirect_uri` variable, it must be set according to the needs of the environment. If it's missing or hitting the wrong endpoint, it may not behave as expected and can cause the redirect loop. Admins should ensure the `redirect_uri` is set correctly based upon the environmental requirements.

For situation #3 above with redis servers used for session storage, ensure that your redis configuration in the OIDC plugin is set correctly. This includes the correct hostname, port number, and more. If a port is misconfigured for example, an error will start `Failed to connect to redis-cluster port 9000`. If a hostname is misconfigured, an error should be logged of `Could not resolve host: redis-cluster`. A good test is to run `curl <redis_host>:<port>` in a command line from the {{site.base_gateway}} container as well to verify connectivity. If the server responds correctly, you should see `Empty reply from server` in the curl response output.
