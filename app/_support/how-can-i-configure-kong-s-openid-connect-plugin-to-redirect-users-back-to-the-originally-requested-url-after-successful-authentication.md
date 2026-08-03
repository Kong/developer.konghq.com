---
title: "Configuring Kong's OpenID Connect plugin to redirect users back to the originally requested URL after authentication"
content_type: support
description: "Leave the `redirect_uri` parameter blank in the OpenID Connect plugin configuration so it can dynamically redirect users back to the page they originally requested after authenticating with an IDP like Azure AD or Keycloak."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "How can I configure Kong's openid-connect plugin to redirect users back to the originally requested URL after successful authentication?"
  a: |
    Leave the `redirect_uri` parameter blank in the OpenID Connect plugin configuration. This lets the plugin dynamically redirect users back to the page they originally requested after authenticating with the IDP (for example Azure AD or Keycloak), instead of sending them to a default URL. If your IDP requires an explicit allow-list of redirect URIs rather than dynamic redirects, register all needed URIs in the IDP configuration.
---

## Overview

How can I configure Kong's openid-connect plugin to redirect users back to the originally requested URL after successful authentication with Okta?

## Steps

When using Kong's openid-connect plugin in conjunction with an Identity Provider (IDP) like Azure AD or Keycloak, you may encounter a scenario where, after authentication, users are not redirected back to the originally requested URL. Instead, they are taken to a default URL, which can disrupt the user experience.

To address this issue, you can leave the `redirect_uri` parameter in Kong's openid-connect plugin configuration blank. This allows the plugin to dynamically handle the redirect to the originally requested URL after the user authenticates with the IDP.

Here's a step-by-step guide to implement the solution:

1. Ensure that the `redirect_uri` parameter in Kong's openid-connect plugin configuration is left blank.
2. Configure your IDP (e.g., Azure AD, Keycloak) to accept dynamic redirect URIs if supported.
3. After successful authentication, the IDP will redirect the user back to a pre-configured URI, which should be the original page the user accessed.

This approach ensures that users are seamlessly redirected to the page they initially requested after logging in, providing a smooth and intuitive user experience similar to what you might find with other applications.

Remember to list all the necessary redirect URIs in your IDP configuration if you are not using dynamic URIs. If you have a large number of URIs, consider automating this process with a script.

By following these steps, you should be able to resolve the redirect issue and provide users with a consistent login experience using Kong's openid-connect plugin and your chosen IDP.
