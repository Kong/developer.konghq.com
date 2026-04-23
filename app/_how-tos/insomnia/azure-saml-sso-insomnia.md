---
title: Configure Azure SAML SSO in Insomnia
permalink: /how-to/azure-saml-sso-insomnia/

content_type: how_to
description: Configure SSO with SAML 2.0 and Azure in Insomnia.
products:
    - insomnia

related_resources:
  - text: Authentication & Authorization in Insomnia
    url: /insomnia/authentication-authorization/
  - text: Configure Azure SAML SSO in Insomnia
    url: /how-to/azure-saml-sso-insomnia/
  - text: SSO for Insomnia
    url: /insomnia/sso/
  - text: Configure SCIM for Insomnia with Azure
    url: /how-to/configure-scim-for-insomnia-with-azure/

tier: enterprise
breadcrumbs:
  - /insomnia/
tags:
  - sso
  - azure
  - authentication
  - security

tldr:
    q: How do I configure SSO with SAML 2.0 and Azure in Insomnia?
    a: Obtain the single sign-on URL from the Insomnia SSO settings and configure a new custom enterprise application in Azure with those values. Copy the Login URL and signing certificate from Azure and enter those in the Insomnia SSO settings. Finally, add users or groups to the Azure app and invite those same users to Insomnia.

prereqs:
  inline:
  - title: Insomnia role
    include_content: prereqs/insomnia-owner
    icon_url: /assets/icons/insomnia/insomnia.svg
  - title: Azure permissions
    include_content: prereqs/azure-sso
    icon_url: /assets/icons/azure.svg
  - title: Domain permissions
    include_content: prereqs/insomnia-verified-domain
    icon_url: /assets/icons/domain.svg

---

{:.warning}
> If you previously configured Azure SAML SSO for Insomnia using the Microsoft Entra SAML Toolkit from the gallery, you need to recreate the application as a custom non-gallery app to use SCIM provisioning. Your existing SSO configuration cannot be migrated. Follow this guide from the beginning to create a new custom app.

## Create the SSO connection in Insomnia

Start the SSO configuration in Insomnia first to get the single sign-on URL and audience URI you'll need in Azure.

1. In your Insomnia account settings, click your account at the top right and select **Enterprise Controls** from the dropdown.
1. Click **SSO** in the sidebar and then click **Create Connection**.
1. In the SSO settings, enter your company's domain.

Keep this window open while you configure the settings in Azure.

## Create a custom enterprise application and configure SSO settings

Create a custom enterprise application in Azure and configure it with the values from Insomnia.

{:.info}
> Do not use the Insomnia app from the Azure application gallery. Gallery apps do not support SCIM provisioning. Creating a custom app is required if you need automatic user provisioning.

1. In the [Microsoft Entra admin center](https://entra.microsoft.com/), go to **Microsoft Entra ID** > **Enterprise applications**.
1. Click **New application**, then click **Create your own application**.
1. Enter **Insomnia SAML** as the application name, select **Integrate any other application you don't find in the gallery (Non-gallery)**, and click **Create**.
1. From the application, select **Single Sign-On** from the left sidebar, then select **SAML**.
1. Configure the following SAML SSO settings:
   
{% capture table1 %}
{% table %}
columns:
  - title: Azure setting
    key: setting
  - title: Value
    key: value
rows:
  - setting: "Identifier (Entity ID)"
    value: "The **Audience Restriction** field in the Insomnia SSO settings."
  - setting: "Reply URL"
    value: "The **SSO URL** in the Insomnia SSO settings."
  - setting: "Sign on URL"
    value: "The **SSO URL** in the Insomnia SSO settings."
{% endtable %}
{% endcapture %}

{{ table1 | indent:3 }}

1. In the [Attributes & Claims settings section](https://learn.microsoft.com/en-us/entra/identity-platform/saml-claims-customization#view-or-edit-claims), add an attribute and configure the following attribute settings:
   
{% capture table2 %}
{% table %}
columns:
  - title: Azure setting
    key: setting
  - title: Value
    key: value
rows:
  - setting: "Name"
    value: "email"
  - setting: "Source"
    value: "Attribute"
  - setting: "Source attribute"
    value: "user.email"
{% endtable %}
{% endcapture %}

{{ table2 | indent:3 }}

1. In the Entra application, find and copy the **Login URL** and the base64 version of the signing certificate.

## Enter the sign on URL and signing certificate in the SSO settings in Insomnia

Enter the Login URL and certificate from Azure to finish the SSO configuration in Insomnia.

1. In the Insomnia SSO settings, enter the Login URL and signing certificate from Azure.
1. To verify the connection, click **Create connection**. If the connection is successful, you will get a message that says "Your SAML connection has been successfully updated."

## Add users or groups to the application in Azure

Assign users or groups to the application in Azure. Users cannot log in with SSO until they are invited to Insomnia in the next step.

In Azure, [assign users or groups to the app](https://learn.microsoft.com/entra/identity/enterprise-apps/assign-user-or-group-access-portal?pivots=portal#assign-users-and-groups-to-an-application-using-the-microsoft-entra-admin-center). 

## Invite users to Insomnia

Invite users to Insomnia. Once they accept, they can log in with SSO.

1. In your Insomnia account settings, click your account at the top right and select **Your organizations**. 
1. Click the organization you configured SSO for.
1. Enter the emails of the users you added to the Azure app and click **Invite**.
