---
title: "Developer self-service and application registration"
content_type: reference
layout: reference

products:
  - dev-portal
tags:
  - application-registration
  - authentication

works_on:
  - konnect

breadcrumbs:
  - /dev-portal/

api_specs:
  - konnect/portal-management

description: "Enable self-service registration flows for developers and applications using authentication strategies and {{site.konnect_short_name}} application auth."

related_resources:
  - text: "{{site.dev_portal}} developer sign-up"
    url: /dev-portal/developer-signup/
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: "{{site.dev_portal}} Dynamic Client Registration"
    url: /dev-portal/dynamic-client-registration/

faqs:
  - q: |
      {% include faqs/api-app-reg-override.md section='question' %}
    a: |
      {% include faqs/api-app-reg-override.md section='answer' %}
---

{{site.konnect_short_name}} {{site.dev_portal}} provides flexible options for controlling access to content and APIs.
When combined with a [Gateway Service](/gateway/entities/service/), developers visiting a {{site.dev_portal}} can sign up, create an application, register it with an API, and retrieve API keys without intervention from {{site.dev_portal}} administrators.

Developer self-service consists of two main components:
* **User authentication:** Allows users to access your {{site.dev_portal}} by logging in. You can further customize what logged in users can see using RBAC.
* **Application registration:** Allows developers to use your APIs using credentials and create applications for them.

## Enable developer self-service

To enable developer self-service, do the following:
1. Enable user authentication by navigating to **Settings > Security** in your {{site.dev_portal}}.

   Developer sign ups and application creation require admin approval by default, which can also be configured in the {{site.dev_portal}} security settings.

   For private {{site.dev_portal}}s, user authentication is enabled by default, and the default application auth strategy is key authentication.
1. Configure an [application authentication strategy](/dev-portal/auth-strategies/) by navigating to **Settings > Security**.
1. Optional: Enable [application sharing](#share-applications-with-a-team) for developer teams by navigating to your {{site.dev_portal}} in {{site.konnect_short_name}} and going to **Access and approvals > Teams**. Click the team, go to **Settings** and enable **Allow team to own applications**.
1. Link an [API to a Gateway Service](/catalog/apis/#gateway-service-link).

   This is required to enforce auth strategies.
1. Publish an [API to a {{site.dev_portal}}](/catalog/apis/#publish-your-api-to-dev-portal).
1. Select an authentication strategy when publishing the API to a {{site.dev_portal}}.
1. For public content with restricted access, use [visibility settings](/dev-portal/pages-and-content/#page-visibility-and-publishing) to show public pages or APIs to anonymous users while restricting actions to logged-in users.

## User authentication

Enabling user authentication requires users to register with the {{site.dev_portal}}.
You can decide which pages remain public and which ones require authentication.

{{site.dev_portal}} supports the following user authentication types:
* Basic authentication
* OIDC
* SAML

Additionally, you can enable [RBAC](/dev-portal/developer-rbac/) from your {{site.dev_portal}}'s security settings to control who can view or view and consume APIs in your {{site.dev_portal}}.
When RBAC is enabled, any {{site.dev_portal}} teams and roles you apply to a developer will control their access.

To get started with user authentication, see the following how-tos:
* [Configure {{site.dev_portal}} SSO](/dev-portal/sso/)
* [{{site.dev_portal}} IdP team mappings](/dev-portal/team-mapping/)
* [{{site.dev_portal}} RBAC](/dev-portal/developer-rbac/)

## Application authentication strategies

Application authentication allows developers to authenticate with your API using credentials.
Developers use the credentials from the authentication strategy when they use an API from your {{site.dev_portal}}.
You can define and reuse multiple authentication strategies for different APIs and {{site.dev_portal}}s.

When you select an [authentication strategy](/dev-portal/auth-strategies/) during [API publication](/catalog/apis/) to a {{site.dev_portal}}, {{site.konnect_short_name}} automatically applies the strategy to the linked Gateway Service.

{{site.dev_portal}} supports the following authentication strategies:
* [Key authentication (`key-auth`)](/dev-portal/auth-strategies/#configure-the-key-auth-strategy)
* [OpenID Connect (`oidc`)](/dev-portal/auth-strategies/#dev-portal-oidc-authentication)
* [Dynamic Client Registration (DCR)](/dev-portal/dynamic-client-registration/)

If a Gateway Service isn't associated with the API when you choose an authentication strategy, the settings are saved and applied once a Service is linked.
If a Service is later unlinked, the authentication strategy is applied to the next linked Service.

To automatically create and manage {{site.dev_portal}} applications using Dynamic Client Registration, see the following guides:

{% html_tag type="div" css_classes="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3" %}
{% icon_card icon="okta.svg" title="Okta" cta_url="/how-to/okta-dcr/" %}
{% icon_card icon="azure.svg" title="Azure AD" cta_url="/how-to/azure-ad-dcr/" %}
{% icon_card icon="third-party/auth0.svg" title="Auth0" cta_url="/how-to/auth0-dcr/" %}
{% icon_card icon="third-party/curity.svg" title="Curity" cta_url="/how-to/curity-dcr/" %}
{% endhtml_tag %}

## Developer and application approvals

You can choose to auto approve developers and applications or require admin approval for developers and applications by navigating to **Settings** and the **Security** tab in your {{site.dev_portal}} settings.

If your settings require developer or application approval, you can manage approvals by navigating to **Access and approvals** in the sidebar. You need the [API Registration Approver and Portal Viewer role](/konnect-platform/teams-and-roles/#dev-portal) assigned to the Teams that control the APIs to approve these.
Additionally, you can add developers to teams by clicking on the settings menu next to the name of the developer.

Once approved, developers can create applications and view APIs, and the application can generate credentials to use the APIs.

Applications and API keys are specific to a [geographic region](/konnect-platform/geos/).
When you enable application registration by selecting an authentication strategy during publication, the resulting applications and API keys are tied to the developers and traffic in that region.

### Share applications with a team

You can assign an application to a team so that all members of that team share ownership of the application.
Any team member can edit, manage, and use the application.
Apps shared by a team appear in each member's apps in the {{site.dev_portal}}.
Team membership and roles are managed via [{{site.dev_portal}} teams and roles](/dev-portal/developer-rbac/).

This is useful in cases such as when a developer leaves your organization.
With team application sharing, the team retains uninterrupted access to the application.

Important considerations:
* All members of the team that owns an application receive full ownership access.
* Applications can only be transferred to teams that have [API Consumer](/dev-portal/developer-rbac/) access for every API currently registered by the application.
  Similarly, you can only register APIs to team-owned applications if everyone in the team has access to the API.
  This is true even if an individual team member has broader access through other teams.

To enable team application sharing, navigate to your {{site.dev_portal}} in {{site.konnect_short_name}} and click **Access and approvals > Teams**. Click the relevant team, go to **Settings**, and enable **Allow team to own applications**.
To transfer ownership of an application to either a developer or team, navigate to the app and from the **Actions** dropdown menu, select "Transfer ownership".

For more information about how to configure {{site.dev_portal}} developer teams, see [{{site.dev_portal}} RBAC](/dev-portal/developer-rbac/).
For more information about the developer experience, see [{{site.dev_portal}} developer sign-up](/dev-portal/developer-signup/#2-create-an-application).

### Limitations

Keep the following limitations in mind for developers and applications:
* Each developer can create a maximum of 500 applications.
* Each application can have a maximum of 20 API keys.
* Each API that uses the [ACE plugin](/plugins/ace/) can have a maximum of 1,000 operations.
* API Packages have a per-request PATCH limit of 100.

## Apply plugins to applications {% new_in 3.15 %}

You can apply {{site.base_gateway}} plugins to your {{site.dev_portal}} applications.
This lets you enforce business logic, such as rate limiting or IP restriction, on the credentials that an application uses to access your APIs.

The following table shows common use cases for applying plugins to applications:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Plugin
    key: plugin
rows:
  - use_case: "Enforce request quotas on the credentials an application uses."
    plugin: "[Rate Limiting](/plugins/rate-limiting/) or [Rate Limiting Advanced](/plugins/rate-limiting-advanced/)"
  - use_case: "Ensure only requests from a partner's known IP ranges can use their application credentials."
    plugin: "[IP Restriction](/plugins/ip-restriction/)"
  - use_case: "Automatically inject a header identifying the partner into every request their application makes, so your upstream can route or log by customer without trusting client-supplied headers."
    plugin: "[Request Transformer](/plugins/request-transformer/)"
{% endtable %}
<!--vale on-->

Plugins can be applied to an application by either linking the application to an existing Consumer in {{site.base_gateway}} or applying the plugin via conditional execution logic to the associated principal.
When a developer creates an application, {{site.dev_portal}} automatically creates a {{site.identity}} principal for this application. 
This principal entity then helps link the application to an existing Consumer entity in {{site.base_gateway}}.
{{site.identity}} doesn't store any credentials for applications. It is only used for mapping an application to a Consumer.

You can apply plugins to an application in two different ways:

<!--vale off-->
{% table %}
columns:
  - title: Method
    key: method
  - title: Existing Consumers for {{site.dev_portal}} applications
    key: existing_consumers
  - title: Plugin mapped to
    key: mapped_to
  - title: Description
    key: description
rows:
  - method: "Conditional plugin execution"
    existing_consumers: "No"
    mapped_to: "Principal"
    description: "Use [conditional plugin execution](/gateway/configure-conditional-plugin-execution/) with an expression that references the application's `principal.id`. You can manage the principal configuration in {{site.identity}} and the plugin configuration in Gateway Manager."
  - method: "Consumer-scoped plugins"
    existing_consumers: "Yes"
    mapped_to: "Consumer"
    description: "[Map the application to an existing Gateway Consumer](#map-an-application-to-a-consumer), then configure Consumer-scoped plugins on that Consumer. This is a common starting point if you already have Consumers configured."
{% endtable %}
<!--vale on-->

### Apply a plugin to an application using a {{site.identity}} principal

This method applies the plugin based on the application's principal, without requiring you to map the application to a Gateway Consumer.
The plugin runs whenever a request authenticates as that application, using a [conditional plugin execution](/gateway/configure-conditional-plugin-execution/) expression that references the application's `principal.id`.

In this example, we'll use the [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin, but you can apply any plugin to an application's principal with `principal.id`.

1. List the applications in your portal, filtering by the application's name, and capture its ID as the `PRINCIPAL_ID` variable. Replace `$PORTAL_ID` with your portal ID and `$APPLICATION_NAME` with the name of your application:
{% capture copy-app-id %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/applications?filter%5Bname%5D%5Beq%5D=$APPLICATION_NAME
status_code: 200
region: us
method: GET
capture:
  - variable: PRINCIPAL_ID
    jq: '.data[0].id'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ copy-app-id | indent: 3}}
   The principal ID is the same as the application's ID. 
1. Configure the Rate Limiting Advanced plugin and use a conditional plugin execution expression to apply it to the application's principal. Replace `$CONTROL_PLANE_ID` with the ID of the control plane that your API is linked to:
{% capture apply-plugin %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/
status_code: 201
region: us
method: POST
body:
  name: rate-limiting-advanced
  config:
    limit:
      - 200
    window_size:
      - 1800
    window_type: fixed
    namespace: my-namespace
  condition: 'principal.id == "$PRINCIPAL_ID"'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ apply-plugin | indent: 3}}
Any request that authenticates as this application is now rate limited to 200 requests every 30 minutes.

### Map an application to a Consumer

Mapping an application to a Consumer requires either the [Control Plane Admin or Consumer Admin](/konnect-platform/teams-and-roles/#control-planes) roles, granted for each API instance registered by the application.

{% navtabs "map-consumer" %}
{% navtab "API" %}
To map an application to an existing Consumer, send a `PUT` request to the registration's `consumer` endpoint with the ID of the Gateway Consumer. Replace `$PORTAL_ID`, `$APPLICATION_ID`, `$REGISTRATION_ID`, and `$CONSUMER_ID` with your values:

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/applications/$APPLICATION_ID/registrations/$REGISTRATION_ID/consumer
status_code: 204
region: us
method: PUT
body:
  id: $CONSUMER_ID
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal > Portals**.
1. Click your portal.
1. Click the **Access and approvals** tab.
1. Click the **App Registrations** tab.
1. Click the application you want to link a Consumer to.
1. In the **App Registrations** section, click the action menu icon for the registration.
1. Click **Link Consumer**.
1. From the **Consumer** dropdown menu, select the Consumer you want to link.
   The API must be [linked to a Gateway Service or control plane](/catalog/apis/#allow-developers-to-consume-your-api) to link a Consumer.
1. Click **Link consumer**.
{% endnavtab %}
{% endnavtabs %}

Any plugins that were applied to the Consumer are now applied to the {{site.dev_portal}} application.

### Limitations

Keep the following in mind when you map applications to Consumers or principals:
* Both the [KAA and ACE plugins](/catalog/apis/#allow-developers-to-consume-your-api) look up principals to resolve the Consumer mapped to an application.
* An application maps to a single Consumer (a 1:1 mapping through one principal).
* If you're mapping applications to Consumers, the Consumer must already exist. The {{site.dev_portal}} validates that the Consumer exists on the Gateway before it will be mapped.
* Application registrations for APIs that are linked to the same Gateway Service will share the same effective Consumer mapping.
  Updating the mapping for one registration updates it for all registrations that resolve to the same Gateway context.
* Applying plugins to applications is only available on v3 {{site.dev_portal}}s.
