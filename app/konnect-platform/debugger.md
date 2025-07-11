---
title: "Collecting {{site.konnect_short_name}} traces with Debugger"
description: "The Debugger enables Control Plane administrators to initiate targeted deep session traces in specific Data Plane nodes."
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

tech_preview: true
faqs:
  - q: Will the {{site.konnect_short_name}} Debugger impact latency?
    a: Under normal conditions, the Debugger adds negligible latency. However, under heavy load, the Debugger may impact the throughput of Data Planes being traced.
tags:
  - tracing
  - tech-preview
related_resources:
  - text: Debugger spans
    url: /konnect-platform/debugger-spans/
  - text: Configure CMEK in {{site.konnect_short_name}}
    url: /konnect-platform/cmek/
  - text: "{{site.base_gateway}} tracing reference"
    url: /gateway/tracing/
---

{{site.konnect_short_name}} provides a connected debugging experience and real-time visibility into API traffic allowing you to: 

* **Monitor system behavior:** Understand how your system performs in real time.
* **Troubleshoot issues:** Quickly identify and resolve problems during deployments or incidents.
* **Optimize performance:** Use insights to improve system reliability and efficiency.

{{site.konnect_short_name}} Debugger offers deep visibility into API traffic and serves as a powerful observability tool. 

{{site.konnect_product_name}}'s Debugger provides exclusive, in-depth insights that aren't available through third-party telemetry tools. The detailed traces captured during a live session are unique to Kong and offer unparalleled visibility into system behavior.

## Traces

Control Plane administrators can initiate targeted deep session traces on specific Data Plane nodes. During a Debugger session, the selected Data Plane generates detailed, OpenTelemetry-compatible traces for all requests that match the defined sampling criteria. Spans are captured for the full request and response summary.

These traces are visualized directly in {{site.konnect_short_name}}’s built-in span viewer. Additional instrumentation or telemetry tools aren't required.

* Traces can be generated for a Service or a Route
* Refined traces can be captured for requests matching specific sampling criteria
* Sampling criteria can be defined using simple expression language, for example: `http.method == GET`
* Sessions are retained for up to 7 days
* Traces are viewable in the built-in span viewer in {{site.konnect_short_name}}

Tracing follows OpenTelemetry naming conventions for spans and attributes wherever possible, ensuring consistency and interoperability.



## Reading traces

Traces from a Debugger session can be viewed in {{site.konnect_short_name}}'s built-in log viewer. The viewer includes:

* Summary view: Use for high-level insights
* Span view: Use for deeper analysis

### Summary view

The summary view presents the full API request-response flow at a glance. It includes key metrics and a transaction map showing:

* All phases of {{site.base_gateway}}
* Plugins executed on both request and response paths
* Time spent in each phase

Use this view to understand request flow, identify performance bottlenecks, and fine-tune your configuration.

### Spans view

The spans view provides detailed visibility into {{site.base_gateway}}’s internal behavior. It breaks down traces into spans, helping you inspect:

* Internal processes and phases
* Plugin execution and latency
* Request and response flow

Use the spans view to troubleshoot specific issues and improve performance.

## Logs

For deeper insights, session traces can include log capture. When starting a session, administrators can enable this option to collect detailed {{site.base_gateway}} logs for its duration. These logs are automatically correlated with trace data using `trace_id` and `span_id`, offering a comprehensive view of all logs generated during a specific trace or span.

### Logs tab in the span viewer

The logs tab provides a drill-down view of all logs generated during a specific trace. Spans within the trace are correlated using `trace_id` and `span_id`. You can filter logs by type, source, or span. Logs are displayed in reverse chronological order.

{{site.konnect_product_name}} encrypts all ingested logs. For added privacy and control, you can [enable customer-managed encryption keys (CMEK)](/konnect-platform/cmek/).

Use the logs view to troubleshoot issues and investigate trace-level events in detail.

## Payload capture

{:.info}
> Payload capture is an opt-in feature because you must agree to the Advanced Feature Addendum. Contact your organization admin to enable this feature.

When troubleshooting, it's important to access the full context of each request {{site.base_gateway}} processes. Capturing request and response headers, and optionally the body, can help identify issues and pinpoint failures.

Payload capture works alongside tracing. For each trace, the corresponding headers and bodies can be collected to provide full visibility into the request summary.


### Payload sanitizer

Payload data may include sensitive information. To protect this data, {{site.base_gateway}} includes built-in payload sanitization. Captured headers and bodies are passed through a log sanitizer that redacts known sensitive patterns.

The sanitizer uses the [Luhn algorithm](https://stripe.com/resources/more/how-to-use-the-luhn-algorithm-a-guide-in-applications-for-businesses), a common method for validating credit card numbers. Matched values are replaced with asterisks.

The sanitizer performs two main functions:

* Authorization header redaction: Removes sensitive authorization parameters (but not the scheme) from the `Authorization` header.
* Sensitive data redaction: Replaces valid credit card numbers (matched using the Luhn check) that follow this regex pattern: `(\\d[\\n -]*){11,18}\\d`.

For example: A number such as `4242-4242-4242-4242` is redacted to `*******************`



## Data security with customer-managed encryption keys (CMEK)

By default, {{site.konnect_product_name}} encrypts payloads and logs at rest using managed keys. For organizations with specific compliance or regulatory requirements, CMEK support allows you to use your own encryption keys. See [Customer-Managed Encryption Keys (CMEK)](/konnect-platform/cmek/) for more information.


When CMEK is enabled, {{site.konnect_product_name}} uses your key to encrypt payloads and logs. This ensures your data remains secure and accessible only to your organization.



## Get started with tracing

To enable tracing with the Debugger, you need:

* Data Plane nodes with {{site.base_gateway}} 3.9.1 or later
* Set the following environment variables in `kong.conf`:
  * `KONG_CLUSTER_RPC=on`
  * `KONG_ACTIVE_TRACING=on`

{:.info}
> The {{site.konnect_short_name}} debugger is currently supported on:
>
> * {{site.konnect_short_name}} Self-Managed Hybrid Gateways  
> * {{site.konnect_short_name}} Dedicated Cloud Gateways  
> * {{site.konnect_short_name}} Serverless Gateways  
>
> It is not supported on {{site.kic_product_name}} or {{site.event_gateway}} Gateways.

### Start a Session

1. In **Gateway Manager**, select the Control Plane that contains the Data Plane to be traced.
2. In the left navigation menu, click **Debugger**.
3. Click **New session**.
4. Define the sampling criteria and click **Start Session**.

Once the session starts, traces will be captured. Click a trace to view it in the spans viewer.

Each session runs for 5 minutes or until 200 traces are collected, whichever comes first. Sessions are retained for up to 7 days.

### Sampling rules

Sampling rules help you capture only relevant traffic. Requests that match the defined criteria are included in the session. There are two types:

* Basic sampling rules: Filter by Route or Service.
* Advanced sampling rules: Use expressions for fine-grained filtering.

For example, to capture all requests with a 503 response:

```sh
http.response.status_code==503
```

A sample trace is shown below. By inspecting the spans, you can see that the bulk of the latency occurs in the pre-function plugin during the access phase.

![Active-Tracing Spans](/assets/images/konnect/active-tracing-spans.png)
