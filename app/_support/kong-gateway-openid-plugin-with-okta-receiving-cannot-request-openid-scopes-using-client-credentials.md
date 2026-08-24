---
title: "Kong Gateway: OpenID plugin with Okta receiving \"Cannot request 'openid' scopes using client credentials.\""
content_type: support
description: "Some IDPs, such as Okta, don't allow the `openid` scope with the `client_credentials` grant type, causing the OpenID Connect plugin to return an `invalid_scope` error. Fix it by creating a custom scope in the IDP and updating the plugin's scopes to use it instead of `openid`."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the OpenID Connect plugin return "Cannot request 'openid' scopes using client credentials" with Okta?
  a: |
    Some IDPs, including Okta, don't allow the `openid` scope with the `client_credentials` grant type, so the OpenID Connect plugin returns an `invalid_scope` error and the request gets an Unauthorized response. Create a custom scope in the IDP and update the plugin's scopes configuration to use that scope instead of `openid`.
---

## Problem

When setting up Client Credentials inside {{site.base_gateway}}'s OpenID Connect plugin we are receiving the following debug statement:

```

[debug] 2149#0: *3771675 [lua] debug.lua:28: debug(): {"error":"invalid_scope","error_description":"Cannot request 'openid' scopes using client credentials."}
```

Our curl command results in:

```

{"message":"Unauthorized"}
```

Our IDP is Okta in this test case and we can confirm that Authorization flow works as expected so we know the connectivity is successful.

## Solution

The issue here is that the scope `openid` is not applicable when using the grant type `Client_Credentials`. Some IDPs may not allow `openid` as a scope in this scenario resulting in the error above.

The way around this is to create a custom scope inside Okta and update the OpenID Connect plugin to reflect this change as well.

The default scope configured on the OpenID Connect plugin for `Config.Scopes` is `openid`. For this, we should update the plugin to accommodate the custom scope that was created.

Once done, we can retest and now should be able to receive 200s.

Sample Command:

```bash

curl --request POST \
  --url http://localhost:8000/test \
  --header 'accept: application/json' \
  --header 'authorization: Basic <clientid:clientsecret>' \
  --header 'cache-control: no-cache' \
  --header 'content-type: application/x-www-form-urlencoded' \
  --data 'grant_type=client_credentials&scope=testScope'
```
