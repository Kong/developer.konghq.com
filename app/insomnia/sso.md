---
title: Single Sign-On (SSO) for Insomnia

description: Learn how to configure SSO for your Enterprise account.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
products:
    - insomnia
tier: enterprise
related_resources:
  - text: Insomnia Enterprise
    url: /insomnia/enterprise/
  - text: Enterprise user management
    url: /insomnia/enterprise-user-management/
  - text: Enterprise account management
    url: /insomnia/enterprise-account-management/
  - text: SCIM for Insomnia
    url: /insomnia/scim/
---

Insomnia supports Single Sign-On (SSO) for Enterprise organizations. Configure SSO to authenticate users with your identity provider (IdP) using SAML 2.0 or OpenID Connect (OIDC).

{:.warning}
> Once you enable SSO on your Enterprise account, users will no longer be able to use other login methods.

## Supported identity providers
The SSO how-to guides detail configuration for:
- Okta (SAML 2.0 and OIDC)
- Microsoft Entra ID (Azure AD) with SAML 2.0

## Supported connection types
Insomnia supports the following SSO connection types:
- SAML 2.0
- OpenID Connect (OIDC)

## Prerequisites

Before you configure SSO, you must meet all of the following requirements:

In Insomnia:
- Your organization is on the Enterprise plan.
- You have the Owner role in the Insomnia organization.
- You have added and verified at least one [domain](https://app.insomnia.rest/app/enterprise/domains/list) for SSO login.

In your identity provider:
- You have an administrator account with permission to create or configure an Enterprise application for SSO.

## Configure SSO

To configure SSO, you need to:
1. Configure SSO in your IdP and get the sign in URL and the certificate.
1. Enable [SSO](https://app.insomnia.rest/app/enterprise/sso/list) with the relevant parameters for your IdP.

For more details, see the SSO how-to guides:
* [Okta SAML](/how-to/okta-saml-sso-insomnia/)
* [Okta OpenID Connect](/how-to/okta-oidc-sso-insomnia/)
* [Azure](/how-to/azure-saml-sso-insomnia/)