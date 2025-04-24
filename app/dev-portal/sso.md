---
title: SSO reference
description: 'Set up SSO for the {{site.konnect_short_name}} Dev Portal using OpenID Connect (OIDC) or SAML.'
content_type: reference
layout: reference
products:
  - dev-portal
tags:
  - authentication
  - sso
works_on:
  - konnect
related_resources:
  - text: "Configure SSO for a {{site.konnect_short_name}} Org"
    url: /konnect-platform/konnect-sso/
  - text: "IdP SAML attribute mapping reference"
    url: /konnect-platform/saml-idp-mappings/
---

You can configure single sign-on (SSO) for {{site.konnect_short_name}} Dev Portal with OpenID Connect (OIDC) or SAML.
This allows developers to log in to Dev Portals using their identity provider (IdP) credentials without needing a separate login. 

## Behavior and Recommendations

* Developers are auto-approved by {{site.konnect_short_name}} when using SSO to log in to the Dev Portal.
  * Kong outsources the approval process to the IdP, so access restrictions must be configured in the IdP.
* If you are using [team mappings from an IdP](/dev-portal/team-mapping/), they must come from the same IdP as your Dev Portal SSO.
* Each Dev Portal has its own SSO configuration.
  * You can use the same IdP across multiple Dev Portals or configure different IdPs per portal.
* Dev Portal SSO is distinct from [{{site.konnect_short_name}} Org-level SSO](/konnect-platform/konnect-authentication/).
* You can combine built-in authentication with either OIDC or SAML (not both).
  * Keep built-in authentication enabled while testing your IdP integration.
  * Disable built-in authentication only after successfully validating the SSO login flow.

{:.important}
> Combining OIDC and SAML simultaneously is not supported. Use only one protocol alongside built-in auth if needed.

## {{site.konnect_short_name}} Portal Editor Considerations

To ensure the preview experience in the {{site.konnect_short_name}} Portal Editor works correctly, configure your IdP with the following:

* Set the Sign On URL (SSO URL) to the login path of your Portal's domain:  
  `https://example.com/login/sso`
* For SAML:
  * Set the primary **Reply URL** (Assertion Consumer Service URL) to:  
    `https://example.com/api/v2/developer/authenticate/saml/acs`
  * Add an additional Reply URL to support preview mode:  
    `https://{subdomain}.edge.{region}.portal.konghq.com/api/v2/developer/authenticate/saml/acs`
* Allow iframe embedding of the IdP's sign-in screen:
  * For example, Okta requires [Trusted Origins](https://help.okta.com/en-us/content/topics/api/trusted-origins-iframe.htm).  
    Add `https://cloud.konghq.com` as a Trusted Origin to allow login in the preview.

