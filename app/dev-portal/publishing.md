---
title: Publishing
content_type: reference
layout: reference

products:
    - dev-portal

works_on:
    - konnect

description: "Security settings allow for visibility and access control around Developers accessing your Dev Portal."

related_resources:
  - text: Dev Portal settings
    url: /dev-portal/portal-settings/
  - text: Dev Portal security settings
    url: /dev-portal/security/
---

Publishing an API makes it available to one or more Dev Portals. 
With the appropriate [security](/dev-portal/security-settings/) and [access and approval](/dev-portal/access-and-approval/) settings, you can publish an API securely to the appropriate audience.

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
3. On the three dots menu on the appropriate Dev Portal, select **Edit Publication**.
4. Change **Visibility** and **Authentication Strategy** to the appropriate values.
5. Click **Save**.

## Access control scenarios

Visibility, authentication strategies, and user authentication can be independently configured to maximize flexibility in how you publish your API to a given Developer audience.

{:.info}
> * The visibility of [pages](/dev-portal/custom-pages/) and [menus](/dev-portal/portal-customization/) is configured independently from APIs, maximizing your flexibility.
> * An API must be linked to a {{site.konnect_short_name}} Gateway Service (version 3.6+) to be able to restrict access to your API with authentication strategies.

### Viewable by anyone, no self-service credentials

Anyone can view the API's specs and documentation, but cannot generate credentials and API keys. No developer registration is required.
  * Visibility: Public
  * Authentication strategy: Disabled
  * User authentication: Disabled in [Security settings](/dev-portal/security-settings/)

### Viewable by anyone, self-service credentials
Anyone can view the API's specs and documentation, but must sign up for a developer account and create an Application to generate credentials and API keys.
  * Visibility: Public
  * Authentication strategy: `key-auth` (or any other appropriate authentication strategy)
  * User authentication: Enabled in [security settings](/dev-portal/security-settings/)
  * RBAC: Disabled, if you don't need to manage fine grained access with Teams, configured in [security settings](/dev-portal/security-settings/)

### Viewable by anyone, self-service credentials with RBAC
Anyone can view the API's specs and documentation, but must sign up for a developer account and create an Application to generate credentials and API keys. {{site.konnect_short_name}} Admin must assign a developer to a Team to provide specific role-based access.
  * Visibility: Public
  * Authentication strategy: `key-auth` (or any other appropriate Authentication strategy)
  * User authentication: Enabled in [security settings](/dev-portal/security-settings/)
  * RBAC: Enabled (allows for [Teams](/dev-portal/access-and-approval) assignments for developers, grants credentials with the API Consumer role) in [security settings](/dev-portal/security-settings/)

### Sign up required to view API specs and/or documentation
All users must sign up for a Developer account in order to view APIs. Optionally, they can create an Application to generate credentials/API keys with RBAC.
  * Visibility: Private
  * Authentication strategy: `key-auth` (or any other appropriate Authentication strategy)
  * User authentication: Enabled in [security settings](/dev-portal/security-settings/)
  * RBAC(optional): Enabled (allows for [Teams](/dev-portal/access-and-approval) assignments for developers, grants credentials with the API Consumer role) in [security settings](/dev-portal/security-settings/)