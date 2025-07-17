---
title: "Troubleshooting with {{site.konnect_short_name}} Debugger"
description: "The Debugger enables control plane administrators to initiate targeted deep session traces in specific data plane nodes."
breadcrumbs:
  - /gateway-manager/
content_type: reference
layout: reference
search_aliases: 
  - active tracing
  - debugger
products:
    - konnect-platform
works_on:
    - konnect

faqs:
  - q: Will the {{site.konnect_short_name}} Debugger impact latency?
    a: Under normal conditions, the Debugger adds negligible latency. However, under heavy load, the Debugger may impact the throughput of data planes being traced.
tags:
  - tracing
  - debugger
related_resources:
  - text: Debugger spans
    url: /gateway/debugger-spans/
  - text: Configure CMEK in {{site.konnect_short_name}}
    url: /konnect-platform/cmek/
  - text: "{{site.base_gateway}} tracing reference"
    url: /gateway/tracing/
---

{{site.konnect_short_name}} Debugger provides a connected debugging experience and real-time trace-level visibility into API traffic, enabling you to:

* **Troubleshoot issues:** Investigate and resolve problems during deployments or incidents with targeted, on-demand traces.
* **Understand request lifecycle**: Visualize exactly what happened during a specific request, including order and duration plugin execution, and more.
* **Improve performance and reliability:** Use deep insights to fine-tune configurations and resolve bottlenecks.

{{site.konnect_product_name}}'s Debugger provides exclusive, in-depth insights not available through third-party telemetry tools. The detailed traces captured during a live session are unique to Kong and offer unparalleled visibility into system behavior.

## Capture traces and logs

{{site.konnect_short_name}} Debugger allows you to capture traces and logs. 

### Traces
Traces provide a visual representation of the request and response lifecycle, offering a comprehensive overview of Kong's request processing pipeline. 

The debugger helps capture OpenTelemetry-compatible traces for all requests matching the sampling criteria. The detailed spans are captured for the entire request/response lifecycle. These traces can be visualized with {{site.konnect_short_name}}'s built-in span viewer with no additional instrumentation or telemetry tools.

**Key Highlights**
* Traces can be generated for a service or per route
* Refined traces can be generated for all requests matching a sampling criteria
* Sampling criteria can be defined with simple expressions language, for example: `http.method` == `GET`
* Trace sessions are retained for up to 7 days
* Traces can be visualized in {{site.konnect_short_name}}'s built in trace viewer

To ensure consistency and interoperability, tracing adheres to OpenTelemetry naming conventions for spans and attributes, wherever possible.

### Logs
For deeper insights, logs can be captured along with traces. When initiating a debug session, administrators can choose to capture logs. Detailed {{site.base_gateway}} logs are captured for the duration of the session. These logs are then correlated with traces using `trace_id` and `span_id` providing a comprehensive and drill-down view of logs generated during specific trace or span.

## Reading traces and logs 
Traces captured during a debug session can be visualized in debugger's built-in trace viewer. The trace viewer displays  **Summary**, **Spans**  and **Logs** view. You can gain instant insights with the summary view while the spans and logs view help you to dive deeper.

### Summary view
Summary view helps you visualize the entire API request-response flow in a single glance. This view provides a concise overview of critical latency metrics and a transaction map. The lifecycle map includes the different phases of {{site.base_gateway}} and the plugins executed by {{site.base_gateway}} on both the request and the response along with the times spent in each phase. Use the summary view to quickly understand the end-to-end API flow, identify performance bottlenecks, and optimize your API strategy.

### Spans view
The span view gives you unparalleled visibility into {{site.base_gateway}}’s internal workings. This detailed view breaks down into individual spans, providing a comprehensive understanding of:

* {{site.base_gateway}}’s internal processes and phases
* Plugin execution and performance
* Request and response handling

Use the span view to troubleshoot issues, optimize performance, and refine your configuration.
### Logs View
A drill-down view of all the logs generated during specific debug session are shown in the logs tab. All the spans in the trace are correlated using `trace_id` and `span_id`. The logs can be filtered on log level and spans. Logs are displayed in reverse chronological order. {{site.konnect_short_name}} encrypts all the logs that are ingested. You can further ensure complete privacy and control by using customer-managed encryption keys (CMEK).
Use the logs view to quickly troubleshoot and pinpoint issues.

## Data Security with Customer-Managed Encryption Keys (CMEK)
By default, logs are automatically encrypted using encryption keys that are owned and managed by {{site.konnect_short_name}}. However if you have a specific compliance and regulatory requirements related to the keys that protect your data, you can use the customer-managed encryption keys. This ensures that sensitive data are secured for each organization with their own key and nobody, including {{site.konnect_short_name}}, has access to that data. For more information about how to create and manage CMEK keys, see [Customer-Managed Encryption Keys (CMEK)](/konnect-platform/cmek/).

## Start your first debug session

To begin using the Debugger, ensure the following requirements are met:

* Your data plane nodes are running {{site.base_gateway}} version 3.9.1 or later.
* Logs require {{site.base_gateway}} version 3.11.0 or later.
* Your {{site.konnect_short_name}} data planes are hosted using self-managed hybrid, Dedicated Cloud Gateways, or serverless gateways. {{site.kic_product_name}} or {{site.event_gateway}} Gateways aren't currently supported.
* For version 3.9.x only: set the following environment variables in `kong.conf`:
  * `KONG_CLUSTER_RPC=on`
  * `KONG_ACTIVE_TRACING=on`

{:.info}
> From version 3.10 and later, these environment variables are enabled by default and no manual configuration is required.


1. In [**Gateway Manager**](https://cloud.konghq.com/us/gateway-manager/), select the control plane that contains the data plane to be traced.
2. In the left navigation menu, click **Debugger**.
3. Click **New session**.
4. Define the sampling criteria and click **Start Session**.

Once the session starts, traces will be captured for requests that match the rule. Click a trace to view it in the span viewer.

Each session can be configured to run for a time between 10 seconds and 30 minutes. Sessions are retained for up to 7 days.

For details on defining sampling rules, see [Debugger sessions](#debugger-sessions).

## Sampling rules

Sampling rules help you capture only relevant traffic. Requests that match the defined criteria are included in the session. There are two types:

* Basic sampling rules: Filter by Route or Service.
* Advanced sampling rules: Use expressions for fine-grained filtering.

For example, to capture all requests with a 503 response:

```sh
http.response.status_code==503
```

A sample trace is shown below. By inspecting the spans, you can see that the bulk of the latency occurs in the pre-function plugin during the access phase.

![Active-Tracing Spans](/assets/images/konnect/active-tracing-spans.png)