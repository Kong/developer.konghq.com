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
  - text: Enterprise
    url: /insomnia/enterprise/
---

Insomnia allows you to configure Single Sign-On (SSO) to authenticate users with your preferred SAML or OIDC Identity Provider.

## Configure SSO

To configure SCIM, you need to:
1. Add and verify a [domain](https://app.insomnia.rest/app/enterprise/domains/list).
1. Configure SSO in your IdP and get the sign in URL and the certificate
1. Enable [SSO](https://app.insomnia.rest/app/enterprise/sso/list) with the relevant parameters for your IdP.

For more details, see the SSO how-to guides:
* [Okta](/how-to/okta-saml-sso-insomnia/)
* [Azure](/how-to/azure-saml-sso-insomnia/)