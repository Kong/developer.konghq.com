---
title: "Active tracing in {{site.konnect_short_name}}"

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
---

Active tracing enables Control Plane administrators to initiate targeted "deep tracing" sessions in specific Data Plane nodes. During an active tracing session, the selected Data Plane generates detailed, OpenTelemetry-compatible traces for all requests matching the sampling criteria. The detailed spans are captured for the entire request/response lifecycle. These traces can be visualized with {{site.konnect_short_name}}'s built-in span viewer with no additional instrumentation or telemetry tools.

{{site.konnect_product_name}}'s active tracing capability offers exclusive, in-depth insights that cannot be replicated by third-party telemetry tools. The detailed traces generated during live active tracing session are unique to Kong and provide unparalleled visibility into system performance. 

Active tracing adheres to OpenTelemetry naming conventions for spans and attributes, wherever possible, ensuring consistency and interoperability.

## Key highlights

- Traces can be generated for a Service or per Route
- Refined traces can be generated for all requests matching a sampling criteria
- Sampling criteria can be defined with simple expressions language, for example: `http.method == GET`
- Trace sessions are retained for up to 7 days
- Traces can be visualized in {{site.konnect_short_name}}'s built in trace viewer 

Although active tracing is designed as a debug and troubleshooting tool, it can unlock in-depth insights into the API traffic and serve as a monitoring and observability tool. 
Under normal conditions, active tracing adds negligible latency. However, under heavy loads, it may affect the throughput.

## Reading traces in {{site.konnect_short_name}} trace viewer

Traces captured in an active tracing session can be visualized in {{site.konnect_short_name}}'s built-in trace viewer. The trace viewer displays a **Summary** view and a **Trace** view. You can gain instant insights with the summary view while the trace view will help you dive deeper.

### Summary view  

The summary view helps you visualize the entire API request-response flow in a single glance. This view provides a concise overview of critical metrics and a transaction map. The transaction map includes the plugins executed by {{site.base_gateway}} on both the request and the response along with the times spent in each phase. Use the summary view to quickly understand the end-to-end API flow, identify performance bottlenecks, and optimize your API strategy. 

### Trace view

The trace view gives you unparalleled visibility into {{site.base_gateway}}'s internal workings. 
This detailed view breaks down into individual spans, providing a comprehensive understanding of:
- {{site.base_gateway}}'s internal processes and phases
- Plugin execution and performance
- Request and response handling

Use the trace view to troubleshoot issues, optimize performance, and refine your configuration.

## Get started with tracing

Active tracing requires the following Data Plane version and environment variables in `kong.conf`:

- **Version:** 3.9.1 or above
- **Environment variables:**
  - `KONG_CLUSTER_RPC=on`
  - `KONG_ACTIVE_TRACING=on`

{:.info}
> **Note:**
> Active tracing is currently limited to:
- Konnect Self-Managed Hybrid Gateways
- Konnect Dedicated Cloud Gateways
- Konnect Serverless Gateways
> <br><br>
> Active tracing is not supported on {{site.kic_product_name}} and {{site.event_gateway}} Gateways at this time.

### Start a trace session

1. Navigate to **Gateway Manager**.
2. Select a **Control Plane** which has the Data Plane to be traced.
3. Click on **Active Tracing** in left navigation menu.
4. Click **New tracing session**, define the criteria and, click **Start Session**.

Once started, traces will begin to be captured. Click on a trace to visualize it in the trace viewer.

The default session duration is 5 minutes or 200 traces per session. Note the sessions are retained for up to 7 days.

### Sampling rules

To capture only the relevant API traffic, use sampling rules. Sampling rules filter and refine the requests to be matched. The matching requests are then traced and captured in the session. There are two options. 
* **Basic sampling rules**: Allow filtering on Routes and Services.
* **Advanced sampling rules**: Specify the desired criteria using expressions. For example, to capture traces for all requests matching 503 response code, specify the following rule:
  ```
  http.response.status_code==503
  ```

### Known issues in tech preview

Here is a list of known issues in the tech preview:

- **Incorrect span orders**: When spans have very short duration few spans may be displayed in wrong order.
- **Incorrect handling of certain error conditions**: Traces may be broken when there are certain error conditions. For example, when DNS name resolution fails.
- **Missing spans during high traffic volumes**: When no sampling rule is enabled during a high traffic volume scenario, some traces could be missing spans.

## Sample trace

A sample trace is shown below. By inspecting the spans, it's clear that the bulk of the latency occurs in the pre-function plugin during the access phase.

![Active-Tracing Spans](/assets/images/konnect/active-tracing-spans.png)

## Spans

The following spans are available.
<!--vale off-->
### kong

The root span.

This span has the following attributes:
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`url.full`"
    description: Full url, without query parameters
  - name: "`client.address`"
    description: |
        Remote address of the client making the request. This considers forwarded addresses in cases when a load balancer is in front of Kong. Note: this requires configuring the real_ip_header and trusted_ips global configuration options.
  - name: "`client.port`"
    description: |
        Remote port of the client making the request. This considers forwarded ports in cases when a load balancer is in front of Kong. Note: this requires configuring the real_ip_header and trusted_ips global configuration options.
  - name: "`network.peer.address`"
    description: IP of the component that is connecting to Kong
  - name: "`network.peer.port`"
    description: Port of the component that is connecting to Kong
  - name: "`server.address`"
    description: Kong's DNS name or IP used in client connection
  - name: "`server.port`"
    description: Kong's public port
  - name: "`network.protocol.name`"
    description: HTTP, gRPC, WS, Kafka, etc.
  - name: "`http.request.method`"
    description: HTTP request method
  - name: "`http.request.body.size`"
    description: Request content length or equivalent in bytes
  - name: "`http.request.size`"
    description: Request body size and request headers size in bytes
  - name: "`http.response.body.size`"
    description: Response content length or equivalent in bytes
  - name: "`http.response.size`"
    description: Response body size and response headers size in bytes
  - name: "`kong.request.id`"
    description: Unique ID for each request
  - name: "`url.scheme`"
    description: Protocol identifier
  - name: "`network.protocol.version`"
    description: Version of the HTTP protocol used in establishing connection [1.2, 2.0]
  - name: "`tls.client.server_name`"
    description: SNI
  - name: "`http.request.header.host`"
    description: Host header if present. This can be different from the SNI.
  - name: "`proxy.kong.consumer_id`"
    description: Authenticated Consumer ID if present
  - name: "`proxy.kong.upstream_id`"
    description: Resolved Upstream ID
  - name: "`proxy.kong.upstream_status_code`"
    description: status code returned by upstream
  - name: "`http.response.status_code`"
    description: Status code sent back by Kong
  - name: "`proxy.kong.latency.upstream`"
    description: Time between the connection to the upstream and the last byte of response
  - name: "`proxy.kong.latency.total`"
    description: Time between the first byte into Kong and the last byte out of Kong
  - name: "`proxy.kong.latency.internal`"
    description: Time taken by Kong to process the request. Excludes client and upstream read/write times, and i/o times.
  - name: "`proxy.kong.latency.net_io_timings`"
    description: Array containing `ip`, `connect_time`, and `rw_time`. I/o outside of the request context is not considered.
  - name: "`proxy.kong.client_KA`"
    description: Whether the downstream used a KeepAlive connection
  - name: "`tls.resumed`"
    description: Whether the TLS session reused
  - name: "`tls.client.subject`"
    description: x509 client DN (if mTLS)
  - name: "`tls.server.subject`"
    description: x509 DN for cert Kong presented
  - name: "`tls.cipher`"
    description: Negotiated cipher
{% endtable %}
<!--vale on-->
### kong.phase.certificate

A span capturing the execution of the `certificate` phase of request processing. Any plugins configured for running in this phase will show up as individual child spans.

### kong.certificate.plugin.plugin_name

A span capturing the execution of a plugin configured to run in the `certificate` phase. Multiple such spans can occur in a trace.

This span has the following attributes:
{% capture instance_id %}
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`proxy.kong.plugin.instance_id`"
    description: Instance ID of the plugin configuration that ran
{% endtable %}
{% endcapture %}

{{instance_id}}


### kong.read_client_http_headers
A span capturing the time taken to read HTTP headers from the client. 
This span is useful for detecting clients that are coming over a slow network or a buggy CDN, or simply take too long to send in the HTTP headers.

This span has the following attributes:
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`proxy.kong.http_headers_count`"
    description: Number of headers sent by the client
  - name: "`proxy.kong.http_headers_size`"
    description: Size (in bytes) of headers sent by the client
{% endtable %}

### kong.read_client_http_body
A span capturing the total time taken to read the full body sent by the client. This span can identify slow clients, a buggy CDN and very large body submissions.

### kong.phase.rewrite
A span capturing the execution of the `rewrite` phase of request processing. Any plugins configured for running in this phase will show up as individual child spans.

### kong.rewrite.plugin.plugin_name
A span capturing the execution of a plugin configured to run in the `rewrite` phase. Multiple such spans can occur in a trace.

This span has the following attributes:
{{instance_id}}

### kong.io.function
A span capturing network i/o timing that occurs during plugin execution or other request processing. 

Can be one of:
* `kong.io.http.request`: Requests done by the internal http client during the flow
* `kong.io.http.connect`: Connections done by the internal http client during the flow
* `kong.io.redis.function`: Redis functions
* `kong.io.socket.function`: Functions called on the internal nginx socket

Examples:
* OIDC plugin making calls to IdP
* Rate Limiting Advanced plugin making calls to Redis
* Custom plugins calling HTTP URLs 

Multiple instances of this span can occur anywhere in the trace when i/o happens.

This span has the following attributes:
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`network.peer.address`"
    description: Address of the peer Kong connected with
  - name: "`network.protocol.name`"
    description: Protocol that was used (Redis, TCP, HTTP, gRPC, etc.)
{% endtable %}


### kong.router

A span capturing the execution of the Kong router.

This span has the following attributes:
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`proxy.kong.router.matched`"
    description: Whether the router find a match for the request
  - name: "`proxy.kong.router.route_id`"
    description: ID of the Route that was matched
  - name: "`proxy.kong.router.service_id`"
    description: ID of the Service that was matched
  - name: "`proxy.kong.router.upstream_path`"
    description: Path of the upstream url returned by the match
  - name: "`proxy.kong.router.cache_hit`"
    description: Whether the match returned from cache

{% endtable %}

### kong.phase.access
A span capturing the execution of the `access` phase of request processing. 
Any plugins configured for running in this phase will show up as individual child spans.

### kong.access.plugin.plugin_name
A span capturing the execution of a plugin configured to run in the `access` phase. Multiple such spans can occur in a trace.

This span has the following attributes:
{{instance_id}}


### kong.dns
A span capturing the time spent in looking up DNS.

This span has the following attributes:
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`proxy.kong.dns.entry`"
    description: A list of DNS attempts, responses and errors if any
{% endtable %}



### kong.upstream.selection
A span capturing the total time spent in finding a healthy upstream. 
Depending on configuration, Kong will try to find a healthy upstream by trying various targets in order determined by the load balancing algorithm. 
Child spans of this span capture the individual attempts.

This span has the following attributes:
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`proxy.kong.upstream.lb_algorithm`"
    description: the load balancing algorithm used for finding the upstream
{% endtable %}


### kong.upstream.find_upstream
A span capturing the attempt to verify a specific upstream. 
Kong attempts to open a TCP connection (if not KeepAlive cache is found), do a TLS handshake and send down the HTTP headers. 
If all of this succeeds, the upstream is healthy and Kong will finish sending the full request and wait for a response. 
If any of the step fails, Kong will switch to the next target and try again.

This span has the following attributes:
<!--vale off-->
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - name: "`network.peer.address`"
    description: the IP address of the target upstream
  - name: "`network.peer.name`"
    description: the DNS name of the target upstream
  - name: "`network.peer.port`"
    description: the port number of the target
  - name: "`try_count`"
    description: The number of attempts Kong has made to find a healthy upstream
  - name: "`keepalive`"
    description: Is this a KeepAlive connection?
{% endtable %}
<!--vale on-->

### kong.send_request_to_upstream
A span capturing the time taken to finish writing the http request to upstream.
This span can be used to identify network delays between Kong and an upstream.

### kong.read_headers_from_upstream
A span capturing the time taken for the upstream to generate the response headers. 
This span can be used to identify slowness in response generation from upstreams.

### kong.read_body_from_upstream
A span capturing the time taken for the upstream to generate the response body. 
This span can be used to identify slowness in response generation from upstreams.


### kong.phase.response
A span capturing the execution of the `response` phase. 
Any plugins configured for running in this phase will show up as individual child spans. This phase will not run if response streaming is enabled.

### kong.response.plugin.plugin_name
A span capturing the execution of a plugin configured to run in the `response` phase. Multiple such spans can occur in a trace.

This span has the following attributes:
{{instance_id}}


### kong.phase.header_filter
A span capturing the execution of the header filter phase of response processing. Any plugins configured for running in this phase will show up as individual child spans.

### kong.header_filter.plugin.plugin_name
A span capturing the execution of a plugin configured to run in the `header_filter` phase. Multiple such spans can occur in a trace.

This span has the following attributes:
{{instance_id}}

### kong.phase.body_filter
A span capturing the execution of the body filter phase of response processing. Any plugins configured for running in this phase will show up as individual child spans.

### kong.body_filter.plugin.plugin_name
A span capturing the execution of a plugin configured to run in the `body_filter` phase. Multiple such spans can occur in a trace.

This span has the following attributes:
{{instance_id}}

