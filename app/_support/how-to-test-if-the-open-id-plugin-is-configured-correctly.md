---
title: How to test if the open-id plugin is configured correctly
content_type: support
description: Test that Kong's `openid-connect` plugin is configured correctly by configuring the plugin, requesting a token from the identity provider, and using it as a bearer token against a protected route.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Azure AD IdP configuration for the OpenID Connect plugin
    url: /gateway/kong-plugins/authentication/oidc/azure-ad/#azure-ad-idp-configuration
tldr:
  q: How do I test if the OpenID Connect plugin is configured correctly?
  a: |
    Configure the `openid-connect` plugin on a route, request an access token from the identity
    provider using the client credentials grant, and call the protected route with the token as a
    Bearer credential to confirm the plugin accepts it.
---

## Overview

We have set up the OpenID-Connect plugin to authenticate against Microsoft Azure ID, but after looking through your docs, we are unsure if the plugin is configured correctly.

## Steps

The simplest way to deploy and test the open-id connect plugin would be:

1. Configure the open-id plugin. The following command has been used to configure the plugin at route level:

   ```bash
   curl -i -X POST http://<kong-admin-hostname>:8001/routes/{route-id}/plugins --data name="openid-connect" \
     --data config.issuer="https://login.microsoftonline.com/{tenant-id}/v2.0" \
     --data config.client_id="{client-id}" \
     --data config.client_secret="{secret}" \
     --data config.scopes="openid" \
     --data config.scopes="email" \
     --data config.scopes="profile" \
     --data config.scopes="{client-id}/.default" \
     --data config.verify_parameters="false" \
     --header 'Kong-Admin-Token: {password}'
   ```

2. Request a token:

   ```bash
   curl -X POST https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token \
     --data scope="{client-id}/.default" \
     --data grant_type="client_credentials" \
     --data client_id="{client-id}" \
     --data client_secret="{secret}"
   ```

3. Consume the service. Copy the `access_token` value and consume your service using it as a Bearer token:

   ```bash
   curl --header 'Authorization: bearer <token_from_above>' '<admin-hostname>:8000/<route>'
   ```
