---
title: Self-service developer and application registration
description: 'Enable self-service registration flows for developers and applications using authentication strategies and {{site.konnect_short_name}} application auth.'
content_type: reference
layout: reference
products:
  - dev-portal
beta: true
tags:
  - application-registration
  - authentication
  - beta

search_aliases:
  - Portal

works_on:
  - konnect

api_specs:
  - konnect/portal-management

breadcrumbs:
  - /dev-portal/

related_resources:
  - text: SSO reference
    url: /dev-portal/sso/
  - text: Auth strategies
    url: /dev-portal/auth-strategies/
  - text: Developer sign-up
    url: /dev-portal/developer-signup/
  - text: Configure Dynamic Client Registration with Okta
    url: /how-to/okta-dcr/
  - text: Configure Dynamic Client Registration with Curity
    url: /how-to/curity-dcr/
  - text: Configure Dynamic Client Registration with Auth0
    url: /how-to/auth0-dcr/
  - text: Configure Dynamic Client Registration with Azure
    url: /how-to/azure-dcr/

---

{{site.konnect_short_name}} Dev Portal provides flexible options for controlling access to content and APIs. 
When combined with a [Gateway Service](/gateway/entities/service/), developers visiting a Dev Portal can sign up, create an application, register it with an API, and retrieve API keys without intervention from Dev Portal administrators. 

Developer sign ups and application creation require admin approval by default, which can be adjusted through the {{site.konnect_short_name}} UI in **Settings > Security**.

Application registration is enabled by:
* Enabling user authentication
* Linking an [API to a Gateway Service {% new_in 3.6 %}](/dev-portal/apis/#gateway-service-link)
  
  This is required to enforce auth strategies.
* Publishing an [API to a Dev Portal](/dev-portal/publishing/)
* Selecting an authentication strategy when publishing the API to a Dev Portal
  
  This only applies to new APIs, it doesn't retroactively change existing APIs.

## Enable self-service app registration

Navigate to **Settings > Security** in your Dev Portal to manage registration flows.

For private portals, user authentication is enabled by default, and the default application Auth Strategy is `key-auth`.

For public content with restricted access, use visibility settings to show public Pages or APIs to anonymous users while restricting actions to logged-in users.

## Region-specific applications

Applications and API keys are specific to a [geographic region](/konnect-platform/geos/). 
When you enable application registration by selecting an authentication strategy during publication, the resulting applications and API keys are tied to the developers and traffic in that region.

## {{site.konnect_short_name}} application auth plugin

When you select an [authentication strategy](/dev-portal/auth-strategies/) during [API publication](/dev-portal/apis/) to a Dev Portal, {{site.konnect_short_name}} automatically configures the **{{site.konnect_short_name}} application auth** (KAA) plugin on the linked Gateway Service.

The KAA plugin enforces authentication using one of the following modes:
* [Key authentication (`key-auth`)](/dev-portal/auth-strategies/#configure-the-key-auth-strategy)
* [OpenID Connect (`oidc`)](/dev-portal/auth-strategies/#dev-portal-oidc-authentication)
* [Dynamic Client Registration (DCR)](/dev-portal/dynamic-client-registration/)

If no Gateway Service is linked at the time of configuration, the settings are saved and applied once a Service is linked. 
If a Service is later unlinked, the plugin is removed and applied to the next linked Service.
