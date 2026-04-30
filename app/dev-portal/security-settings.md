---
title: "{{site.dev_portal}} access and authentication settings"
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

description: "Security settings help you configure visibility and access control for developers accessing your {{site.dev_portal}}."

related_resources:
  - text: "{{site.dev_portal}} settings"
    url: /dev-portal/portal-settings/
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: Publish APIs with {{site.dev_portal}}
    url: /catalog/apis/
  - text: Custom domains
    url: /dev-portal/custom-domains/
---

The {{site.dev_portal}} security settings allow for visibility and access control around developers accessing your {{site.dev_portal}}. To configure these settings, navigate to {{site.dev_portal}} in the {{site.konnect_short_name}} UI, click a {{site.dev_portal}}, and then click **Settings** in the sidebar.

{:.info}
> To adjust security settings for {{site.dev_portal}} admins and users, see [{{site.konnect_short_name}} organization settings](/konnect-platform/authentication/).

## Default visibility

When new APIs or pages are created, the specified default visibility will be used. When publishing these items, these defaults can be changed as well. 

* Private: Registered and approved developer must be logged into to view the asset
* Public: Visible to anonymous users browsing the {{site.dev_portal}}

{:.info}
> Changing the default visibility only affects new APIs or pages. It does not retroactively change the visibility of existing APIs or pages.

## User authentication

Enabling user authentication will allow anonymous users browsing the {{site.dev_portal}} to register for a developer account. 

User authentication must be enabled to configure any further settings related to identity providers, RBAC, developer & application registration, or specifying application auth strategies and API keys.

<!--
### Kong {{site.dev_portal}} API

```
PATCH /portals/{portalId}
authentication_enabled: true|false
```
-->

### Identity providers

Identity providers (IdPs) manage authentication of developers signing into the {{site.dev_portal}}. 
{{site.konnect_short_name}}'s built-in authentication provider is used by default. This option generates API keys for developers.

OIDC or SAML providers can be configured as integrated IdP providers.

Learn more about configuring IdPs in [Self-service developer & application registration](/dev-portal/self-service/).

### Developer and application approvals

{:.info}
> {% new_in 3.6 %} An API must be linked to a {{site.konnect_short_name}} Gateway Service to be able to restrict access to your API with authentication strategies.

Registration of developer accounts and creation of applications both require approval by {{site.dev_portal}} admins by default. These approvals are managed in [Access and Approvals](/dev-portal/self-service/#developer-and-application-approvals).

#### Auto approve developers

The following explains the behavior when auto-approval for developers is configured:
* Enabled: Anyone can sign up for a developer account without any further approval process. 
* Disabled: {{site.dev_portal}} admins have to approve any new sign up in [Access and Approvals](/dev-portal/self-service/#developer-and-application-approvals/).

#### Auto approve applications 

The following explains the behavior when auto-approval for applications is configured:
* Enabled: When any approved developer creates an Application, it will be automatically approved and created. 
  * Once an application is approved, the developer will be able to use it to create API Keys. 
* Disabled: {{site.dev_portal}} admins have to approve any new Applications in [Access and Approvals](/dev-portal/self-service/#developer-and-application-approvals) before a developer can create API Keys.

### {{site.dev_portal}} role-based access control

When RBAC is enabled for a {{site.dev_portal}}, the option to configure API access policies for developers will be available when [publishing](/catalog/apis/#publish-your-api-to-dev-portal) the API to a portal. Otherwise, any logged in developer can see any published API that is set to `Visibility: public`.

### Authentication strategy and creating API keys

{:.info}
> {% new_in 3.6 %} An API must be linked to a {{site.konnect_short_name}} Gateway Service to be able to restrict access to your API with authentication strategies.

Authentication strategies determine how [published APIs](/catalog/apis/#publish-your-api-to-dev-portal) are authenticated, and how developers create API Keys. 
When you link an API to a Gateway, you have two options:
* Link to a single Gateway Service
* Link to a control plane

The following table can help you decide which option to pick:

{% table %}
columns:
  - title: Single Gateway Service
    key: kaa
  - title: Control plane
    key: ace
rows:
  - title: Plugin used
    kaa: "{{site.konnect_short_name}} Application Auth (KAA) plugin (automatically applied)"
    ace: "[Access Control Enforcement plugin](/plugins/ace/)"
  - title: "{{site.base_gateway}} version"
    kaa: "{% new_in 3.6 %}"
    ace: "{% new_in 3.13 %}"
  - title: "Can be used with declarative configuration"
    kaa: "No, because the plugin is applied automatically"
    ace: "Yes, because you must configure the plugin"
{% endtable %}

Authentication strategies automatically configure the {{site.konnect_short_name}} Gateway Service by enabling the {{site.konnect_short_name}} Application Auth (KAA) plugin on the [Gateway Service linked to the API](/catalog/apis/#gateway-service-link). The KAA plugin can only be configured from the associated {{site.dev_portal}} and not from API Gateway.

#### Default application authentication strategy 

Determines the default authentication strategy applied to an API as it is published to a portal. Changing this default will not retroactively change any previously [published APIs](/catalog/apis/#publish-your-api-to-dev-portal).

To create a new application authentication strategy, see [Application Auth](/dev-portal/application-registration).

{:.info}
> The authentication strategy only affects the hosted Service and does not affect developers browsing the {{site.dev_portal}} from viewing APIs. To change visibility of APIs in the {{site.dev_portal}}, see [Default Visibility](#default-visibility) and [Role-Based Access Control](#role-based-access-control).

<!--
### Kong {{site.dev_portal}} API 

```
PATCH /portals/{portalId}
Default_application_auth_strategy_id: null (none) or auth strategy uuid
```
-->

## Specify IP addresses that can connect to your {{site.dev_portal}}

You can specify an IP address or a range of IP addresses that are allowed to connect to a {{site.dev_portal}} through its supported interfaces. 
This includes the UI, the {{site.konnect_short_name}} [APIs](/konnect-api/), and [Terraform](/terraform/).
This **does not** restrict who can access the {{site.dev_portal}} settings, configuration, and Portal Editor in {{site.konnect_short_name}}.

This IP allow list applies to all {{site.dev_portal}} communication that goes through the Admin API.

{:.warning}
> **Important:** 
> * Any IP addresses that aren't allow listed won't be able to access the {{site.dev_portal}}, including your own.
> * If you're configuring IP allow list for the first time, it will take effect in up to a minute. If you're editing existing IP allow list values, the changes will take effect after several minutes.
> * {{site.konnect_short_name}} favors IPs over IPv6, and not the IPv4. If your network has dual stack support (supports IPv4 and IPv6), we recommend configuring the IP the network uses if you're using IPv4 and IPv6. If you aren't sure or your network path isn't explicitly controlled by you, its best to enter both.


To configure an IP allow list for a {{site.dev_portal}}, do one of the following:

{% navtabs "ip-allow-list" %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.dev_portal}}**](https://cloud.konghq.com/portals/).
1. Click your {{site.dev_portal}}.
1. In the {{site.dev_portal}} sidebar, click **Settings**.
1. Click the **Security** tab.
1. For IP allow list settings, click **Configure**.
1. In the **IP range** field, enter a single IP or an IP range in CIDR notation. 
   For example, `192.0.2.1` or `192.0.2.0/24`.
1. To add another IP or IP range, click **Add IP address**.
1. Enable **IP allow list status** to enable the {{site.dev_portal}} allow list.
1. Click **Create**.
{% endnavtab %}
{% navtab "API" %}
1. To configure your {{site.dev_portal}} IP allow list, send a POST request to the `/portals/$DEV_PORTAL_ID/ip-allow-list` endpoint:
{% capture set-allow-list %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/ip-allow-list
status_code: 201
region: us
method: POST
body:
  allowed_ips:
  - 192.168.1.1
  - 192.168.1.0/22
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ set-allow-list | indent: 3 }}


   {:.danger}
   > **Allowlist your current IP:** Make sure your current IP is added to the allow list otherwise you'll lose access to {{site.dev_portal}}.

1. To enable your {{site.dev_portal}} IP allow list, send a PATCH request to the `/portals/$DEV_PORTAL_ID` endpoint:
{% capture enable-allow-list %}   
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID
status_code: 200
region: us
method: PATCH
body:
  sipr_enabled: true
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ enable-allow-list | indent: 3 }}
{% endnavtab %}
{% endnavtabs %}
