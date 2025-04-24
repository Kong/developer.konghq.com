---
title: Self-Service Developer & Application Registration
description: 'Enable self-service registration flows for developers and applications using authentication strategies and {{site.konnect_short_name}} application Auth.'
content_type: reference
layout: reference
products:
  - dev-portal
tags:
  - application-registration
  - authentication
works_on:
  - konnect
related_resources:
  - text: SSO reference
    url: /dev-portal/sso/
  - text: Auth strategies
    url: /dev-portal/auth-strategies/
faqs:
  - q: What are the prerequisites for configuring Dev Portal security in {{site.konnect_short_name}}?
    a: |
      To configure Dev Portal security settings, ensure you have:
      * A Gateway Service running version 3.6 or later
      * An [API linked to the Gateway Service](/dev-portal/apis/#gateway-service-link)
      * An [API published to a Dev Portal](/dev-portal/publishing)

      > Note: APIs must be linked to a Gateway Service to enforce authentication strategies.

---

{{site.konnect_short_name}} Dev Portal provides flexible options for controlling access to content and APIs. When combined with a Gateway Service, developers visiting a Dev Portal can sign up, create an application, register it with an API, and retrieve API keys without intervention from Dev Portal administrators. Developer sign ups and application creation require admin approval by default, which can be adjusted through the {{site.konnect_short_name}} UI in **Settings > Security**.

Application registration is enabled by:
* Enabling User Authentication
* Linking an API to a Gateway Service (version 3.6+)
* Selecting an authentication strategy when publishing the API to a Dev Portal

## Region-Specific applications

Applications and API keys are specific to a [geographic region](/konnect-geos/). When you enable application registration by selecting an authentication strategy during publication, the resulting applications and API keys are tied to the developers and traffic in that region.

## {{site.konnect_short_name}} application auth plugin

When you select an authentication strategy during [API publication](/dev-portal/apis) to a Dev Portal, {{site.konnect_short_name}} automatically configures the **{{site.konnect_short_name}} application Auth** plugin on the linked Gateway Service.

The KAA plugin enforces authentication using one of the following modes:
* Key authentication (`key-auth`)
* OpenID Connect (`oidc`)
* Dynamic Client Registration (DCR) (coming soon)

If no Gateway Service is linked at the time of configuration, the settings are saved and applied once a service is linked. If a service is later unlinked, the plugin is removed and applied to the next linked service.


## Dev Portal Security Settings

Navigate to **Settings > Security** in your Dev Portal to manage registration flows.

* **Private Portals**:
  * User Authentication is enabled by default.
  * Default application Auth Strategy is `key-auth`.

* **Public content with restricted access**:
  * Use visibility settings to show public Pages or APIs to anonymous users while restricting actions to logged-in users.

### Configuration Steps

1. **Enable User Authentication**  
   Allows developers to register applications.

1. **(Optional) Enable Role-Based Access Control (RBAC)**  
   Use Teams and Roles to restrict API and page access.

1. **(Optional) Enable Auto Approve**  
   Automatically approves new developers and applications.

1. **(Optional) Set Default Auth Strategy**  
   Sets the strategy used for new APIs by default (does not retroactively change existing APIs).
