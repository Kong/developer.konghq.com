---
title: Dev Portal SSO
description: 'Set up SSO for the {{site.konnect_short_name}} Dev Portal using OpenID Connect (OIDC) or SAML.'
content_type: reference
layout: reference
products:
  - dev-portal
tags:
  - authentication
  - sso
breadcrumbs:
  - /dev-portal/
api_specs:
  - konnect/portal-management
search_aliases:
  - Portal
  - OpenID Connect
  - SSO
works_on:
  - konnect
related_resources:
  - text: Dev Portal team mapping
    url: /dev-portal/team-mapping/
  - text: "Configure SSO for a {{site.konnect_short_name}} org"
    url: /konnect-platform/sso/
  - text: "IdP SAML attribute mapping reference"
    url: /konnect-platform/saml-idp-mapping/
  - text: Dev Portal access and authentication settings
    url: /dev-portal/security-settings/
  - text: Authentication strategies
    url: /dev-portal/auth-strategies/
---

You can configure single sign-on (SSO) for {{site.konnect_short_name}} Dev Portal with OpenID Connect (OIDC) or SAML.
This allows developers to log in to Dev Portals using their identity provider (IdP) credentials without needing a separate login.

To configure SSO, navigate to [Dev Portal](https://cloud.konghq.com/portals/), click your Dev Portal, and click **Settings** in the sidebar. Then, click the **Identity** tab.

## Behavior and recommendations

When configuring SSO for Dev Portal, keep the following guidelines in mind:

* Developers are auto-approved by {{site.konnect_short_name}} when using SSO to log in to the Dev Portal.
  * Kong outsources the approval process to the IdP, so access restrictions must be configured in the IdP.
* If you are using [team mappings from an IdP](/dev-portal/team-mapping/), they must come from the same IdP as your Dev Portal SSO.
* To automatically initiate the login flow when linking developers to the Dev Portal, use the SSO URL: `https://$YOUR_DOMAIN.com/login/sso`
* Each Dev Portal has its own SSO configuration.
  * You can use the same IdP across multiple Dev Portals or configure different IdPs per portal.
* With OIDC, when a developer's IdP session ends, your IdP can notify the Dev Portal to end that developer's session. See [OIDC back-channel logout](#oidc-back-channel-logout).
* Dev Portal SSO is distinct from [{{site.konnect_short_name}} Org-level SSO](/konnect-platform/authentication/).
* You can combine built-in authentication with either OIDC or SAML (not both).
  * Keep built-in authentication enabled while testing your IdP integration.
  * Disable built-in authentication only after successfully validating the SSO login flow.

{:.warning}
> Combining OIDC and SAML is not supported. Use only one protocol alongside built-in auth if needed.

## {{site.konnect_short_name}} Dev Portal Editor considerations

To ensure the preview experience in the {{site.konnect_short_name}} Dev Portal Editor works correctly, configure your IdP with the following:

* Set the Sign On URL (SSO URL) to the login path of your Dev Portal's domain:
  `https://$YOUR_DOMAIN.com/login/sso`
* For SAML:
  * Set the primary **Reply URL** (Assertion Consumer Service URL) to:
    `https://$YOUR_DOMAIN.com/api/v2/developer/authenticate/saml/acs`
  * Add an additional Reply URL to support preview mode:
     `https://$YOUR_SUBDOMAIN.portal-preview.$GEO.api.konghq.com/api/v2/developer/authenticate/saml/acs`
* Allow iframe embedding of the IdP's sign-in screen:
  * For example, Okta requires [Trusted Origins](https://help.okta.com/en-us/content/topics/api/trusted-origins-iframe.htm).
    Add `https://cloud.konghq.com` as a Trusted Origin to allow login in the preview.

## OIDC back-channel logout

If you use OIDC for SSO, you can configure back-channel logout so the Dev Portal ends a developer's session when their IdP session ends.
When back-channel logout isn't enabled, a developer who logs out from the IdP (or an admin who terminates their IdP session, for example after offboarding) stays logged in to {{site.dev_portal}} until their {{site.dev_portal}} tokens expire.

By default, when a developer signs out of your IdP, they stay signed in to the Dev Portal until their Dev Portal session expires.

Before enabling back-channel logout, keep the following in mind:
* Back-channel logout only applies to sessions that start after you enable it.
* If your IdP doesn't send a session ID, all of a developer's Dev Portal sessions are ended.
* Some IdPs send a logout request only when a developer signs themselves out, or only end one session when an admin ends all of a developer's sessions. Verify how your IdP behaves.
* If the request from your IdP is invalid, the Dev Portal ignores it and doesn't sign anyone out.
* Encrypted logout tokens aren't supported. Your IdP must send signed, unencrypted logout tokens.
* The Dev Portal rejects logout tokens that are more than 10 minutes old.

### Requirements

* Your Dev Portal uses OIDC for SSO.
* Your IdP supports OpenID Connect Back-Channel Logout 1.0.
* Your IdP can reach your Dev Portal over the internet.

### Set up back-channel logout

1. In your IdP, find the application you created for the Dev Portal and set its back-channel logout URL to one of the following:
   * If you're using a custom domain: `https://www.example.com/api/v3/oauth/backchannel-logout`
   * If you aren't using a custom domain: `https://abc123456789.us.kongportals.com/api/v3/oauth/backchannel-logout`

   If your IdP has a setting that includes the session ID in the logout request (often called "session required"), turn it on. This lets the Dev Portal only end the session that signed out, instead of every session for that developer.

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.dev_portal}}**](https://cloud.konghq.com/portals/).
1. Click your {{site.dev_portal}}.
1. In the {{site.dev_portal}} sidebar, click **Settings**.
1. Click the **Security** tab.
1. Next to your OIDC identity provider, click **Configure**.
1. Enable **Back-channel logout**.


## Dev Portal SSO configuration example

The following is an example Dev Portal SSO configuration. For the example, we will use the following values:

- **{{site.konnect_short_name}} Dev Portal region/geo**: `us`
- **{{site.konnect_short_name}} Dev Portal provided domain**: `abc123456789.us.kongportals.com`
- **Desired custom domain**: `www.example.com`

### OIDC-specific settings

If you're using OIDC for SSO, you'd configure your settings like the following:
- **Single Sign On URL (SSO URL)**: Also sometimes referred to as **Initiate login URI**, use to automatically initiate the SSO login flow.
  - If you're using a custom domain: `https://www.example.com/login/sso`
  - If you aren't using a custom domain: `https://abc123456789.us.kongportals.com/login/sso`
- **Sign-in redirect URIs**:
  - `https://www.example.com/login`
  - `https://abc123456789.us.kongportals.com/login`
  - `https://abc123456789.portal-preview.us.api.konghq.com/login`

- **Sign-out redirect URIs**:
  - `https://www.example.com/login`
  - `https://abc123456789.us.kongportals.com/login`
  - `https://abc123456789.portal-preview.us.api.konghq.com/login`

### SAML-specific settings:

If you're using SAML for SSO, you'd configure your settings like the following:
- **Single Sign On URL (SSO URL)**: Also sometimes referred to as **Initiate login URI**, used to automatically initiate the SSO login flow.
    - If you're using a custom domain: `https://www.example.com/api/v2/developer/authenticate/saml/acs`
    - If you aren't using a custom domain: `https://abc123456789.us.kongportals.com/api/v2/developer/authenticate/saml/acs`
  - To automatically initiate the login flow when linking developers to the Dev Portal, use the dedicated path:
    - If you're using a custom domain: `https://www.example.com/login/sso`
    - If you aren't using a custom domain: `https://abc123456789.us.kongportals.com/login/sso`
- **Other Requestable SSO URLs** (typically found in Advanced settings) for the Konnect Portal Editor:
  - `https://abc123456789.portal-preview.us.api.konghq.com/api/v2/developer/authenticate/saml/acs`
