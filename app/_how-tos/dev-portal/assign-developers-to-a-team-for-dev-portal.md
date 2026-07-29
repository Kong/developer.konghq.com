---
title: Assign developers to a team with a {{site.dev_portal}} custom sign-up form
permalink: /how-to/assign-developers-to-a-team-for-dev-portal/
description: Learn how to collect a developer's department at sign-up with a Dev Portal custom form, then automatically assign them to the matching RBAC team before approval.
content_type: how_to
automated_tests: false
products:
    - dev-portal
    - gateway
works_on:
    - konnect
tools:
  - konnect-api
  - deck
entities: []
tags:
    - application-registration
    - rbac
search_aliases:
    - custom forms
    - custom sign-up form
    - developer rbac

tldr:
    q: How do I automatically add new developers to the right {{site.dev_portal}} team based on their sign-up answers?
    a: Create a custom developer registration form with a custom field, turn off developer auto-approve, then read each new developer's `additional_data` and add them to the matching team using the `/v3/portals/{portalId}/teams/{teamId}/developers` endpoint before approving them.

prereqs:
  inline:
    - title: "{{site.konnect_product_name}} roles"
      content: |
        To run this tutorial, you need the following [{{site.konnect_short_name}} teams and roles](/konnect-platform/teams-and-roles/):
        - **Portal Admin**: Manage {{site.dev_portal}} settings, teams, and custom forms.
      icon_url: /assets/icons/dev-portal.svg
    - title: "{{site.dev_portal}}"
      include_content: prereqs/dev-portal-configure
      icon_url: /assets/icons/dev-portal.svg
    - title: Published API
      include_content: prereqs/publish-api
      icon_url: /assets/icons/dev-portal.svg
  entities_product: gateway
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
  - text: "{{site.dev_portal}} developer RBAC"
    url: /dev-portal/developer-rbac/
  - text: Developer, API, and application registration forms
    url: /dev-portal/self-service/#developer-api-and-application-registration-forms
  - text: Review partner API access requests with {{site.dev_portal}} custom forms
    url: /how-to/review-partner-api-access-requests-for-dev-portal/
---

In this tutorial, you'll collect a developer's department at sign-up with a custom form, read that answer, add the developer to the matching team, and see them gain access to that team's API.
This can be useful when your {{site.dev_portal}} is used internally by your organization's own engineering groups, and you want new developers to be assigned to the right team, with the right API access, as soon as they're approved.

## Create teams

Create two teams, one for each department, by sending `POST` requests to the [`/portals/{portalId}/teams` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-team):

1. Create the Payments team, and capture its ID as `$PAYMENTS_TEAM_ID`:
{% capture create-payments-team %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/teams
method: POST
status_code: 201
body:
  name: Payments
  description: The Payments engineering team
capture:
  - variable: PAYMENTS_TEAM_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-payments-team | indent: 3}}
1. Create the Platform team, and capture its ID as `$PLATFORM_TEAM_ID`:
{% capture create-platform-team %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/teams
method: POST
status_code: 201
body:
  name: Platform
  description: The Platform engineering team
capture:
  - variable: PLATFORM_TEAM_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-platform-team | indent: 3}}

## Give the Payments team API access

Give the Payments team access to your API, so its members can call it, by sending a `POST` request to the [`/portals/{portalId}/teams/{teamId}/assigned-roles` endpoint](/api/konnect/portal-management/v3/#/operations/assign-role-to-portal-teams):

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/teams/$PAYMENTS_TEAM_ID/assigned-roles
method: POST
status_code: 201
body:
  role_name: API Consumer
  entity_id: $SERVICE_ID
  entity_type_name: Services
  entity_region: us
{% endkonnect_api_request %}
<!--vale on-->

The **API Consumer** role lets developers on the team make calls to the API. 
The Platform team is left without API access in this tutorial to show the difference in a developer's access depending on which team they are assigned to.

## Turn off auto-approve for developers

To review each new developer's department answer and assign a team before they're approved, turn off developer auto-approve by sending a `PATCH` request to the [`/portals/{portalId}` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal):

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID
method: PATCH
status_code: 200
body:
  auto_approve_developers: false
{% endkonnect_api_request %}
<!--vale on-->

Application auto-approve is left on, since by the time a developer registers an application, their team already scopes what they can access.

## Create a developer registration form

Create a custom form that asks new developers to select their department, by sending a `POST` request to the [`/portals/{portalId}/forms` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-form):

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
    - type: select
      mode: single_select
      name: department
      label: Department
      required: true
      options:
        - value: payments
          label: Payments
        - value: platform
          label: Platform
    - type: submit
      name: submit
      value: Create account
{% endkonnect_api_request %}
<!--vale on-->

## Register a developer

Simulate a developer signing up and selecting their department, and capture their ID as `$DEVELOPER_ID`, by sending a `POST` request to the [`/portals/{portalId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/create-developer) with `additional_data`:

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/developers
method: POST
status_code: 201
body:
  full_name: Jordan Blake
  email: jordan.blake@example.com
  additional_data:
    department: payments
capture:
  - variable: DEVELOPER_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->

Since auto-approve is off, this developer's `status` is `pending`.

## Read the submitted answer and assign a team

1. Read the developer's submitted answer, by sending a `GET` request to the [`/portals/{portalId}/developers/{developerId}` endpoint](/api/konnect/portal-management/v3/#/operations/get-developer):
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
   The response includes `additional_data.department: payments`.
1. Based on that answer, add the developer to the matching team, by sending a `POST` request to the [`/portals/{portalId}/teams/{teamId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/add-developer-to-portal-team):
{% capture add-to-team %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/teams/$PAYMENTS_TEAM_ID/developers
method: POST
status_code: 201
body:
  id: $DEVELOPER_ID
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ add-to-team | indent: 3}}
1. Approve the developer, by sending a `PATCH` request to the [`/portals/{portalId}/developers/{developerId}` endpoint](/api/konnect/portal-management/v3/#/operations/update-developer):
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

## Validate

Verify that the developer was approved by sending a `GET` request to the [`/portals/{portalId}/developers/{developerId}` endpoint](/api/konnect/portal-management/v3/#/operations/get-developer) and confirming `status: approved` in the response:
 
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/developers/$DEVELOPER_ID
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

### Automation ideas

Instead of reading each developer's answer and assigning their team manually, you can:
* Run this logic on a schedule, or trigger it from an internal workflow tool whenever a new pending developer registers.
* Extend the form with more departments as your organization grows, and maintain a lookup table mapping each `department` value to a team ID.

{{site.dev_portal}} doesn't have a webhook for new sign-ups, so this automation needs to poll the {{site.konnect_short_name}} API on an interval, for example by [listing developers](/api/konnect/portal-management/v3/#/operations/list-portal-developers) filtered on `status=pending`.