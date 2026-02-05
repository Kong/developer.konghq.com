---
title: "Collect Dev Portal audit logs"
permalink: /how-to/collect-dev-portal-audit-logs/
description: "Learn how to configure your SIEM provider to collect {{site.konnect_short_name}} Dev Portal logs and configure a Dev Portal audit log webhook."
content_type: how_to
related_resources:
  - text: "{{site.konnect_short_name}} audit logs"
    url: /konnect-platform/audit-logs/
  - text: Collect {{site.konnect_short_name}} audit logs
    url: /how-to/collect-audit-logs/
  - text: About Dev Portal
    url: /dev-portal/
  - text: Recover Dev Portal audit logs
    url: /how-to/recover-dev-portal-audit-logs/
  - text: Recover {{site.konnect_short_name}} audit logs
    url: /how-to/recover-konnect-org-audit-logs/
  - text: Configure an HTTPS data collection endpoint in SumoLogic
    url: https://help.sumologic.com/docs/send-data/hosted-collectors/http-source/logs-metrics/#configure-an-httplogs-and-metrics-source
automated_tests: false
products:
    - gateway
    - dev-portal

works_on:
    - konnect

tags:
    - security
    - logging
    - audit-logging

tldr:
    q: How do I send Dev Portal audit logs to a SIEM provider?
    a: |
        Create an HTTPS data collection endpoint and access key in the provider and save their values. Configure an [audit log destination](/api/konnect/audit-logs/#/operations/create-audit-log-destination) in {{site.konnect_short_name}} with the SIEM endpoint (`endpoint`), the access key (`authorization`), and set the log format `log_format: cef`. Then create the webhook for your Dev Portal with the [`/portals/{portalId}/audit-log-webhook`](/api/konnect/portal-management/#/operations/update-portal-audit-log-webhook).

        This tutorial uses SumoLogic, but you can apply the same steps to your provider.
prereqs:
  inline:
    - title: "{{site.konnect_product_name}} roles"
      include_content: prereqs/dev-portal-audit-log-roles
      icon_url: /assets/icons/gateway.svg
    - title: Dev Portal
      content: |
        For this tutorial, you’ll need a Dev Portal and some Dev Portal settings, like a published API, pre-configured. These settings are essential for Dev Portal to function but configuring them isn’t the focus of this guide. If you don't have these settings already configured, follow these steps to pre-configure them:

        1. [Create a Dev Portal](https://cloud.konghq.com/portals/create).
        1. From the overview of your Dev Portal, get your Dev Portal ID and export it to your environment:
           ```sh
           export PORTAL_ID='YOUR DEV PORTAL ID'
           ```
        1. [Register a test developer account with your Dev Portal](/dev-portal/developer-signup/#1-register-or-sign-in). You can do this by navigating to your Dev Portal URL and clicking **Sign up**.
      icon_url: /assets/icons/dev-portal.svg
    - title: SumoLogic SIEM provider
      include_content: /prereqs/sumologic-siem-for-konnect-api

tools:
  - konnect-api

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---

## Set up the audit log destination

Create an audit log destination by sending a `POST` request to the [`/audit-log-destinations`](/api/konnect/audit-logs/#/operations/create-audit-log-destination) endpoint with the connection details for your SIEM vendor:

<!-- vale off -->
{% konnect_api_request %}
url: /v3/audit-log-destinations
status_code: 201
method: POST
region: global
headers:
  - 'Content-Type: application/json'
body:
    endpoint: $SIEM_ENDPOINT
    authorization: $SIEM_TOKEN
    log_format: cef
    name: Example destination
{% endkonnect_api_request %}
<!-- vale on -->

Export the ID of the new destination to your environment:

```sh
export DESTINATION_ID='YOUR DESTINATION ID'
```

## Enable the webhook on your Dev Portal

Create a webhook by sending a `PATCH` request to the [`/portals/{portalId}/audit-log-webhook`](/api/konnect/portal-management/#/operations/update-portal-audit-log-webhook) endpoint with the audit log destination:

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/audit-log-webhook
status_code: 201
method: PATCH
body:
    audit_log_destination_id: $DESTINATION_ID
    enabled: true
{% endkonnect_api_request %}
<!--vale on-->

Webhooks are triggered via an HTTPS request using the following retry rules:

- Minimum retry wait time: 1 second
- Maximum retry wait time: 30 seconds
- Maximum number of retries: 4

A retry is performed on a connection error, server error (`500` HTTP status code), or too many requests (`429` HTTP status code).

## Validate

To validate that the webhook is configured correctly, you can log in to your Dev Portal with the account you created in the [prerequisites](#dev-portal). This should trigger a log in SumoLogic. Sometimes it can take a minute to populate the logs.

In the SumoLogic UI, navigate to the [log search](https://service.sumologic.com/log-search) and search for `_source=` with the name of the source we created in the [prerequisites](#sumologic-siem-provider). In this example, `_source=Konnect`. You should see logs like the following:

```cef
2025-06-23T14:28:47Z konghq.com CEF:0|KongInc|Dev-Portal|1.0|AUTHENTICATION_TYPE_BASIC|AUTHENTICATION_OUTCOME_SUCCESS|0|rt=1750688927556 src=172.71.232.22 request=/api/v2/developer/authenticate success=true org_id=998db3e4-5cb7-4dd5-b51c-9878096a6999 portal_id=3e551b39-227d-4297-b911-e68fd5d77c17 principal_id=a3d2699a-0ed3-4417-bb10-d8e74a1513a4 trace_id=3360194145499877252 user_agent= sig=XQC3OSFxLbi5dy2-o4xAXHT-x8oW5Df-zVsACWQLMU9Q-sPnEyk5CVs4JHwuRcwO0QNLsNaP1wsyrXYPeneXDQ
```

