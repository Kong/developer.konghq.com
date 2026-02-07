---
title: "Recover Dev Portal audit logs"
permalink: /how-to/recover-dev-portal-audit-logs/
description: "Learn how to recover {{site.konnect_short_name}} Dev Portal audit logs using replay jobs."
content_type: how_to
related_resources:
  - text: "{{site.konnect_short_name}} audit logs"
    url: /konnect-platform/audit-logs/
  - text: Collect {{site.konnect_short_name}} audit logs
    url: /how-to/collect-audit-logs/
  - text: About Dev Portal
    url: /dev-portal/
  - text: Recover {{site.konnect_short_name}} audit logs
    url: /how-to/recover-konnect-org-audit-logs/
  - text: Configure an HTTPS data collection endpoint in SumoLogic
    url: https://help.sumologic.com/docs/send-data/hosted-collectors/http-source/logs-metrics/#configure-an-httplogs-and-metrics-source
automated_tests: false
products:
    - konnect
    - dev-portal

works_on:
    - konnect

tags:
    - security
    - logging
    - audit-logging

tldr:
    q: How do I recover Dev Portal audit logs?
    a: |
        You can use replay jobs in {{site.konnect_short_name}} to recover audit logs. These are useful when you've missed audit log entries due to an error or a misconfigured audit log webhook. 

        Configure an audit log webhook in {{site.konnect_short_name}} with the SIEM endpoint, the access key, and the log format. Then, configure audit logs for your Dev Portal by adding the audit log webhook that you just configured. You can then navigate to your Dev Portal audit log configuration and click the **Replay** tab to recover audit logs from a specified time frame. 

        This tutorial uses SumoLogic, but you can apply the same steps to your SIEM provider.
prereqs:
  show_works_on: false
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: "{{site.konnect_short_name}} roles"
      content: |
        To recover audit logs, you need the Admin role for audit logs.
      icon_url: /assets/icons/gateway.svg
    - title: Dev Portal
      content: |
        For this tutorial, you’ll need a Dev Portal pre-configured. If you don't have these settings already configured, follow these steps to pre-configure it:

        1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal**.
        1. Click **New portal** to [create a Dev Portal](https://cloud.konghq.com/portals/create).
        1. Click your Dev Portal URL at the top of the Dev Portal overview.
        1. Click **Sign up** to [register a test developer account with your Dev Portal](/dev-portal/developer-signup/#1-register-or-sign-in).
        1. If your settings require developer or application approval, you can manage approvals by navigating to **Access and approvals** in the {{site.konnect_short_name}} sidebar.
      icon_url: /assets/icons/dev-portal.svg
    - title: SumoLogic SIEM provider
      include_content: /prereqs/sumologic-siem-for-konnect-ui
    - title: Audit log destination and webhook
      content: |
        To complete this tutorial, you'll need an audit log destination and webhook configured. If you don't already have one configured, follow these steps:

        1. In the {{site.konnect_short_name}} sidebar, click [**Organization**](https://cloud.konghq.com/organization).
        1. From the sidebar, click **Audit Logs Setup**.
        1. On the Webhook Destination tab, click **New Webhook**.
        1. In the **Name** field, enter `SumoLogic`.
        1. In the **Endpoint** field, enter your external endpoint that will receive audit log messages. For example: `https://endpoint4.collection.sumologic.com/receiver/v1/http/1234abcd`.
        1. In the **Authorization Header** field, enter the access token from you SIEM. 
           {{site.konnect_short_name}} will send this string in the `Authorization` header of requests to that endpoint.
        1. From the **Log Format** dropdown menu, select "cef".
        1. (Optional) Click **Disable SSL Verification** to disable SSL verification of the host endpoint when delivering payloads.
            
           {:.warning}
           > We only recommend disabling SSL verification when using self-signed SSL certificates in a non-production environment as this can subject you to man-in-the-middle and other attacks.
        1. Click the **Dev Portal** tab.
        1. Click **New Dev Portal Audit Log**.
        1. From the **View region** dropdown menu, select the region.
        1. From the **Dev Portal** dropdown menu, select your Dev Portal.
        1. Click **Enabled**.
        1. From the **Endpoint** dropdown menu, select your SIEM endpoint.
        1. Click **Save**.

        To validate that the webhook is configured correctly, you can log in to your Dev Portal with the account you created in the [prerequisites](#dev-portal). This should trigger a log in SumoLogic. Sometimes it can take a minute to populate the logs.

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
faqs:
  - q: How many days of Dev Portal audit logs can I recover?
    a: |
      {{site.konnect_short_name}} only collects audit logs from the past seven days, so you can only recover up to seven days of logs from the current date.
---

## Configure a replay job

Dev Portal audit logs allow you to recover audit logs by configuring a replay job.

1. In the {{site.konnect_short_name}} sidebar, click [**Organization**](https://cloud.konghq.com/organization).
1. From the sidebar, click **Audit Logs Setup**.
1. Click the **Dev Portal** tab.
1. Click the Dev Portal that you want to configure the replay job for.
1. Click the **Replay** tab.
1. From the **Replay Time Range** dropdown menu, select `Last 6 hours`.
1. Click **Send Replay**.

The replay job will now display one of the following statuses:

<!--vale off-->
{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: description
rows:
  - status: "Unconfigured"
    description: The job has not been set up. This is the job's initial state.
  - status: "Accepted"
    description: The job has been accepted for scheduling.
  - status: "Pending"
    description: The job has been scheduled.
  - status: "Running"
    description: The job is in progress. When a replay job is `running`, a request to update the job will return a `409` response code until it has completed or failed.
  - status: "Completed"
    description: The job has finished with no errors.
  - status: "Failed"
    description: The job has failed.
{% endtable %}
<!--vale on-->

## Validate

Once the replay job is marked as Complete, you can view the recovered audit logs in your SIEM provider. If you're using SumoLogic, navigate to the [log search](https://service.sumologic.com/log-search) and search for `_source=Konnect`. You should see logs like the following:

```cef
2025-06-23T14:28:47Z konghq.com CEF:0|KongInc|Dev-Portal|1.0|AUTHENTICATION_TYPE_BASIC|AUTHENTICATION_OUTCOME_SUCCESS|0|rt=1750688927556 src=172.71.232.22 request=/api/v2/developer/authenticate success=true org_id=998db3e4-5cb7-4dd5-b51c-9878096a6999 portal_id=3e551b39-227d-4297-b911-e68fd5d77c17 principal_id=a3d2699a-0ed3-4417-bb10-d8e74a1513a4 trace_id=3360194145499877252 user_agent= sig=XQC3OSFxLbi5dy2-o4xAXHT-x8oW5Df-zVsACWQLMU9Q-sPnEyk5CVs4JHwuRcwO0QNLsNaP1wsyrXYPeneXDQ
```


