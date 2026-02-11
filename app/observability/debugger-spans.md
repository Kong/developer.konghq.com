---
title: Debugger spans
description: 'Spans represent a single unit of trace in {{site.base_gateway}} this page contains all available spans.'
breadcrumbs:
  - /observability/
  - /observability/debugger/
content_type: reference
layout: reference
search_aliases: 
  - active tracing
  - debugger
products:
    - konnect
    - observability
works_on:
    - konnect
tags:
  - tracing
  - debugger
related_resources:
  - text: The {{site.konnect_short_name}} Debugger
    url: /observability/debugger/
---



When you set up a tracing session with [{{site.konnect_short_name}} Debugger](/observability/debugger/), it collects and reports spans that detail {{site.konnect_short_name}} events.
The following sections describe the spans that are available in the {{site.konnect_short_name}} Debugger.
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
  - name: "`proxy.kong.request.id`"
    description: Unique id for each request
  - name: "`proxy.kong.request.time`"
    description: Request time as measured by Nginx ($request_time)
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
    description: status code returned by Upstream
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
    description: Whether the downstream used a KeepAlive connection.
  - name: "`tls.resumed`"
    description: Whether the TLS session resumed.
  - name: "`tls.client.subject`"
    description: x509 client DN (if mTLS).
  - name: "`tls.server.subject`"
    description: x509 DN for cert Kong presented.
  - name: "`tls.cipher`"
    description: Negotiated cipher.
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

## kong.tls_handshake
A span that captures the execution of the TLS handshake between the client and Kong. This span includes any I/O operations involved in the handshake, which may be prolonged due to slow client behavior.

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

A span capturing the execution of the {{site.base_gateway}} router.

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
{{site.base_gateway}} attempts to open a TCP connection (if not `KeepAlive` cache is found), do a TLS handshake and send down the HTTP headers. 
If all of this succeeds, the upstream is healthy and Kong will finish sending the full request and wait for a response. 
If any of the step fails, {{site.base_gateway}} will switch to the next target and try again.

The last of these spans (or the only one, if the first attempt succeeds) ends as soon as the connection is established, 
ensuring that the total time captured by the parent `kong.upstream.selection` span always reflects only the time 
spent *connecting* to the selected upstream.

Depending on how the [`proxy_next_upstream`](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_next_upstream) directive is configured, earlier (failed) tries may involve additional I/O. 
For example, if retries are triggered based on the upstream’s status code or header validity, those attempts will include sending the request and reading the response status line and headers which is enough for Kong to determine whether to retry.

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
    description: Checks if it is a `KeepAlive` connection.
{% endtable %}
<!--vale on-->

### kong.send_request_to_upstream
A span capturing the time taken to write the http request to the upstream.
This span can be used to identify network delays between Kong and an upstream.

### kong.read_headers_from_upstream
A span capturing the time taken for the upstream to generate the response headers. 
This span can be used to identify slowness in response generation from upstreams.
If there is a delay after the request is sent but before the upstream starts responding, that **time to first byte** is also included in this span.

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

### kong.wait_for_client_read
A span that measures the time Kong spends finishing the response write to the client. This duration may be extended for slow-reading clients, resulting in a longer span.