---
title: Configure Okta SAML SSO in Insomnia

content_type: how_to

products:
    - insomnia

related_resources:
  - text: Authentication & Authorization in Insomnia
    url: /insomnia/authentication-authorization/
  - text: Configure Azure SAML SSO in Insomnia
    url: /how-to/azure-saml-sso-insomnia/

tier: enterprise

tags:
  - sso
  - third-party
  - authentication
  - security

tldr:
    q: How do I configure SSO with SAML 2.0 and Okta in Insomnia?
    a: Obtain the single sign-on URL and audience URI from the Insomnia SSO settings and add them to an application integration in Okta. Copy the sign on URL and signing certificate from Okta and enter those in the Insomnia SSO settings. Finally, add users or groups to the Okta app integration and invite those same users to the Insomnia app.

prereqs:
  inline:
  - title: Insomnia permissions
    include_content: prereqs/insomnia-sso
    icon_url: /assets/icons/insomnia/insomnia.svg
  - title: Okta permissions
    include_content: prereqs/okta-sso
    icon_url: /assets/icons/okta.svg
  - title: Domain permissions
    include_content: prereqs/sso-domain
    icon_url: /assets/icons/domain.svg
---

## 1. Create the SSO connection in Insomnia

Before you can configure the SSO connection in Okta, you must start configuring the SSO settings in Insomnia so you have access to the single-sign on URL and audience URI for the Okta settings.

1. In your Insomnia account settings, click your account at the top right and select **Enterprise Controls** from the dropdown.
1. Click **SSO** in the sidebar and then click **Create Connection**.
1. In the SSO settings, enter your company's domain.

Keep this window open while you configure the settings in Okta.

## 2. Configure SAML 2.0 SSO in Okta

Now that you have the single-sign on URL and audience URI from Insomnia, you can create a new app integration in Okta. 

1. Create a [new app integration in Okta](https://help.okta.com/en-us/content/topics/apps/apps_app_integration_wizard_saml.htm).
1. For the Sign-in method, select **SAML 2.0**.
1. Configure the general settings as needed.
1. Configure the following app [SAML settings](https://help.okta.com/en-us/content/topics/apps/aiw-saml-reference.htm):
   
   | Okta setting | Value |
   |--------------|-------|
   | Single sign-on URL | Copy this from the SSO settings in Insomnia. |
   | Audience URI (SP Entity ID) | Copy this from the SSO settings in Insomnia. |
   | Name ID format | EmailAddress |
   | Application username | Email |
   | Update application username on | Create and update | 
1. In the Attribute Statements, add the following attribute:
   
   | Name | Name format | Value |
   |------|-------------|-------|
   | `email` | Unspecified | user.email |
1. Save the new application.
1. In the application Sign On page, find and copy the **Sign on URL**. This will be used for the sign on URL in Insomnia.
1. [Create a signing certificate](https://help.okta.com/en-us/content/topics/apps/manage-signing-certificates.htm) for your app and copy the certificate. This will be used in the Insomnia SSO settings.

## 3. Enter the sign on URL and signing certificate in the SSO settings in Insomnia

Now that Okta SSO is configured and you have the sign on URL and certificate from Okta, you can finish configuring the SSO settings in Insomnia.

1. In the Insomnia SSO settings, enter the sign on URL and signing certificate from Okta.
1. To verify the connection, click **Create connection**. If the connection is successful, you will get a message that says "Your SAML connection has been successfully updated."

## 4. Add users or groups to the application in Okta

You can add users or groups to the application in Okta. They won't be allowed to log in with SSO yet though.

In Okta, [assign users or groups to the app integration](https://help.okta.com/en-us/content/topics/apps/apps-manage-assignments.htm). 

## 5. Invite users to Insomnia

Now that users or groups are assigned to the app in Okta, you can start inviting users to Insomnia. Once they accept the invite, they can log in to Insomnia with SSO.

1. In your Insomnia account settings, click your account at the top right and select **Your organizations**. 
1. Click the organization you configured SSO for.
1. Enter the emails of the users you added to the Okta app and click **Invite**.

