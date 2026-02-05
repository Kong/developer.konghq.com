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
    a: Obtain the single sign-on URL from the Insomnia SSO settings and add them to a new Microsoft Entra SAML Toolkit in Azure. Copy the Login URL and signing certificate from Azure and enter those in the Insomnia SSO settings. Finally, add users or groups to the Azure app integration and invite those same users to the Insomnia app.

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

## Create the SSO connection in Insomnia

Before you can configure the SSO connection in Azure, you must start configuring the SSO settings in Insomnia so you have access to the single-sign on URL and audience URI for the Azure settings.

1. In your Insomnia account settings, click your account at the top right and select **Enterprise Controls** from the dropdown.
1. Click **SSO** in the sidebar and then click **Create Connection**.
1. In the SSO settings, enter your company's domain.

Keep this window open while you configure the settings in Azure.

## Add the Microsoft Entra SAML Toolkit and configure SSO settings

Now that you have the single-sign on URL from Insomnia, you can create a new Microsoft Entra SAML Toolkit. 

1. In the [Microsoft Entra admin center](https://entra.microsoft.com/), create a new application and [add the Microsoft Entra SAML Toolkit from the gallery](https://learn.microsoft.com/entra/identity/saas-apps/saml-toolkit-tutorial#add-microsoft-entra-saml-toolkit-from-the-gallery).
1. Rename the toolkit "Insomnia SAML".
1. [Navigate to the SSO settings](https://learn.microsoft.com/entra/identity/saas-apps/saml-toolkit-tutorial#configure-microsoft-entra-sso) for the Microsoft Entra SAML toolkit you just created.
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

1. In the Entra application, find and copy the **Login URL** and the base64 version of the signing certificate. These will be used in the Insomnia SSO settings.

## Enter the sign on URL and signing certificate in the SSO settings in Insomnia

Now that Azure SSO is configured and you have the Login URL and certificate from Azure, you can finish configuring the SSO settings in Insomnia.

1. In the Insomnia SSO settings, enter the Login URL and signing certificate from Azure.
1. To verify the connection, click **Create connection**. If the connection is successful, you will get a message that says "Your SAML connection has been successfully updated."

## Add users or groups to the application in Azure

You can add users or groups to the application in Azure. They won't be allowed to log in with SSO yet though.

In Azure, [assign users or groups to the app](https://learn.microsoft.com/entra/identity/enterprise-apps/assign-user-or-group-access-portal?pivots=portal#assign-users-and-groups-to-an-application-using-the-microsoft-entra-admin-center). 

## Invite users to Insomnia

Now that users or groups are assigned to the app in Azure, you can start inviting users to Insomnia. Once they accept the invite, they can log in to Insomnia with SSO.

1. In your Insomnia account settings, click your account at the top right and select **Your organizations**. 
1. Click the organization you configured SSO for.
1. Enter the emails of the users you added to the Azure app and click **Invite**.
