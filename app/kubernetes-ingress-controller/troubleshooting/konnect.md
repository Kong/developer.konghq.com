---
title: Debugging KIC in Konnect
short_title: KIC in Konnect

description: |
  Gain insights into the KIC in Konnect synchronization process using traces.

content_type: reference
layout: reference

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Troubleshooting

products:
  - kic

works_on:
  - on-prem
  - konnect

tags:
  - troubleshooting

related_resources:
  - text: "Debugging {{site.base_gateway}} configuration"
    url: /kubernetes-ingress-controller/troubleshooting/kong-gateway-configuration/
  - text: Debugging Kubernetes API Server connectivity
    url: /kubernetes-ingress-controller/troubleshooting/kubernetes-api-server/
  - text: "Debugging KIC in {{site.konnect_short_name}}"
    url: /kubernetes-ingress-controller/troubleshooting/konnect/
  - text: Failure modes
    url: /kubernetes-ingress-controller/troubleshooting/failure-modes/
---

{{ site.kic_product_name }} must communicate with the {{ site.konnect_short_name }} APIs to provide an integration with {{site.konnect_short_name}}. If you encounter issues with KIC in {{ site.konnect_short_name }}, you should first inspect logs from {{ site.kic_product_name }} to identify the root cause.

## Prometheus Metrics

The Prometheus metrics `ingress_controller_configuration_push_count` and `ingress_controller_configuration_push_duration_milliseconds_bucket` show upload failures to {{site.konnect_short_name}}, where the `dataplane` label is the URL of {{site.konnect_short_name}}.

## Logging {{ site.konnect_short_name }} and {{ site.konnect_short_name }} traces {% new_in 3.3 %}

{{ site.kic_product_name }} logs the details for every failed request and response (method, URL, status code) it receives from {{ site.konnect_short_name }} by default.

If you set the `LOG_LEVEL` to `trace`, {{ site.kic_product_name }} will log the details for _every_ request and response it receives from {{ site.konnect_short_name }}.

Here is an example of a failed request/response log entry:

```text
Request failed  {"x_b3_traceid": "66c731200000000034ce3297e8e64544", "x_b3_spanid": "4e6955874299011d", "x_datadog_trace_id": "3805034363203503428", "x_datadog_parent_id": "5650141246939267357", "v": 0, "method": "GET", "url": "https://us.kic.api.konghq.com/kic/api/control-planes/81bc4af5-ed3c-40b4-bb88-b5a05fbe34a1/oauth2?size=1000", "status_code": 404}
```
{:.no-copy-code}

If your issue requires further investigation on the {{ site.konnect_short_name }} side, attach logs with tracing information to your support ticket.   