---
title: how to get id token and access token used for Kong Manager or Dev Portal login
content_type: support
description: "Configure `downstream_id_token_header` and `downstream_access_token_header` in the OpenID Connect config, then inspect the browser's network tab to find the id token and access token used for Kong Manager or Dev Portal login."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I find the id token and access token used for Kong Manager or Dev Portal OpenID Connect login?
  a: |
    Add `downstream_id_token_header` and `downstream_access_token_header` to your `admin_gui_auth_conf`/`KONG_ADMIN_GUI_AUTH_CONF` (Kong Manager) or `portal_auth_conf`/`KONG_PORTAL_AUTH_CONF` (classic Dev Portal), restart Kong, then log in and inspect the `id-token` and `access-token` response headers in your browser's network tab. Note: the classic Dev Portal is hard-deprecated and license-gated on current {{site.ee_product_name}}, so the Dev Portal steps are likely non-functional for most current customers.
---

## Overview

I am using openid-connect to login Kong Manager and Dev Portal, but I am encountering a login issue. How could I check what is the id token and access token used in the login procedure?

## Steps

1. For the case you are using openid-connect to login Kong Manager

   1. Please add below 2 parameters to `admin_gui_auth_conf` or `KONG_ADMIN_GUI_AUTH_CONF`

      ```json
      "downstream_id_token_header": "id-token"
      "downstream_access_token_header": "access-token"
      ```

   2. Restart Kong

   3. Login Kong Manager by using Chrome

      Keep opening the "Network" tab of "Developer Tools" in this procedure,

      Find below API and check its response header.

      ```
      http(s)://<kong>:<kong-admin-api-port>/auth?state=xxx&session_state=yyy&code=zzz
      ```

      Then we will find the id-token response header shows the id token,

      the access-token response header shows the access token.

2. For the case you are using openid-connect to login Dev Portal

   Note: the classic Dev Portal is hard-deprecated and license-gated on current {{site.ee_product_name}}, so this section is very likely non-functional for most current customers. The Kong Manager steps above remain fully valid.

   1. Please add below 2 parameters to `portal_auth_conf` or `KONG_PORTAL_AUTH_CONF`

      ```json
      "downstream_id_token_header": "id-token"
      "downstream_access_token_header": "access-token"
      ```

   2. Restart Kong

   3. Login Dev Portal by using Chrome

      Keep opening the "Network" tab of "Developer Tools" in this procedure,

      Find below API and check its response header.

      ```
      http(s)://<kong>:<dev-portal-api-port>/<workspace>/session
      ```

      Then we will find the id-token response header shows the id token,

      the access-token response header shows the access token.
