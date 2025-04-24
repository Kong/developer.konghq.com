---
title: Security Settings
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


settings allow for visibility and access control around Developers accessing your Dev Portal. 

{:.note}
> *To adjust security settings for Dev Portal admin/users, see [{{site.konnect_short_name}} Organization settings](/konnect-platform/konnect-authentication/)*.



## Default Visibility

 When new APIs or Pages are created, the specified default Visibility will be used. When publishing these items, these defaults can be changed as well. 

 * Private: Registered and approved Developer must be logged into to view the asset
 * Public: Visible to anonymous users browsing the Dev Portal

{:.note}
> *Changing the default Visibility only affects new APIs or Pages. It does not retroactively change the visibility of existing APIs or Pages.*


## User Authentication

Enabling User Authentication will allow anonymous users browsing the portal to register for a Developer account. 

User Authentication must be enabled to configure any further settings related to Identity Providers, RBAC, Developer & Application registration, or specifying Application Auth Strategies. 


## Identity Providers

Identity Providers (IdP) manage authentication of Developers signing into the Dev Portal. 

{{site.konnect_short_name}}'s Built-in authentication provider is used by default. This will generate API keys for Developers.

OIDC or SAML providers can be configured as an integrated IdP provider.

Learn more about configuring IdPs in [Enable Self-Service Developer & Application Registration](/dev-portal/application-registration/)

## Developer & Application Approvals

{:.info}
> *An API must be linked to a {{site.konnect_short_name}} Gateway Service (version 3.6+) to be able to restrict access to your API with Authentication Strategies.*

Registration of Developer accounts and creation of Applications both require approval by portal admins by default. These approvals are managed in [Access and Approvals](/dev-portal/access-and-approval/).

### Auto approve developers
* Enabled: anyone can sign up for a Developer account without any further approval process. 
* Disabled: portal admins will have to approve any new sign up in [Access and Approvals](/dev-portal/access-and-approval/).

### Auto approve applications 
* Enabled: When any approved Developer creates an Application, it will be automatically approved and created. 
  * Once an application is approved, the Developer will be able to use it to create API Keys. 
* Disable: portal admins will have to approve any new Applications in [Access and Approvals](/dev-portal/access-and-approval/) before a Developer can create API Keys.



## Role-Based Access Control

When RBAC is enabled for a Portal, the option to configure API access policies for Developers will be available when [publishing](/dev-portal/publishing/) the API to a portal. Otherwise, any logged in Developer can see any published API that is set to `Visibility: public`.


## Authentication Strategy / Creating API Keys

{:.note}
> *An API must be linked to a {{site.konnect_short_name}} Gateway Service (version 3.6+) to be able to restrict access to your API with Authentication Strategies.*

Authentication strategies determine how [published APIs](/dev-portal/publishing/) are authenticated, and how Developers create API Keys. 

Authentication strategies automatically configure the {{site.konnect_short_name}} Gateway service by enabling the {{site.konnect_short_name}} Application Auth (KAA) plugin on the [Gateway service linked to the API](/dev-portal/apis/#gateway-service-link). The KAA plugin can only be configured from the associated Dev Portal and not the {{site.konnect_short_name}} Gateway Manager.

### Default application authentication strategy 

Determines the default authentication strategy applied to an API as it is published to a portal. Changing this default will not retroactively change any previously [published APIs](/dev-portal/publishing).

To create a new Application Authentication Strategy, see [Application Auth](/dev-portal/application-registration)

{:.note}
> *Authentication strategy only affects the hosted service and does not affect developers browsing the portal from viewing APIs. To change visibility of APIs in the portal, see [Default Visibility](#default-visibility) and [Role-based access control](#role-based-access-control).*

<!--
### Kong Dev Portal API 

```
PATCH /portals/{portalId}
Default_application_auth_strategy_id: null (none) or auth strategy uuid
```
-->

## User Authentication & Role-Based Access Control (RBAC)

Enabling User Authentication will allow anonymous users browsing the portal to register Developer accounts.  User Authentication must be enabled to configure any further settings related to Identity Providers, or Developers creating and registering Applications or issuing API Keys. 

<!--
### Kong Dev Portal API

```
PATCH /portals/{portalId}
authentication_enabled: true|false
```
-->

## Identity Providers (IdP)

Identity Providers handle authentication of Developers signing into the Dev Portal. 
{{site.konnect_short_name}}'s Built-in authentication provider, key auth, is used by default. OIDC or SAML providers can be configured as an integrated IdP provider.

For more information see [{{site.konnect_short_name}} authentication settings](/konnect-platform/konnect-authentication/)*