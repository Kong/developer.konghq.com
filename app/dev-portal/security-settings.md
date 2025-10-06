---
title: Dev Portal access and authentication settings
content_type: reference
layout: reference

products:
    - dev-portal
tags:
  - access-control
  - authentication

api_specs:
  - konnect/portal-management

works_on:
    - konnect

search_aliases:
  - Portal

breadcrumbs:
  - /dev-portal/

description: "Security settings help you configure visibility and access control for developers accessing your Dev Portal."

related_resources:
  - text: Dev Portal settings
    url: /dev-portal/portal-settings/
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: Publish APIs with Dev Portal
    url: /service-catalog/apis/
  - text: Custom domains
    url: /dev-portal/custom-domains/
---

The Dev Portal security settings allow for visibility and access control around developers accessing your Dev Portal. To configure these settings, navigate to Dev Portal in the {{site.konnect_short_name}} UI, click a Dev Portal, and then click **Settings** in the sidebar.

{:.info}
> To adjust security settings for Dev Portal admins and users, see [{{site.konnect_short_name}} organization settings](/konnect-platform/authentication/).

## Default visibility

When new APIs or pages are created, the specified default visibility will be used. When publishing these items, these defaults can be changed as well. 

* Private: Registered and approved developer must be logged into to view the asset
* Public: Visible to anonymous users browsing the Dev Portal

{:.info}
> Changing the default visibility only affects new APIs or pages. It does not retroactively change the visibility of existing APIs or pages.

## User authentication

Enabling user authentication will allow anonymous users browsing the Dev Portal to register for a developer account. 

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
{{site.konnect_short_name}}'s built-in authentication provider is used by default. This option generates API keys for developers.

OIDC or SAML providers can be configured as integrated IdP providers.

Learn more about configuring IdPs in [Self-service developer & application registration](/dev-portal/self-service/).

### Developer and application approvals

{:.info}
> {% new_in 3.6 %} An API must be linked to a {{site.konnect_short_name}} Gateway Service to be able to restrict access to your API with authentication strategies.

Registration of developer accounts and creation of applications both require approval by Dev Portal admins by default. These approvals are managed in [Access and Approvals](/dev-portal/self-service/#developer-and-application-approvals).

#### Auto approve developers

The following explains the behavior when auto-approval for developers is configured:
* Enabled: Anyone can sign up for a developer account without any further approval process. 
* Disabled: Dev Portal admins have to approve any new sign up in [Access and Approvals](/dev-portal/self-service/#developer-and-application-approvals/).

#### Auto approve applications 

The following explains the behavior when auto-approval for applications is configured:
* Enabled: When any approved developer creates an Application, it will be automatically approved and created. 
  * Once an application is approved, the developer will be able to use it to create API Keys. 
* Disabled: Dev Portal admins have to approve any new Applications in [Access and Approvals](/dev-portal/self-service/#developer-and-application-approvals) before a developer can create API Keys.

### Dev Portal role-based access control

When RBAC is enabled for a Dev Portal, the option to configure API access policies for developers will be available when [publishing](/service-catalog/apis/#publish-your-api-to-dev-portal) the API to a portal. Otherwise, any logged in developer can see any published API that is set to `Visibility: public`.

### Authentication strategy and creating API keys

{:.info}
> {% new_in 3.6 %} An API must be linked to a {{site.konnect_short_name}} Gateway Service to be able to restrict access to your API with authentication strategies.

Authentication strategies determine how [published APIs](/service-catalog/apis/#publish-your-api-to-dev-portal) are authenticated, and how developers create API Keys. 

Authentication strategies automatically configure the {{site.konnect_short_name}} Gateway Service by enabling the {{site.konnect_short_name}} Application Auth (KAA) plugin on the [Gateway Service linked to the API](/service-catalog/apis/#gateway-service-link). The KAA plugin can only be configured from the associated Dev Portal and not the {{site.konnect_short_name}} Gateway Manager.

#### Default application authentication strategy 

Determines the default authentication strategy applied to an API as it is published to a portal. Changing this default will not retroactively change any previously [published APIs](/service-catalog/apis/#publish-your-api-to-dev-portal).

To create a new application authentication strategy, see [Application Auth](/dev-portal/application-registration).

{:.info}
> The authentication strategy only affects the hosted Service and does not affect developers browsing the Dev Portal from viewing APIs. To change visibility of APIs in the Dev Portal, see [Default Visibility](#default-visibility) and [Role-Based Access Control](#role-based-access-control).

<!--
### Kong Dev Portal API 

```
PATCH /portals/{portalId}
Default_application_auth_strategy_id: null (none) or auth strategy uuid
```
-->