---
title: "Recover {{site.konnect_short_name}} audit logs"
permalink: /how-to/recover-konnect-org-audit-logs/
description: "Learn how to recover {{site.konnect_short_name}} org audit logs using replay jobs."
content_type: how_to
related_resources:
  - text: "{{site.konnect_short_name}} audit logs"
    url: /konnect-platform/audit-logs/
  - text: Collect {{site.konnect_short_name}} audit logs
    url: /how-to/collect-audit-logs/
  - text: Recover Dev Portal audit logs
    url: /how-to/recover-dev-portal-audit-logs/
  - text: Configure an HTTPS data collection endpoint in SumoLogic
    url: https://help.sumologic.com/docs/send-data/hosted-collectors/http-source/logs-metrics/#configure-an-httplogs-and-metrics-source
automated_tests: false
products:
    - konnect

works_on:
    - konnect

tags:
    - security
    - logging
    - audit-logging

tldr:
    q: How do I recover {{site.konnect_short_name}} org audit logs?
    a: |
        Use replay jobs in {{site.konnect_short_name}} to recover audit logs. These are useful when you've missed audit log entries due to an error or a misconfigured audit log webhook. 

        Configure an audit log webhook in {{site.konnect_short_name}} with the SIEM endpoint, the access key, and the log format. Then, configure audit logs for your {{site.konnect_short_name}} org by adding the audit log webhook that you just configured. You can then navigate to your {{site.konnect_short_name}} org audit log configuration and click the **Replay** tab to recover audit logs from a specified time frame. 

        This tutorial uses SumoLogic, but you can apply the same steps to your SIEM provider.

prereqs:
  skip_product: true
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        To recover audit logs, you need the Admin role for audit logs.
      icon_url: /assets/icons/gateway.svg
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
        1. Click the **Konnect** tab.
        1. Navigate to the region you want to configure the webhook for.
        1. Click **Disabled**.
        1. From the **Endpoint** dropdown menu, select your SIEM endpoint.
        1. Click **Save**.

        To validate that the webhook is configured correctly, send an API request using the {{site.konnect_short_name}} API:

        <!--vale off-->
        {% konnect_api_request %}
        url: /v2/control-planes
        status_code: 201
        method: GET
        {% endkonnect_api_request %}
        <!--vale on-->

        This triggers a log in SumoLogic. Sometimes it can take a minute to populate the logs.

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
faqs:
  - q: How many days of {{site.konnect_short_name}} org audit logs can I recover?
    a: |
      {{site.konnect_short_name}} only collects audit logs from the past seven days, so you can only recover up to seven days of logs from the current date.
---

## Configure a replay job

In {{site.konnect_short_name}}, you can restore audit logs by configuring a replay job:

1. In the {{site.konnect_short_name}} sidebar, click [**Organization**](https://cloud.konghq.com/organization).
1. From the sidebar, click **Audit Logs Setup**.
1. Click the **Konnect** tab.
1. Navigate to the region you want to configure the replay job for.
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

Once the replay job is marked as Complete, you can view the recovered audit logs in your SIEM provider. If you're using SumoLogic, navigate to the [log search](https://service.sumologic.com/log-search) and search for `_source=Konnect`. You will see logs like the following:

```cef
2025-06-18T21:02:36Z konghq.com CEF:0|KongInc|Konnect|1.0|konnect|Authz.control-planes|1|rt=1750280466889 src=127.0.0.6 action=list granted=true org_id=777db3e4-5cb7-4dd5-b51c-9878096a6999 principal_id=eb999f01-5976-4f4b-9fbc-dd5d514bd675 trace_id=3959872677347089807 user_agent=grpc-node-js/1.12.4 sig=KbLaBhQFnggT_8CyC95b777R1_fGvvLVDn7awjZK8eZLdGPrSvnS-sxJw63j930eKr-VTsQv8-TQTD_GVmAPAQ
```

