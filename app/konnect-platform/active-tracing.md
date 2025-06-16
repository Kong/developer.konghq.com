---
title: "Logs and traces"
description: "Active tracing enables Control Plane administrators to initiate targeted deep tracing sessions in specific Data Plane nodes."
breadcrumbs:
  - /konnect/
content_type: reference
layout: reference
search_aliases: 
  - active tracing
products:
    - konnect-platform
works_on:
    - konnect

tech_preview: true

tags:
  - tracing
  - tech-preview
related_resources:
  - text: Active tracing spans
    url: /konnect-platform/active-tracing-spans/
---

{{site.konnect_short_name}} provides a connected debugging experience and real-time visibility into API traffic. Logs offer a detailed record of system events, while tracing tracks the flow of requests through Kong. Together, **Logs & Traces** provide key data that empower you to:

1. **Monitor system behavior**
   - Understand how your system performs in real time.
1. **Troubleshoot issues**
   - Quickly identify and resolve problems during deployments or incidents.
1. **Optimize performance**
   - Use insights to improve system reliability and efficiency.

Logs and traces offer deep visibility into API traffic and serve as powerful observability tools. Under normal conditions, they add negligible latency. However, under heavy load, active tracing may impact the throughput of Data Planes being traced.

## Traces

Control Plane administrators can initiate targeted deep tracing sessions on specific Data Plane nodes. During an active tracing session, the selected Data Plane generates detailed, OpenTelemetry-compatible traces for all requests that match the defined sampling criteria. Spans are captured for the full request and response lifecycle.

These traces are visualized directly in {{site.konnect_short_name}}’s built-in span viewer—no additional instrumentation or telemetry tools are required.

* Traces can be generated for a Service or a Route
* Refined traces can be captured for requests matching specific sampling criteria
* Sampling criteria can be defined using simple expression language, for example: `http.method == GET`
* Trace sessions are retained for up to 7 days
* Traces are viewable in the built-in trace viewer in {{site.konnect_short_name}}

Tracing follows OpenTelemetry naming conventions for spans and attributes wherever possible, ensuring consistency and interoperability.

{{site.konnect_product_name}}'s active tracing provides exclusive, in-depth insights that are not available through third-party telemetry tools. The detailed traces captured during a live session are unique to Kong and offer unparalleled visibility into system behavior.


## Logs

For deeper insights, tracing sessions can include log capture. When starting a session, administrators can enable this option to collect detailed {{site.base_gateway}} logs for its duration. These logs are automatically correlated with trace data using `trace_id` and `span_id`, offering a comprehensive view of all logs generated during a specific trace or span.

## Payload capture

When troubleshooting, it's important to access the full context of each request Kong processes. Capturing request and response headers—and optionally the body—can help identify issues and pinpoint failures.

Payload capture works alongside tracing. For each trace, the corresponding headers and bodies can be collected to provide full visibility into the request lifecycle.

Tracing in {{site.konnect_short_name}} follows OpenTelemetry naming conventions for spans and attributes wherever possible, ensuring interoperability and consistency.

### Protecting sensitive data with the payload sanitizer

Payload data may include sensitive information. To protect this data, {{site.base_gateway}} includes built-in payload sanitization. Captured headers and bodies are passed through a log sanitizer that redacts known sensitive patterns.

The sanitizer uses the [Luhn algorithm](https://stripe.com/resources/more/how-to-use-the-luhn-algorithm-a-guide-in-applications-for-businesses), a common method for validating credit card numbers. Matched values are replaced with asterisks.

The sanitizer performs two main functions:

* Authorization header redaction: Removes sensitive authorization parameters (but not the scheme) from the `Authorization` header.
* Sensitive data redaction: Replaces valid credit card numbers (matched using the Luhn check) that follow this regex pattern: `(\\d[\\n -]*){11,18}\\d`.

For example: A number such as `4242-4242-4242-4242` is redacted to `*******************`




### Logs tab in the trace viewer

The logs tab provides a drill-down view of all logs generated during a specific trace. Spans within the trace are correlated using `trace_id` and `span_id`. You can filter logs by type, source, or span. Logs are displayed in reverse chronological order.

{{site.konnect_product_name}} encrypts all ingested logs. For added privacy and control, you can enable customer-managed encryption keys (CMEK).

Use the logs view to troubleshoot issues and investigate trace-level events in detail.

## Data security with customer-managed encryption keys (CMEK)

By default, {{site.konnect_product_name}} encrypts payloads and logs at rest using managed keys. For organizations with specific compliance or regulatory requirements, CMEK support allows you to use your own encryption keys.


When CMEK is enabled, {{site.konnect_product_name}} uses your key to encrypt payloads and logs. This ensures your data remains secure and accessible only to your organization.

{:.info}
> The ability to capture payloads is an opt-in feature. It requires agreement to the Advanced Feature Addendum. Contact your organization admin to enable this feature.

## Reading traces in {{site.konnect_short_name}} trace viewer

Traces from an active tracing session can be viewed in {{site.konnect_short_name}}'s built-in trace viewer. The viewer includes:

* Summary view
* Trace view

Use the summary view for high-level insights, and the trace view for deeper analysis.

### Summary view

The summary view presents the full API request-response flow at a glance. It includes key metrics and a transaction map showing:

* All phases of {{site.base_gateway}}
* Plugins executed on both request and response paths
* Time spent in each phase

Use this view to understand request flow, identify performance bottlenecks, and fine-tune your configuration.

### Trace view

The trace view provides detailed visibility into {{site.base_gateway}}’s internal behavior. It breaks down traces into spans, helping you inspect:

* Internal processes and phases
* Plugin execution and latency
* Request and response flow

Use the trace view to troubleshoot specific issues and improve performance.

## Get started with tracing

Active tracing requires the following Data Plane version and environment variables in `kong.conf`:

* Version: 3.9.1 or later
* Environment variables:
  * `KONG_CLUSTER_RPC=on`
  * `KONG_ACTIVE_TRACING=on`

{:.info}
> Active tracing is currently supported on:
>
> * Konnect Self-Managed Hybrid Gateways  
> * Konnect Dedicated Cloud Gateways  
> * Konnect Serverless Gateways  
>
> It is not supported on {{site.kic_product_name}} or {{site.event_gateway}} Gateways.

### Start a trace session

1. In **Gateway Manager**, select the Control Plane that contains the Data Plane to be traced.
2. In the left navigation menu, click **Active Tracing**.
3. Click **New tracing session**.
4. Define the sampling criteria and click **Start Session**.

Once the session starts, traces will be captured. Click a trace to view it in the trace viewer.

Each session runs for 5 minutes or until 200 traces are collected, whichever comes first. Sessions are retained for up to 7 days.

### Sampling rules

Sampling rules help you capture only relevant traffic. Requests that match the defined criteria are included in the session. There are two types:

* Basic sampling rules: Filter by Route or Service.
* Advanced sampling rules: Use expressions for fine-grained filtering.

For example, to capture all requests with a 503 response:

`http.response.status_code==503`

## Sample trace

A sample trace is shown below. By inspecting the spans, it's clear that the bulk of the latency occurs in the pre-function plugin during the access phase.

![Active-Tracing Spans](/assets/images/konnect/active-tracing-spans.png)

