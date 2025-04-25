---
title: Security settings
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
  - text: Custom pages
    url: /dev-portal/custom-pages/
---

Settings allow for visibility and access control around Developers accessing your Dev Portal. 

{:.info}
> To adjust security settings for Dev Portal admins and users, see [{{site.konnect_short_name}} organization settings](/konnect-authentication/).

## Default visibility

When new APIs or pages are created, the specified default visibility will be used. When publishing these items, these defaults can be changed as well. 

* Private: Registered and approved developer must be logged into to view the asset
* Public: Visible to anonymous users browsing the Dev Portal

{:.info}
> Changing the default Visibility only affects new APIs or pages. It does not retroactively change the visibility of existing APIs or pages.

## User authentication

Enabling user authentication will allow anonymous users browsing the Portal to register for a developer account. 

User authentication must be enabled to configure any further settings related to identity providers, RBAC, developer & application registration, or specifying application auth strategies and API keys.

<!--
### Kong Dev Portal API

```
PATCH /portals/{portalId}
authentication_enabled: true|false
```
-->

### Identity providers

Identity providers (IdPs) manage authentication of developers signing into the Dev Portal. 
{{site.konnect_short_name}}'s built-in authentication provider is used by default. This option generates API keys for Developers.

OIDC or SAML providers can be configured as integrated IdP providers.

Learn more about configuring IdPs in [Self-service developer & application registration](/dev-portal/application-registration/).

### Developer & application approvals

{:.info}
> An API must be linked to a {{site.konnect_short_name}} Gateway Service (version 3.6+) to be able to restrict access to your API with authentication strategies.

Registration of developer accounts and creation of applications both require approval by Portal admins by default. These approvals are managed in [Access and Approvals](/dev-portal/access-and-approval/).

#### Auto approve developers
* Enabled: Anyone can sign up for a Developer account without any further approval process. 
* Disabled: Portal admins have to approve any new sign up in [Access and Approvals](/dev-portal/access-and-approval/).

#### Auto approve applications 
* Enabled: When any approved Developer creates an Application, it will be automatically approved and created. 
  * Once an application is approved, the developer will be able to use it to create API Keys. 
* Disabled: Portal admins have to approve any new Applications in [Access and Approvals](/dev-portal/access-and-approval/) before a Developer can create API Keys.

### Role-Based Access Control

When RBAC is enabled for a Portal, the option to configure API access policies for Developers will be available when [publishing](/dev-portal/publishing/) the API to a portal. Otherwise, any logged in Developer can see any published API that is set to `Visibility: public`.

### Authentication strategy and creating API keys

{:.info}
> An API must be linked to a {{site.konnect_short_name}} Gateway Service (version 3.6+) to be able to restrict access to your API with Authentication Strategies.

Authentication strategies determine how [published APIs](/dev-portal/publishing/) are authenticated, and how Developers create API Keys. 

Authentication strategies automatically configure the {{site.konnect_short_name}} Gateway service by enabling the {{site.konnect_short_name}} Application Auth (KAA) plugin on the [Gateway service linked to the API](/dev-portal/apis/#gateway-service-link). The KAA plugin can only be configured from the associated Dev Portal and not the {{site.konnect_short_name}} Gateway Manager.

#### Default application authentication strategy 

Determines the default authentication strategy applied to an API as it is published to a portal. Changing this default will not retroactively change any previously [published APIs](/dev-portal/publishing).

To create a new application authentication strategy, see [Application Auth](/dev-portal/application-registration).

{:.info}
> The authentication strategy only affects the hosted Service and does not affect developers browsing the Portal from viewing APIs. To change visibility of APIs in the Portal, see [Default Visibility](#default-visibility) and [Role-Based Access Control](#role-based-access-control).

<!--
### Kong Dev Portal API 

```
PATCH /portals/{portalId}
Default_application_auth_strategy_id: null (none) or auth strategy uuid
```
-->