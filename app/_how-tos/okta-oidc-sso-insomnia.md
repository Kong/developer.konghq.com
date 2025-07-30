---
title: Configure Okta OpenID Connect SSO in Insomnia
description: Learn how to secure Insomnia by setting up OIDC single sign-on (SSO) with Okta.
content_type: how_to

products:
    - insomnia

related_resources:
  - text: Authentication & Authorization in Insomnia
    url: /insomnia/authentication-authorization/
  - text: Configure Okta SAML SSO in Insomnia
    url: /how-to/okta-saml-sso-insomnia/
  - text: Configure Azure SAML SSO in Insomnia
    url: /how-to/azure-saml-sso-insomnia/
  - text: SSO for Insomnia
    url: /insomnia/sso/
  - text: Configure SCIM for Insomnia with Okta
    url: /how-to/configure-scim-for-insomnia-with-okta/

tier: enterprise

tags:
  - sso
  - okta
  - oidc
  - authentication
  - security

search_aliases:
    - OpenID Connect
    - oidc

tldr:
    q: How do I configure SSO with OpenID Connect and Okta in Insomnia?
    a: Obtain the single sign-on URL and audience URI from the Insomnia SSO settings and add them to an application integration in Okta. Copy the auth server issuer URL, client ID, and client secret from Okta and enter those in the Insomnia SSO settings. Finally, add users or groups to the Okta app integration and invite those same users to the Insomnia app.

prereqs:
  inline:
  - title: Insomnia role
    include_content: prereqs/insomnia-owner
    icon_url: /assets/icons/insomnia/insomnia.svg
  - title: Okta permissions
    include_content: prereqs/okta-sso
    icon_url: /assets/icons/okta.svg
  - title: Domain permissions
    include_content: prereqs/insomnia-verified-domain
    icon_url: /assets/icons/domain.svg
---

## Create the SSO connection in Insomnia

Before you can configure the SSO connection in Okta, you must start configuring the SSO settings in Insomnia so you have access to the single-sign on URL and audience URI for the Okta settings.

1. In your Insomnia account settings, click your account at the top right and select **Enterprise Controls** from the dropdown.
1. Click **SSO** in the sidebar and then click **Create Connection**.
1. In the SSO settings, enter your company's domain.

Keep this window open while you configure the settings in Okta.

## Configure OIDC SSO in Okta

1. In Okta, navigate to **Applications > Applications** in the sidebar.
1. Click **Create App Integration**.
1. Select **OIDC - OpenID Connect**.
1. Select **Web Application**.
1. In the **Sign-in redirect URIs** field, enter the SSO URL from Insomnia. For example: `https://insomnia-dev.us.auth0.com/login/callback`.
1. Save your settings, and from the **General** tab of the application, copy and save your client ID and client secret.
1. Click **Security > API** in the sidebar and navigate to the auth server you want to use.
1. Copy the issuer URL for your authorization server.

## Enter the Okta information in the SSO settings in Insomnia

Now that Okta SSO is configured and you have the issuer URL, client ID, and client secret from Okta, you can finish configuring the SSO settings in Insomnia.

1. In the Insomnia SSO settings, enter the issuer URL, client ID, and client secret from Okta.
1. To verify the connection, click **Create connection**. If the connection is successful, you will get a message that says "Your OIDC connection has been successfully updated."

## Add users or groups to the application in Okta

You can add users or groups to the application in Okta. They won't be allowed to log in with SSO yet though.

In Okta, [assign users or groups to the app integration](https://help.okta.com/en-us/content/topics/apps/apps-manage-assignments.htm). 

## Invite users to Insomnia

Now that users or groups are assigned to the app in Okta, you can start inviting users to Insomnia. Once they accept the invite, they can log in to Insomnia with SSO.

1. In your Insomnia account settings, click your account at the top right and select **Your organizations**. 
1. Click the organization you configured SSO for.
1. Enter the emails of the users you added to the Okta app and click **Invite**.

