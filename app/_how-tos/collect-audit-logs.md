---
title: "Collect {{site.konnect_short_name}} audit logs"
description: "Learn how to configure you SIEM provider to collect {{site.konnect_short_name}} logs and configure a {{site.konnect_short_name}} audit log webhook."
content_type: how_to
related_resources:
  - text: "{{site.konnect_short_name}} audit logs"
    url: /konnect-platform/audit-logs/
automated_tests: false
products:
    - gateway
    - ai-gateway

works_on:
    - konnect

entities:
  - vault

tags:
    - security
    - logging
    - audit-logging

tldr:
    q: How do I send {{site.konnect_short_name}} audit logs to a SIEM provider?
    a: |
        Create an HTTPS data collection endpoint and access key in your SIEM provider and save their values. Configure the audit log webhook endpoint (`/v2/audit-log-webhook`) in {{site.konnect_short_name}} with the provider endpoint (`endpoint`), the access key (`authorization`), and set `log_format: cef` and `enabled: true`. 

        This tutorial uses SumoLogic, but you can apply the same steps to your provider.

prereqs:
  inline:
    - title: SumoLogic SIEM provider
      include_content: /prereqs/sumologic-siem

tools:
  - konnect-api

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

## Set up the audit log webhook

Now that you have an external endpoint and authorization credentials, you can set up a webhook in {{site.konnect_short_name}}.

Create a webhook by sending a `PATCH` request to the [`/audit-log-webhook`](/api/konnect/audit-logs/v2/#/operations/update-audit-log-webhook) endpoint with the connection details for your SIEM vendor:

<!--vale off-->
{% konnect_api_request %}
url: /v2/audit-log-webhook
status_code: 201
method: PATCH
body:
    endpoint: $SIEM_ENDPOINT
    enabled: true
    authorization: "Bearer $SIEM_TOKEN"
    log_format: cef
{% endkonnect_api_request %}
<!--vale on-->

Webhooks are triggered via an HTTPS request using the following retry rules:

- Minimum retry wait time: 1 second
- Maximum retry wait time: 30 seconds
- Maximum number of retries: 4

A retry is performed on a connection error, server error (`500` HTTP status code), or too many requests (`429` HTTP status code).

## Validate

To validate that the webhook is configured correctly, send an API request using the {{site.konnect_short_name}} API:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->

This should trigger a log in SumoLogic. Sometimes it can take a minute to populate the logs.

In the SumoLogic UI, navigate to the [log search](https://service.sumologic.com/log-search) and search for `_source=Konnect`. 

You should see logs like the following:

```cef
2025-06-18T21:02:36Z konghq.com CEF:0|KongInc|Konnect|1.0|konnect|Authz.control-planes|1|rt=1750280466889 src=127.0.0.6 action=list granted=true org_id=777db3e4-5cb7-4dd5-b51c-9878096a6999 principal_id=eb999f01-5976-4f4b-9fbc-dd5d514bd675 trace_id=3959872677347089807 user_agent=grpc-node-js/1.12.4 sig=KbLaBhQFnggT_8CyC95b777R1_fGvvLVDn7awjZK8eZLdGPrSvnS-sxJw63j930eKr-VTsQv8-TQTD_GVmAPAQ
```

