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
  - beta
breadcrumbs:
  - /dev-portal/
api_specs:
  - konnect/portal-management
search_aliases:
  - Portal
  - OpenID Connect
  - SSO
beta: true
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
* Each Dev Portal has its own SSO configuration.
  * You can use the same IdP across multiple Dev Portals or configure different IdPs per portal.
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
    `https://$YOUR_SUBDOMAIN.edge.us.portal.konghq.com/api/v2/developer/authenticate/saml/acs`
* Allow iframe embedding of the IdP's sign-in screen:
  * For example, Okta requires [Trusted Origins](https://help.okta.com/en-us/content/topics/api/trusted-origins-iframe.htm).  
    Add `https://cloud.konghq.com` as a Trusted Origin to allow login in the preview.

