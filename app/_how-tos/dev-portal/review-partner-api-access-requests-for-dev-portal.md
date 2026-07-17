---
title: Review partner API access requests with {{site.dev_portal}} custom forms
permalink: /how-to/review-partner-api-access-requests-for-dev-portal/
description: Learn how to collect company and business justification details from partner developers before approving Dev Portal and API access, using Dev Portal custom forms.
content_type: how_to
automated_tests: false
products:
    - gateway
    - dev-portal
works_on:
    - konnect
tools:
  - konnect-api
  - deck
entities: []
tags:
    - application-registration
search_aliases:
    - custom forms
    - custom registration forms

tldr:
    q: How do I collect and review extra information from partner developers before approving their API access?
    a: Create a custom developer registration form and API registration form with the {{site.konnect_short_name}} API (`/v3/portals/{portalId}/forms`). Link the API form to your published API, then turn off auto-approve so new sign-ups and registrations are marked as pending until you review the submitted `additional_data`.

prereqs:
  inline:
    - title: "{{site.konnect_product_name}} roles"
      content: |
        To run this tutorial, you need the following [{{site.konnect_short_name}} teams and roles](/konnect-platform/teams-and-roles/):
        - **Portal Admin**: Manage {{site.dev_portal}} settings and custom forms.
        - **API Registration Approver** and **Portal Viewer**: Review and approve developer and application registrations.
      icon_url: /assets/icons/dev-portal.svg
    - title: "{{site.dev_portal}}"
      include_content: prereqs/dev-portal-configure
      icon_url: /assets/icons/dev-portal.svg
    - title: Published API
      include_content: prereqs/publish-api
      icon_url: /assets/icons/dev-portal.svg
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: Developer, API, and application registration forms
    url: /dev-portal/self-service/#developer-api-and-application-registration-forms
  - text: "{{site.dev_portal}} customizations: Custom forms"
    url: /dev-portal/customizations/dev-portal-customizations/#custom-forms
  - text: Automate your API catalog with the Konnect API
    url: /how-to/automate-api-catalog/
  - text: Assign developers to a team with a {{site.dev_portal}} custom sign-up form
    url: /how-to/assign-developers-to-a-team-for-dev-portal/
---

In this tutorial, you'll build both a developer and API registration custom form, turn off auto-approve so new registrations wait for review, and see how the submitted answers show up when you go to approve them.
This can be useful if your company publishes a partner-facing API and you want to only allow users and applications that are from valid partners.
Before a partner's developers get access, you may want to know their company name and job title at sign-up, and a business justification when they register for the API.

## Turn off auto-approve for developers and applications

To review submitted answers before granting access, turn that auto-approve for new developers and application registrations by sending a `PATCH` request to the [`/portals/{portalId}` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal):

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID
method: PATCH
status_code: 200
body:
  auto_approve_developers: false
  auto_approve_applications: false
{% endkonnect_api_request %}
<!--vale on-->

New developers and application registrations now are marked with a `pending` status until you approve them.

## Create a developer registration form

Create a custom form that collects a partner developer's company name and job title, in addition to the required name and email fields, by sending a `POST` request to the [`/portals/{portalId}/forms` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-form):

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/forms
method: POST
status_code: 201
body:
  type: developer_registration
  status: published
  fields:
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
    - type: text
      name: company_name
      label: Company name
      placeholder: Enter your company name
      required: true
    - type: text
      name: job_title
      label: Job title
      placeholder: Enter your job title
      required: true
    - type: submit
      name: submit
      value: Create account
{% endkonnect_api_request %}
<!--vale on-->

The `full_name`, `email`, and `submit` fields are required for every developer registration form. Once published, this form replaces the default sign-up form.

## Create an API registration form

Create a second form that collects a business justification when a partner registers an application for the API, and capture its ID as `$FORM_ID`, by sending a `POST` request to the [`/portals/{portalId}/forms` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-form):

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/forms
method: POST
status_code: 201
body:
  type: api_registration
  name: api-registration
  status: published
  fields:
    - type: text
      name: api_id
      label: API
    - type: textarea
      name: business_justification
      label: Why do you need access to this API?
      placeholder: Describe how you plan to use the API
      required: true
    - type: submit
      name: submit
      value: Request access
capture:
  - variable: FORM_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->

Every API registration form must include a text field named `api_id`. Its value is populated from the API you're registering for, not from something the developer fills in, so don't mark it as required.

## Create an application auth strategy

Partner applications need credentials to call the API. Configure a key auth application authentication strategy, and capture its ID as `$AUTH_STRATEGY_ID`, by sending a `POST` request to the [`/application-auth-strategies` endpoint](/api/konnect/application-auth-strategies/v2/#/operations/create-app-auth-strategy):

<!--vale off-->
{% konnect_api_request %}
url: /v2/application-auth-strategies
method: POST
status_code: 201
body:
  name: API Key Auth
  display_name: API Key Auth
  strategy_type: key_auth
  configs:
    key-auth:
      key_names:
        - apikey
capture:
  - variable: AUTH_STRATEGY_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->

## Link the form and auth strategy to your API

Update your API's publication, setting `form_id` to the form's ID and `auth_strategy_ids` to the auth strategy's ID, by sending a `PUT` request to the [`/apis/{apiId}/publications/{portalId}` endpoint](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal):

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
method: PUT
status_code: 200
body:
  form_id: $FORM_ID
  auth_strategy_ids:
    - $AUTH_STRATEGY_ID
{% endkonnect_api_request %}
<!--vale on-->

## Register a partner developer

Simulate a partner developer signing up with `additional_data` matching your custom fields, and capture their ID as `$DEVELOPER_ID`, by sending a `POST` request to the [`/portals/{portalId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/create-developer):

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/developers
method: POST
status_code: 201
body:
  full_name: Raina Sovani
  email: raina.sovani@example.com
  additional_data:
    company_name: Example Air
    job_title: Partnerships Manager
capture:
  - variable: DEVELOPER_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->

Since auto-approve is off, this developer's `status` is `pending`.

## Create an application and register it for the API

1. Create an application for the developer, and capture its ID as `$APPLICATION_ID`, by sending a `POST` request to the [`/portals/{portalId}/applications` endpoint](/api/konnect/portal-management/v3/#/operations/create-application):
{% capture create-application %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/applications
method: POST
status_code: 201
body:
  name: "Example Air Integration"
  description: "A partner application requesting access to the API."
  auth_strategy_id: "$AUTH_STRATEGY_ID"
  owner:
    id: "$DEVELOPER_ID"
    type: "developer"
capture:
  - variable: APPLICATION_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-application | indent: 3}}
1. Register the application for the API with `additional_data.business_justification`, and capture the registration ID as `$REGISTRATION_ID`, by sending a `POST` request to the [`/portals/{portalId}/applications/{applicationId}/registrations` endpoint](/api/konnect/portal-management/v3/#/operations/create-application-registration):
{% capture register-application %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/applications/$APPLICATION_ID/registrations
method: POST
status_code: 201
body:
  api_id: "$API_ID"
  additional_data:
    business_justification: "We are integrating our booking platform with your API to display real-time availability to our customers."
capture:
  - variable: REGISTRATION_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ register-application | indent: 3}}
   This registration also lands as `pending`.

## Validate

1. Review the submitted answers before approving. Get the developer to see their `additional_data`, by sending a `GET` request to the [`/portals/{portalId}/developers/{developerId}` endpoint](/api/konnect/portal-management/v3/#/operations/get-developer):
{% capture get-developer %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/developers/$DEVELOPER_ID
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ get-developer | indent: 3}}
   The response includes `additional_data.company_name` and `additional_data.job_title`.
1. List application registrations, filtered to pending ones, to see the business justification, by sending a `GET` request to the [`/portals/{portalId}/application-registrations` endpoint](/api/konnect/portal-management/v3/#/operations/list-registrations):
{% capture list-registrations %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/application-registrations?filter%5Bstatus%5D=pending
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ list-registrations | indent: 3}}
   The matching registration includes `additional_data.business_justification`.
1. Once you're satisfied with the answers, approve the developer, by sending a `PATCH` request to the [`/portals/{portalId}/developers/{developerId}` endpoint](/api/konnect/portal-management/v3/#/operations/update-developer):
{% capture approve-developer %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/developers/$DEVELOPER_ID
method: PATCH
status_code: 200
body:
  status: approved
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ approve-developer | indent: 3}}
1. Approve the registration, by sending a `PATCH` request to the [`/portals/{portalId}/applications/{applicationId}/registrations/{registrationId}` endpoint](/api/konnect/portal-management/v3/#/operations/update-application-registration):
{% capture approve-registration %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/applications/$APPLICATION_ID/registrations/$REGISTRATION_ID
method: PATCH
status_code: 200
body:
  status: approved
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ approve-registration | indent: 3}}

### Ideas for using this data

Once you can see submitted company names, job titles, and business justifications, you can do the following:
* Assign the developer to a {{site.dev_portal}} team based on their job title or company, so they are assigned with the right access as soon as they're approved.
* Send a Slack notification to your partnerships channel whenever a registration references a new company.
* Forward `additional_data` to an in-house approvals dashboard or CRM so your team can track and act on requests outside {{site.konnect_short_name}}.

{{site.dev_portal}} doesn't have a webhook for new registrations or form submissions, so any of these integrations need to poll the {{site.konnect_short_name}} API on an interval. For example by filtering on `status=pending` and sorting by `created_at`, and tracking the last ID or timestamp you've already processed.
