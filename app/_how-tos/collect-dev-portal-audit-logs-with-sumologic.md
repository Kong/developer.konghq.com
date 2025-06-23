---
title: "Collect Dev Portal audit logs with SumoLogic"
description: "Learn how to configure you SIEM provider to collect {{site.konnect_short_name}} logs and configure a {{site.konnect_short_name}} audit log webhook."
content_type: how_to
related_resources:
  - text: "{{site.konnect_short_name}} audit logs"
    url: /konnect-platform/audit-logs/
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
    q: How do I send Dev Portal audit logs to a SIEM provider like SumoLogic?
    a: |
        Create an HTTPS data collection endpoint and access key in SumoLogic and save their values. Configure an [audit log destination](/api/konnect/audit-logs/v2/#/operations/create-audit-log-destination) in {{site.konnect_short_name}} with the SumoLogic endpoint (`endpoint`), the access key (`authorization`), and set the log format `log_format: cef`. Then create the webhook for your Dev Portal with the [`/portals/{portalId}/audit-log-webhook`](/api/konnect/portal-management/v3/#/operations/update-portal-audit-log-webhook).

prereqs:
  inline:
    - title: Dev Portal
      include_content: prereqs/dev-portal-app-reg
      icon_url: /assets/icons/dev-portal.svg
    - title: Dev Portal ID
      content: |
        From the overview of the [Dev Portal you created](#dev-portal), get your Dev Portal ID and export it to your environment:

        ```sh
        export PORTAL_ID='YOUR DEV PORTAL ID'
        ```
      icon_url: /assets/icons/dev-portal.svg
    - title: SumoLogic SIEM provider
      include_content: /prereqs/sumologic-siem

tools:
  - konnect-api

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---

## Set up the audit log destination

Create an audit log destination by sending a `POST` request to the [`/audit-log-destinations`](/api/konnect/audit-logs/v2/#/operations/create-audit-log-destination) endpoint with the connection details for your SIEM vendor:

```sh
curl -i -X POST https://global.api.konghq.com/v2/audit-log-destinations \
--header "Content-Type: application/json" \
--header "Authorization: Bearer $KONNECT_TOKEN" \
--json '{
    "endpoint": "'$SIEM_ENDPOINT'",
    "authorization": "'$SIEM_TOKEN'",
    "log_format": "cef",
    "name": "Example destination"
}'
```

Export the ID of the new destination to your environment:

```sh
export DESTINATION_ID='YOUR DESTINATION ID'
```

## Enable the webhook on your Dev Portal

Create a webhook by sending a `PATCH` request to the [`/portals/{portalId}/audit-log-webhook`](/api/konnect/portal-management/v3/#/operations/update-portal-audit-log-webhook) endpoint with the audit log destination:

```sh
curl -i -X PATCH https://us.api.konghq.com/v3/portals/$PORTAL_ID/audit-log-webhook \
 --header "Content-Type: application/json" \
 --header "Authorization: Bearer $KONNECT_TOKEN" \
 --json '{
     "audit_log_destination_id": "'$DESTINATION_ID'",
     "enabled": true
 }'
```

Webhooks are triggered via an HTTPS request using the following retry rules:

- Minimum retry wait time: 1 second
- Maximum retry wait time: 30 seconds
- Maximum number of retries: 4

A retry is performed on a connection error, server error (`500` HTTP status code), or too many requests (`429` HTTP status code).

## Validate

To validate that the webhook is configured correctly, you can log in to your Dev Portal with the account you created in the [prerequisites](#dev-portal). This should trigger a log in SumoLogic. Sometimes it can take a minute to populate the logs.

In the SumoLogic UI, navigate to the [log search](https://service.sumologic.com/log-search) and search for `_sourcecategory="Http Input"`. You should see logs like the following:

```cef
2025-06-23T14:28:47Z konghq.com CEF:0|KongInc|Dev-Portal|1.0|AUTHENTICATION_TYPE_BASIC|AUTHENTICATION_OUTCOME_SUCCESS|0|rt=1750688927556 src=172.71.232.22 request=/api/v2/developer/authenticate success=true org_id=998db3e4-5cb7-4dd5-b51c-9878096a6999 portal_id=3e551b39-227d-4297-b911-e68fd5d77c17 principal_id=a3d2699a-0ed3-4417-bb10-d8e74a1513a4 trace_id=3360194145499877252 user_agent= sig=XQC3OSFxLbi5dy2-o4xAXHT-x8oW5Df-zVsACWQLMU9Q-sPnEyk5CVs4JHwuRcwO0QNLsNaP1wsyrXYPeneXDQ
```

