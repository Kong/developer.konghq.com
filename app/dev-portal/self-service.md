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

### Automate developer creation

You can pre-create developer accounts to provision their team association and API access before they access the {{site.dev_portal}}.

1. To automatically create developers and send them an email to create a password, send a `POST` request to the [`/portals/{portalId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/create-developer):
{% capture create-dev %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/developers
method: POST
status_code: 201
body:
  full_name: "Raina Sovani"
  email: "raina.sovani@example.com"
  status: "approved"
  send_invitation_email: true
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{create-dev | indent: 3}}

1. Copy and export the developer ID:
  ```sh
  export DEVELOPER_ID='YOUR DEVELOPER ID'
  ```

1. Add the developer to an existing team that has the correct roles for the APIs they need access to by sending a `POST` request to the [`/portals/{portalId}/teams/{teamId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/add-developer-to-portal-team):
{% capture add-dev-to-team %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/teams/$TEAM_ID/developers
method: POST
status_code: 201
body:
  id: "$DEVELOPER_ID"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{add-dev-to-team | indent: 3}} 

{:.warning}
> **Logging in to {{site.dev_portal}}s:**
> * **SSO:** If a developer is created in a {{site.dev_portal}} with SSO configured, they must be able to use SSO to log in if their email address is configured in the identity provider. 
>  After they log in, they will automatically be approved. Both OIDC and SAML SSO are supported.
> * **Basic auth:** If a developer is created in a {{site.dev_portal}} with basic auth configured, they must be able to set their password. This can be done one of two ways:
>   * `send_invitation_email: true`: Developers can use the link in the email to set their password.
>   * Developers can click **Forgot password** in the {{site.dev_portal}} UI to set a password, regardless of whether `send_invitation_email` is `true` or `false`.

### Automate application creation

You can automate applications and application registrations on behalf of a developer or team using the {{site.konnect_short_name}} API.
The [authentication strategy](/dev-portal/auth-strategies/) you want to use must be enabled on your {{site.dev_portal}} and your published API.
Key auth credentials can't be automatically created or imported.

1. Create a developer application by sending a `POST` request to the [`/portals/{portalId}/applications` endpoint](/api/konnect/portal-management/v3/#/operations/create-application):
{% capture create-application %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/applications
method: POST
status_code: 201
body:
  name: "KongAir Application"
  description: "A Dev Portal application provisioned for a developer by a Portal Admin."
  auth_strategy_id: "$AUTH_STRATEGY_ID"
  owner:
    id: "$DEVELOPER_ID"
    type: "developer"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{create-application | indent: 3}}
   
   If the application is for a team, configure `owner.type: team` and set `owner.id` to the team ID instead of `$DEVELOPER_ID`.

1. Copy and export the application ID:
  ```sh
  export APPLICATION_ID='YOUR APPLICATION ID'
  ```

1. Create an application registration by sending a `POST` request to the `/portals/{portalId}/applications/{applicationId}/registrations` endpoint:
{% capture create-application-registration %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/applications/$APPLICATION_ID/registrations
method: POST
status_code: 201
body:
  api_id: "$API_ID"
  status: "approved"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{create-application-registration | indent: 3}}
   
   {:.warning}
   > **DCR applications:**
   > If the application will be using a DCR provider with the given auth strategy, your configuration depends on your use case:
   > * You want to create a new DCR application, where the IdP client will be created in the identity provider and assigned a `client_id`. This will be set as the `client_id` of the application and can't be changed moving forward. **Do not** specify `dcr_client_id` or `client_id` in this case. `client_id` will be present in the response.
   > * You want to create an application that is linked to an existing IdP client, but treated as if it was created via the DCR app creation process. This allows you to import existing IdP clients when onboarding your applications into {{site.konnect_short_name}}. In this case, you must specify `dcr_client_id` and `client_id` will be present in the response.

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

### Developer, API, and application registration forms

{% include_cached sections/custom-form-tutorials.md %}

By default, {{site.dev_portal}} collects the following information during registration:
* **Developer registration**: Full name and email address.
* **Application registration**: The application and API being registered. 

If you need to capture more than this, for example a developer's team, company, job title, or their reason for wanting access to an API, you can create a custom form. 
Custom forms let you create a new form with configurable fields for developer registration or per-API application registration.

Use cases for custom forms include:
{% include_cached sections/custom-form-use-cases.md %}

The following field types are available when creating a custom form:
{% include_cached sections/custom-form-field-types.md %}

{% include_cached sections/custom-form-constraints.md %}

#### Create a developer registration custom form

You can only create one developer registration form per {{site.dev_portal}}. 
Once it's published, the custom form replaces the default sign-up form.

{% navtabs "create-developer-form" %}
{% navtab "API" %}
Create a form by sending a `POST` request to the [`/portals/{portalId}/forms` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-form). 
The following example includes the required `full_name`, `email`, and `submit` fields, plus a department dropdown and a terms and conditions acceptance checkbox:
{% capture create-developer-form %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/forms
method: POST
status_code: 201
body:
  type: developer_registration
  status: published
  fields:
    - type: content
      value: "## Tell us about yourself\n\nThis information helps us route your request to the right team."
    - type: text
      name: full_name
      label: Full name
      placeholder: Enter your full name
      required: true
    - type: email
      name: email
      label: Email address
      placeholder: you@example.com
      required: true
    - type: select
      mode: single_select
      name: department
      label: Department
      required: true
      options:
        - value: sales
          label: Sales
        - value: engineering
          label: Engineering
        - value: finance
          label: Finance
    - type: checkbox
      name: agree_terms
      label: I agree to the terms and conditions
      description: "View the [terms](https://example.com/terms)."
      required: true
    - type: submit
      name: submit
      value: Create account
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-developer-form | indent: 3}}

To update the form later, send a `PUT` request to `/v3/portals/{portalId}/forms/{formId}`. 
This replaces the default form, so any field omitted from the `fields` array is removed.
{% endnavtab %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal > Portals**.
1. Click your {{site.dev_portal}}.
1. Click the **Portal Editor** tab.
1. In the Portal Editor sidebar, click the forms icon.
1. Click **New form**.
1. Select **Portal developer registration**.
1. Click **Create**.
1. On the form's Fields page, click **Add** to add additional fields, or click a field to edit it.
1. Click **Save and return to form**.
1. Click **Save**.
1. When you want to publish the custom form, click **Publish**.

The **Full name** and **Email address** fields are added automatically and are required. You can edit these fields, but you can't delete them. Any other fields you add can be edited or deleted.
{% endnavtab %}
{% endnavtabs %}

#### Create an API application registration custom form

You can create multiple API registration forms, and assign a different one to each API.

{% navtabs "create-api-form" %}
{% navtab "API" %}
1. Create a form by sending a `POST` request to the [`/portals/{portalId}/forms` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-form). Set `type` to `api_registration`, supply a unique `name` for the form, and include a `text` field named `api_id`:
{% capture create-api-form %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/forms
method: POST
status_code: 201
body:
  type: api_registration
  name: payments-api-registration
  status: published
  fields:
    - type: text
      name: api_id
      label: API
      required: true
    - type: text
      name: company_name
      label: Company name
      required: true
    - type: select
      mode: single_select
      name: use_case
      label: Use case
      required: true
      options:
        - value: analytics
          label: Analytics
        - value: monitoring
          label: Monitoring
    - type: submit
      name: submit
      value: Request access
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-api-form | indent: 3}}
   The `api_id` and `submit` fields are required for every API registration form.
1. Copy and export the form ID from the response:
   ```sh
   export FORM_ID='YOUR FORM ID'
   ```
1. Link the form to an API by sending a `PUT` request to the [`/apis/{apiId}/publications/{portalId}` endpoint](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal), setting `form_id` to the form's ID:
{% capture link-api-form %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$DEV_PORTAL_ID
method: PUT
status_code: 200
body:
  form_id: $FORM_ID
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ link-api-form | indent: 3}}
   For the rest of the settings required to publish an API, see [Publish your API to {{site.dev_portal}}](/catalog/apis/#publish-your-api-to-dev-portal).
{% endnavtab %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal > Portals**.
1. Click your {{site.dev_portal}}.
1. Click the **Portal Editor** tab.
1. In the Portal Editor sidebar, click the forms icon.
1. Click **New form**.
1. Select **API registration**.
1. In the **Form name** field, enter a name for the form.
1. Click **Create**.
1. On the form's Fields page, click **Add** to add additional fields, or click a field to edit it.
1. Click **Save and return to form**.
1. Click **Save**.
1. When you want to publish the custom form, click **Publish**.

A submit field is added automatically and is required. You don't need to add or configure an `api_id` field yourself in the UI.

To link the form to an API:
1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal > Portals**.
1. Click your {{site.dev_portal}}.
1. Click the **Published APIs** tab.
1. Find the API, click its action menu, and click **Edit publication**.
1. Click the **Require API registration form** checkbox.
1. From the **Form** dropdown, then select your custom form. 
1. Click **Save**.
{% endnavtab %}
{% endnavtabs %}

#### View collected form data

Submitted form answers appear alongside the developer or application registration they belong to:
* Developer registration answers are available on the developer's detail page under **Access and approvals > Developers** in {{site.konnect_short_name}}, and through the `additional_data` property on the [`/portals/{portalId}/developers`](/api/konnect/portal-management/v3/#/operations/list-portal-developers) and [`/portals/{portalId}/developers/{developerId}`](/api/konnect/portal-management/v3/#/operations/get-developer) endpoints.
* API registration answers are available on the registration's detail page under **Access and approvals > App Registrations**, and through the `additional_data` property on the [`/portals/{portalId}/application-registrations`](/api/konnect/portal-management/v3/#/operations/list-registrations) endpoint.

{{site.dev_portal}} doesn't have a webhook for new registrations or form submissions, so if you want to react to new submissions automatically, poll these endpoints on an interval instead. 
For example, you could filter on `status=pending` and track the last submission you've already processed.

If you later edit or delete a field or form, previously collected answers aren't affected. 
Each submitted answer is stored with a snapshot of its field label and type from the moment it was submitted, so it stays visible on the response detail view even after the field or form it came from no longer exists.

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

{:.info}
> Since application to Consumer linking uses [{{site.identity}}](/identity/) in the backend, there may be some latency impact to the first request.

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

1. List the applications in your {{site.dev_portal}}, filtering by the application's name, and capture its ID as the `PRINCIPAL_ID` variable. Replace `$PORTAL_ID` with your {{site.dev_portal}} ID and `$APPLICATION_NAME` with the name of your application:
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
1. Click your {{site.dev_portal}}.
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
* Since application to Consumer linking uses {{site.identity}} in the backend, there may be some [latency impact](/identity/principals/#can-using-principals-to-authenticate-introduce-additional-latency-over-consumers) to the first request.
