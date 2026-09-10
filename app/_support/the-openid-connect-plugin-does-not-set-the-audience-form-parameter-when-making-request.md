---
title: The `openid-connect` plugin does not set the `audience` form parameter with `client_credentials` auth method
content_type: support
description: Setting the `config.audience` parameter in the `openid-connect` configuration options does NOT cause the plugin to add the required form parameter.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why doesn't the `openid-connect` plugin send the `audience` form parameter with the `client_credentials` auth method?
  a: |
    Setting `config.audience` alone does not add the parameter to the token request. Configure `config.token_post_args_names` and `config.token_post_args_values` to explicitly send `audience` (the same fields appear as Config.Token Post Args Names / Config.Token Post Args Values in Kong Manager).
---

## Problem

I am trying to configure the `client_credentials` authentication method with the `openid-connect` plugin. My IdP (for example Auth0) requires that an `audience` form parameter is being sent when using the `client_credentials` authentication method so I have configured the `config.audience` parameter in the plugin configuration.

However, authentication still fails with the following error suggesting that the parameter is not being sent:

```

{“error”:”access_denied”,”error_description”:”Non-global clients are not allowed access to APIv1"}
```

## Solution

Setting the `config.audience` parameter in the `openid-connect` configuration options does NOT cause the plugin to add the required form parameter.

Please use the `config.token_post_args_names` (Config.Token Post Args Names in the Kong Manager UI) and `config.token_post_args_values` (Config.Token Post Args Values in the Kong Manager UI) configuration parameters to correctly set the `audience` parameter.

An example of the relevant configuration would be:

```json

 "token_post_args_names": [
      "audience"
    ],
"token_post_args_values": [
      "https://<audienceURL>"
    ],
```

Or in Kong Manager:
