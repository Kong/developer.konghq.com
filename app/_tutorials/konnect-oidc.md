---
title: Configure OIDC in Konnect
related_resources:
  - text: Authentication
    url: /authentication


products:
    - konnect

platforms:
    - konnect

tags:
  - authentication
  - oidc
  - sso

content_type: tutorial

---

You can configure rate-limiting based on peak or non-peak times by using the Pre-function and the Rate Limiting Advanced plugins together. This tutorial creates two Kong Gateway routes, one to handle peak traffic, and one to handle off-peak traffic. Each route has a different rate limiting configuration. The Pre-function plugin runs a Lua function to ship traffic to either of the routes based on the time. 

## Configure Konnect

1. In [Konnect](https://cloud.konghq.com/login), click **Organization**, and then **Auth Settings**.
1. Click **Configure provider** for **OIDC**.

1. Paste the issuer URI from your IdP in the **Issuer URI** box. 

1. Paste the client ID from your IdP in the **Client ID** box.

1. Paste the client secret from your IdP in the **Client Secret** box.

1. In the **Organization Login Path** box, enter a unique string. For example: `examplepath`.

1. After clicking Save, close the configuration dialog and click Enable on your OIDC provider.

You can test the SSO configuration by navigating to the login URI based on the organization login path you set earlier. For example: `https://cloud.konghq.com/login/examplepath`, where `examplepath` is the unique login path string set in the steps above. 
If your configuration is set up correctly, you will see the IdP sign-in page.

## Advanced configuration

### Advanced OIDC settings

You can configure custom IdP-specific behaviors in the **Advanced Settings** of the OIDC configuration form. The following options are available:

1. **Scopes**: Specify the list of scopes Konnect requests from the IdP. By default, Konnect requests the `openid`, `email`, and `profile` scopes. The `openid` scope is required and cannot be removed.
2. **Claim Mappings**: Customize the mapping of required attributes to a different claim in the `id_token` Konnect receives from the IdP. By default, Konnect requires three attributes: Name, Email, and Groups. The values in these attributes are mapped as follows:
    - `name`: Used as the Konnect account's `full_name`.
    - `email`: Used as the Konnect account's `email`.
    - `groups`: Used to map users to teams defined in the team mappings upon login.

