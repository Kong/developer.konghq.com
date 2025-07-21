---
title: Publish APIs with Dev Portal
content_type: reference
layout: reference

products:
    - dev-portal
tags:
  - publish-apis
works_on:
    - konnect

search_aliases:
  - Portal
api_specs:
  - konnect/api-builder
breadcrumbs:
  - /dev-portal/

description: "Learn how to publish APIs with Dev Portal and control who can see published APIs."

faqs:
  - q: Why don't I see API Products in my {{site.konnect_short_name}} sidebar?
    a: API Products were used to create and publish APIs to classic (v2) Dev Portals. When the new (v3) Dev Portal was released, API Products was removed from the sidebar navigation of any {{site.konnect_short_name}} organization that didn't have an existing API product. If you want to create and publish APIs, you can create a new (v3) Dev Portal. To get started, see [Automate your API catalog with Dev Portal](/how-to/automate-api-catalog/).

related_resources:
  - text: Dev Portal settings
    url: /dev-portal/portal-settings/
  - text: Dev Portal security settings
    url: /dev-portal/security-settings/
---

Publishing an API makes it available to one or more Dev Portals. 
With the appropriate [security](/dev-portal/security-settings/) and [access and approval](/dev-portal/self-service/) settings, you can publish an API securely to the appropriate audience.

Make sure you have [created APIs](/dev-portal/apis/) before attempting to publish to them your Dev Portals.

## Publish an API to a Dev Portal

There are two methods for publishing an API:
* Click on your Dev Portal, and select **Published APIs**. Click **Publish**
* Click on **APIs**, and select the API you want to publish. Click **Publish**

In both cases, you'll see the same dialog:

1. Select the **Dev Portal** you want to publish the API to.
2. Select an **Authentication Strategy**. 

   The default value for this setting is set in **Settings > Security** for the specific Dev Portal. 
   This determines how developers will generate credentials to call the API.

3. Select the appropriate **Visibility**. 
  
   The default value for this setting is set in **Settings > Security** for the specific Dev Portal. 
   Visibility determines if developers need to register to view the API or generate credentials and API keys. 

## Change a published API

Change the **Visibility** or **Authentication Strategy** of an API that has been published to one or more Dev Portals:

1. Browse to a **Published API**.
2. Select the **Portals** tab to see where the API has been previously published.
3. Click the menu icon next to the appropriate Dev Portal, select **Edit Publication**.
4. Change **Visibility** and **Authentication Strategy** to the appropriate values.
5. Click **Save**.

## Access control scenarios

Visibility, authentication strategies, and user authentication can be independently configured to maximize flexibility in how you publish your API to a given developer audience. 

{:.info}
> * The visibility of [pages](/dev-portal/pages-and-content/) and [menus](/dev-portal/portal-customization/) is configured independently from APIs, maximizing your flexibility.
> * {% new_in 3.6 %} An API must be linked to a {{site.konnect_short_name}} Gateway Service to be able to restrict access to your API with authentication strategies.

The following table describes various Dev Portal access control scenarios and their settings:

<!--vale off-->
{% table %}
columns:
  - title: Access use case
    key: use-case
  - title: Visibility
    key: visibility
  - title: Authentication strategy
    key: strategy
  - title: User authentication
    key: user-auth
  - title: Description
    key: description
rows:
  - use-case: Viewable by anyone, no self-service credentials
    visibility: Public
    strategy: Disabled
    user-auth: "Disabled in [security settings](/dev-portal/security-settings/)"
    description: Anyone can view the API's specs and documentation, but cannot generate credentials and API keys. No developer registration is required.
  - use-case: Viewable by anyone, self-service credentials
    visibility: Public
    strategy: "`key-auth` (or any other appropriate authentication strategy)"
    user-auth: "Enabled in [security settings](/dev-portal/security-settings/)"
    description: |
      Anyone can view the API's specs and documentation, but must sign up for a developer account and create an Application to generate credentials and API keys. 
      <br><br>
      RBAC is disabled if fine-grained access management is not needed, configured in [security settings](/dev-portal/security-settings/).
  - use-case: Viewable by anyone, self-service credentials with RBAC
    visibility: Public
    strategy: "`key-auth` (or any other appropriate Authentication strategy)"
    user-auth: "Enabled in [security settings](/dev-portal/security-settings/)"
    description: |
      Anyone can view the API's specs and documentation, but must sign up for a developer account and create an Application to generate credentials and API keys. 
        <br><br>
        A {{site.konnect_short_name}} Admin must assign a developer to a Team to provide specific role-based access. RBAC is enabled to allow [Teams](/dev-portal/access-and-approval) assignments for developers, granting credentials with the API Consumer role.
  - use-case: Sign up required to view API specs and/or documentation
    visibility: Private
    strategy: "`key-auth` (or any other appropriate Authentication strategy)"
    user-auth: "Enabled in [security settings](/dev-portal/security-settings/)"
    description: |
      All users must sign up for a Developer account to view APIs. They can optionally create an Application to generate credentials/API keys. 
      <br><br>
      RBAC can be enabled for [Teams](/dev-portal/access-and-approval) assignments for developers, granting credentials with the API Consumer role, configured in [security settings](/dev-portal/security-settings/).
{% endtable %}
<!--vale on-->
