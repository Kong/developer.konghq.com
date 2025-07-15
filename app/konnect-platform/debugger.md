---
title: "Collecting {{site.konnect_short_name}} traces with Debugger"
description: "The Debugger enables control plane administrators to initiate targeted deep session traces in specific data plane nodes."
breadcrumbs:
  - /konnect/
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
related_resources:
  - text: Debugger spans
    url: /konnect-platform/debugger-spans/
  - text: Configure CMEK in {{site.konnect_short_name}}
    url: /konnect-platform/cmek/
  - text: "{{site.base_gateway}} tracing reference"
    url: /gateway/tracing/
---

{{site.konnect_short_name}} Debugger provides a connected debugging experience and real-time trace-level visibility into API traffic, enabling you to:

* **Troubleshoot issues:** Investigate and resolve problems during deployments or incidents with targeted, on-demand traces.
* **Understand request behavior:** See exactly what happened during a specific request, including which plugins ran, in what order, how long they took, and more.
* **Improve performance and reliability:** Use deep insights to fine-tune configurations and resolve bottlenecks.

{{site.konnect_product_name}}'s Debugger provides exclusive, in-depth insights not available through third-party telemetry tools. The detailed traces captured during a live session are unique to Kong and offer unparalleled visibility into system behavior.



## Start your first debug session

To begin using the Debugger, ensure the following requirements are met:

* Your data plane nodes are running {{site.base_gateway}} version 3.9.1 or later.
* For version 3.9.x only: set the following environment variables in `kong.conf`:
  * `KONG_CLUSTER_RPC=on`
  * `KONG_ACTIVE_TRACING=on`

{:.info}
> From version 3.10 and later, these environment variables are enabled by default and no manual configuration is required.

{:.info}
> The {{site.konnect_short_name}} Debugger is currently supported on:
>
> * {{site.konnect_short_name}} Self-Managed Hybrid Gateways  
> * {{site.konnect_short_name}} Dedicated Cloud Gateways  
> * {{site.konnect_short_name}} Serverless Gateways  
>
> It is not supported on {{site.kic_product_name}} or {{site.event_gateway}} Gateways.

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


## Debugger sessions

Control plane administrators can initiate a debugger session to capture trace-level insights on specific data plane nodes. A session defines which traffic to trace using configurable **sampling rules**.

Sampling rules can be defined in two ways:

* **Basic sampling rules:** Choose from predefined filters:
  * **None:** Capture all requests.
  * **Route:** Capture requests to a specific Route.
  * **Gateway service:** Capture requests to a specific Gateway service.
* **Advanced sampling rules:** Use expressions to match on attributes such as latency, headers, status codes, route ID, service ID, and more.  
  For example: `http.response.status_code == 503`


Once a session starts, the selected data plane node generates detailed, debug-level data for every request that matches the sampling rule. This information is represented as **OpenTelemetry-compatible traces**, including spans for each phase of request processing.

Traces are viewable directly in {{site.konnect_short_name}}’s built-in span viewer. No additional instrumentation or telemetry tools are required.

### Caputred traces

Captured traces include:

* Request and response summary
* Spans for each internal Kong phase
* Plugin execution and duration
* Logs correlated to each trace and span ([learn more](#logs))

Tracing follows OpenTelemetry naming conventions for spans and attributes wherever possible, ensuring consistency and interoperability.

For details on the structure and attributes of traces and spans, see the [Debugger spans reference](/konnect-platform/debugger-spans/).


## Viewing session details

After starting a Debugger session, the UI lists all captured traces that match the sampling criteria. You can select an individual trace from the list to open a side panel that displays in-depth information about the request.

The side panel includes the following views:

* Summary
* Span
* Logs


### Summary view

The summary view provides a high-level visualization of the request and response flow. It includes a transaction map that shows:

* All phases of {{site.base_gateway}}
* Plugins executed during the request and response path
* Time spent in each phase
* A detailed latency breakdown

Use the summary view to quickly understand the overall flow of a request and identify potential bottlenecks.

### Span view

The span view breaks the trace into individual spans, each representing an internal Kong phase or plugin execution. This view allows you to:

* Inspect each span and its attributes  
* Investigate plugin execution order and duration  
* Jump directly into logs for a specific span

Use the spans view to troubleshoot specific issues and improve performance.

## Logs

Logs offer deeper insight into what happened during a request. While traces and spans help you pinpoint **where** an issue occurred, logs help explain **what** occurred.

When starting a session, administrators can enable log capture to collect Gateway logs for the duration of the session. These logs are scoped to the session and only include error logs produced by {{site.base_gateway}} during that time.

Captured logs are automatically associated with specific spans and are viewable in the **Logs** tab of the trace panel. You can filter logs by log level and span to narrow down the output.

{:.info}
> Logs are supported only on data plane nodes running {{site.base_gateway}} version 3.11 or later.

{{site.konnect_product_name}} encrypts all ingested logs. For added privacy and control, you can [enable customer-managed encryption keys (CMEK)](/konnect-platform/cmek/).

Use the logs view to investigate specific errors and debug messages in the context of a trace.


Use the logs view to troubleshoot issues and investigate trace-level events in detail.


## Data security with customer-managed encryption keys (CMEK)

By default, {{site.konnect_product_name}} encrypts payloads and logs at rest using managed keys. For organizations with specific compliance or regulatory requirements, CMEK support allows you to use your own encryption keys. See [Customer-Managed Encryption Keys (CMEK)](/konnect-platform/cmek/) for more information.


When CMEK is enabled, {{site.konnect_product_name}} uses your key to encrypt payloads and logs. This ensures your data remains secure and accessible only to your organization.




