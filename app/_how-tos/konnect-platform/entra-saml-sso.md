---
title: Configure SAML SSO for Konnect with Microsoft Entra ID
permalink: /konnect-platform/entra-saml-sso/
content_type: how_to
description: Learn how to configure SAML 2.0 SSO for Kong Konnect using Microsoft Entra ID as the identity provider.
products:
  - konnect
works_on:
  - konnect
tags:
  - saml
  - sso
  - authentication
  - azure
automated_tests: false
tldr:
  q: How do I configure SAML SSO for Konnect with Microsoft Entra ID?
  a: |
    Create a non-gallery enterprise application in Microsoft Entra ID, configure the SAML settings with your {{site.konnect_short_name}} organization ID and login path, and map the required user attributes and claims. Then configure the SAML authentication scheme in {{site.konnect_short_name}} Organization settings with the App Federation Metadata URL from Entra ID and enable SAML.
related_resources:
  - text: "{{site.konnect_short_name}} authentication"
    url: /konnect-platform/authentication/
prereqs:
  skip_product: true
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: Microsoft Entra ID
      content: |
        You need a Microsoft Entra account with the Cloud Application Administrator or Application Administrator role.

        Copy your {{site.konnect_short_name}} organization ID from **{{site.konnect_short_name}} > Organization > Settings > General**.
      icon_url: /assets/icons/azure.svg
---

The following diagram shows the SAML authentication flow between a user, {{site.konnect_short_name}}, and Microsoft Entra ID:

{% comment %}
{% mermaid %}
sequenceDiagram
    participant User
    participant Konnect as Kong Konnect (SP)
    participant Entra as Entra ID (IdP)

    User->>Konnect: Access Login URL (https://cloud.konghq.com/login/<custom_path>)
    Konnect->>User: Redirect to IdP SSO URL (https://login.microsoftonline.com/<tenant_id>/saml2)
    User->>Entra: Send SAML Request (SP Entity ID: https://cloud.konghq.com/sp/<organization_id>)
    Entra->>User: Return SAML Response with Claims (Email, NameID, Groups)
    User->>Konnect: Post SAML Response to ACS URL (https://global.api.konghq.com/v2/authenticate/<custom_path>/saml/acs)
    Konnect->>Konnect: Validate SAML Response (Verify Signature, Claims)
    Konnect->>User: Grant Access to Kong Konnect
{% endmermaid %}
{% endcomment %}

## Create an enterprise application in Microsoft Entra ID

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com) using your admin account.
1. Go to **Microsoft Entra ID** > **Enterprise applications**.
1. Click **New application**, then click **Create your own application**.
1. Enter a name for the application (for example, `Kong Konnect SSO`), select **Integrate any other application you don't find in the gallery (Non-gallery)**, and click **Create**.

## Configure SAML settings in Microsoft Entra ID

### Configure Basic SAML

Before configuring Entra ID, decide on the login path you want to use for your {{site.konnect_short_name}} organization. You'll use this same value in both Entra ID and {{site.konnect_short_name}}.

1. In the application, click **Single sign-on** in the sidebar.
1. Select **SAML** as the single sign-on method.
1. In the **Basic SAML Configuration** section, click **Edit**.
1. In the **Identifier (Entity ID)** field, enter `https://cloud.konghq.com/sp/<your-organization-id>`.
1. In the **Reply URL (Assertion Consumer Service URL)** field, enter `https://global.api.konghq.com/v2/authenticate/<your-login-path>/saml/acs`.
1. In the **Sign on URL** field, enter `https://cloud.konghq.com/login/<your-login-path>`.
1. Click **Save**.

### Configure user attributes and claims

1. In the **Attributes & Claims** section, click **Edit**.
1. Configure the following claims. For each claim, clear the namespace URI before saving:
   1. Set **Unique user identifier** to `user.userprincipalname`.
   1. Click **Add a group claim** and configure it to send `user.groups`.
   1. Add a claim named `firstname` with source attribute `user.givenname`.
   1. Add a claim named `lastname` with source attribute `user.surname`.
   1. Add a claim named `email` with source attribute `user.mail`.
1. Click **Save**.
1. Copy the **App Federation Metadata URL** from the **SAML Certificates** section. You'll need this in the next section.

{:.warning}
> **Important:** Use the App Federation Metadata URL, not the tenant-level metadata URL. Using the tenant-level URL causes an invalid SAML response error due to a certificate mismatch.

## Configure SAML in {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} sidebar, click **Organization**.
1. Click the **Settings** tab.
1. Click the **Authentication scheme** tab.
1. On the **SAML** tile, click **Configure**.
1. In the **IDP Metadata URL** field, enter the App Federation Metadata URL from Microsoft Entra ID.
1. In the **Login Path** field, enter the login path you chose when configuring Entra ID (for example, `my-org`). {{site.konnect_short_name}} uses this to generate your organization's custom login URL: `https://cloud.konghq.com/login/<login-path>`.
1. Click **Save**.

## Configure team mappings

Team mappings let you automatically assign {{site.konnect_short_name}} teams based on Entra ID group membership.

1. Click the **Team mappings** tab.
1. Select the **IdP Mapping Enabled** checkbox.
1. For each team you want to map, enter the corresponding Entra ID group name in the **Group Name** field.
1. Click **Save**.

## Enable SAML

1. Click the **Authentication scheme** tab.
1. On the **SAML** tile, click the action menu icon.
1. Click **Enable SAML**.

## Validate

1. Navigate to your custom login URL: `https://cloud.konghq.com/login/<your-login-path>`.
1. You are redirected to the Microsoft Entra ID sign-in page.
1. Log in with your Entra ID credentials. If the configuration is correct, you are authenticated into {{site.konnect_short_name}}.
