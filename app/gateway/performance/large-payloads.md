---
title: "Tune {{site.base_gateway}} for large payloads"
content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem
    - konnect

tags:
    - performance

breadcrumbs:
    - /gateway/

description: "How {{site.base_gateway}} buffers request and response bodies, and how to tune buffer sizes for deployments handling large payloads."

related_resources:
  - text: "Optimize {{site.base_gateway}} performance"
    url: /gateway/performance/optimize/
  - text: Resource sizing guidelines
    url: /gateway/resource-sizing-guidelines/
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/
  - text: Nginx directives
    url: /gateway/nginx-directives/
---

{{site.base_gateway}} is optimized for API traffic. Most payloads are small JSON documents in the range of a few bytes to 10 KB. When your deployment handles larger payloads (SOAP/XML responses from legacy services, file uploads, batch operations, or web-oriented traffic like HTML and images), the default buffer configuration needs tuning to maintain throughput and protect against resource exhaustion.

## How buffering works

By default, {{site.base_gateway}} does not stream request and response bodies. It reads the entire payload into memory before forwarding it:

1. The client sends a request. {{site.base_gateway}} reads the bytes into a request buffer until the full request is received.
1. {{site.base_gateway}} processes the request and forwards it to the upstream.
1. The upstream sends a response. {{site.base_gateway}} reads it into a response buffer until the full response is received.
1. {{site.base_gateway}} forwards the complete response to the client.

{% mermaid %}
sequenceDiagram
    participant Client
    box Kong
        participant RB as Request buffer
        participant RSB as Response buffer
    end
    participant Upstream

    Client->>RB: Request
    RB->>Upstream: Forward request
    Upstream->>RSB: Response
    RSB->>Client: Forward response
{% endmermaid %}

With default buffering enabled, the upstream does not receive the request body until {{site.base_gateway}} has buffered it from the client. For responses, {{site.base_gateway}} begins forwarding data to the client only after it has buffered some of the response from the upstream, and may continue streaming as more data arrives. Each buffer is allocated per request, so buffer sizes compound quickly under load.

## Request buffers

{{site.base_gateway}} uses the following configuration options to buffer incoming requests:

<!-- vale off -->
{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
rows:
  - option: "`nginx_http_client_header_buffer_size`"
    description: Size of the buffer used to read HTTP request headers. The default works for most cases.
  - option: "`nginx_http_large_client_header_buffers`"
    description: |
      Additional buffers dynamically allocated when request headers exceed `nginx_http_client_header_buffer_size`. Format is `number size`. For example, `4 8k` allocates up to 4 buffers of 8 KB each, one at a time. Buffers are freed after the response is sent and the request is logged.
  - option: "`nginx_http_client_body_buffer_size`"
    description: Size of the buffer used to hold the request body.
  - option: "`nginx_http_client_max_body_size`"
    description: |
      Hard limit on the request body size. Requests exceeding this limit are rejected with a `413` error. Defaults to `0`, which disables the limit. Always set this value. Without it, large request bodies or many concurrent requests with large bodies can exhaust file system storage. For most APIs, `1m` is a reasonable starting point. Increase it gradually to fit your use case.
{% endtable %}
<!-- vale on -->

### When request buffers are exceeded

If the total size of the request headers exceeds the combined size of `nginx_http_client_header_buffer_size` and `nginx_http_large_client_header_buffers`, {{site.base_gateway}} returns a `414` or `400` error.

There are two separate controls for the request body because they serve different purposes. When the body exceeds `nginx_http_client_body_buffer_size` but is within `nginx_http_client_max_body_size`, {{site.base_gateway}} spills the excess to disk rather than rejecting the request. When the body exceeds `nginx_http_client_max_body_size`, {{site.base_gateway}} returns a `413` error.

{:.warning}
> If a plugin reads the request body and the body exceeds `nginx_http_client_body_buffer_size`, the plugin will fail. See the [PDK documentation](/gateway/pdk/reference/) for details.

## Response buffers

{{site.base_gateway}} uses two configuration options to buffer upstream responses:

<!-- vale off -->
{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
rows:
  - option: "`nginx_http_proxy_buffer_size`"
    description: Size of the buffer used to hold the response status line and HTTP headers. The default works for most cases.
  - option: "`nginx_http_proxy_buffers`"
    description: |
      Buffers dynamically allocated to hold the response body. Format is `number size`. The first number sets the maximum number of buffers that can be allocated. Increase it as needed while keeping the default `4k` for the buffer size to avoid cache inefficiencies.
{% endtable %}
<!-- vale on -->

### When response buffers are exceeded

If the response headers from the upstream exceed `nginx_http_proxy_buffer_size`, {{site.base_gateway}} returns a `502` error and logs:

```
upstream sent too big header while reading response header from upstream

Increasing `nginx_http_proxy_buffer_size` resolves this error.

If the response body exceeds the total size of `nginx_http_proxy_buffers`, {{site.base_gateway}} spills the excess to disk. 
When that happens, increase `nginx_http_proxy_buffers` or disable response buffering for that Route. 
For large responses where {{site.base_gateway}} is not inspecting or modifying the body (more than a few megabytes), disabling buffering is the better option.

## Disk buffering and performance

When {{site.base_gateway}} spills to disk, performance degrades for all concurrent requests, not just the large one. {{site.base_gateway}} uses a non-blocking event loop to handle many requests concurrently on a single thread. Disk I/O is a blocking system call on Linux, so one disk-buffered request stalls the event loop and increases latency for everything running at the same time.

{{site.base_gateway}} logs when disk buffering occurs:

```
a client request body is buffered to a temporary file
an upstream response is buffered to a temporary file

Monitor these log messages alongside disk I/O on {{site.base_gateway}} nodes. 
When they appear consistently, either increase the relevant buffer size or disable buffering for that Route. 
You can also set `nginx_http_proxy_max_temp_file_size` to `0` to prevent {{site.base_gateway}} from spilling response bodies to disk at all. 
{{site.base_gateway}} will stream the response instead.

## Memory considerations

Buffers are allocated per request. At 1,000 concurrent requests, increasing a buffer size by 1 MB adds roughly 1 GB of memory consumption. The actual impact varies depending on traffic shape, network speeds, and OS settings, so test {{site.base_gateway}} under realistic load when tuning buffer sizes. Increasing by a few memory pages at a time (each page being 4 KB) is safer than making large jumps.

## Disabling buffering

For large payloads where buffering is impractical, you can disable it per Route:

* `request_buffering: false`: {{site.base_gateway}} streams the request body to the upstream as the client sends it.
* `response_buffering: false`: {{site.base_gateway}} streams the response body to the client as the upstream sends it.

Disabling buffering also helps when optimizing for Time To First Byte (TTFB), since the client starts receiving data as soon as the upstream begins sending it rather than waiting for the full response to be buffered.

Disabling buffering only applies to the body. Headers are always buffered. At typical sizes, this adds negligible overhead.

By default, {{site.base_gateway}} buffers because reading and writing to a network socket requires a syscall. Streaming data in small chunks increases syscall frequency and CPU usage. Buffering reduces that overhead, which is the right default for small API payloads that fit in memory.

{:.warning}
> Disabling buffering exposes the upstream to slow clients, including [Slowloris attacks](https://www.cloudflare.com/learning/ddos/ddos-attack-tools/slowloris/). Use an authentication or authorization plugin to protect the upstream when buffering is disabled.

## Security considerations

{{site.base_gateway}} treats all clients as untrusted. Strict buffer limits prevent a malicious client from sending oversized requests that cause unbounded consumption of CPU, memory, disk, or network resources.

Avoid reading or modifying large request or response bodies inside {{site.base_gateway}} plugins. Processing large bodies adds latency and reduces throughput for all requests, regardless of payload size.

## Configuration reference


The following table shows which Nginx directives the kong.conf buffering options map to:

<!-- vale off -->
{% table %}
columns:
  - title: kong.conf option
    key: kong
  - title: Nginx directive
    key: nginx
rows:
  - kong: "`nginx_http_client_header_buffer_size`"
    nginx: "`client_header_buffer_size`"
  - kong: "`nginx_http_large_client_header_buffers`"
    nginx: "`large_client_header_buffers`"
  - kong: "`nginx_http_client_max_body_size`"
    nginx: "`client_max_body_size`"
  - kong: "`nginx_http_client_body_buffer_size`"
    nginx: "`client_body_buffer_size`"
  - kong: "`nginx_http_proxy_buffer_size`"
    nginx: "`proxy_buffer_size`"
  - kong: "`nginx_http_proxy_buffers`"
    nginx: "`proxy_buffers`"
  - kong: "`nginx_http_proxy_max_temp_file_size`"
    nginx: "`proxy_max_temp_file_size`"
{% endtable %}
<!-- vale on -->
