---
title: "Tuning {{site.base_gateway}} for large payloads"
content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem

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

{{site.base_gateway}} is optimized for API traffic. Most payloads are small JSON documents in the range of a few bytes to 10 KB. When your deployment handles larger payloads like SOAP/XML responses, file uploads, or batch operations, the default buffer configuration needs tuning to maintain throughput and protect against resource exhaustion.

## How buffering works

By default, {{site.base_gateway}} does not stream request and response bodies. It reads the entire payload into memory before forwarding it:

1. The client sends a request. {{site.base_gateway}} reads the bytes into a request buffer until the full request is received.
1. {{site.base_gateway}} processes the request and forwards it to the upstream.
1. The upstream sends a response. {{site.base_gateway}} reads it into a response buffer until the full response is received.
1. {{site.base_gateway}} forwards the complete response to the client.

Each buffer is allocated per request. Larger buffers mean more memory used per request, so they compound quickly under load.

## Request buffers

{{site.base_gateway}} uses three configuration options to buffer incoming requests:

* `nginx_http_client_header_buffer_size`: size of the buffer used to read HTTP request headers. The default works for most cases.
* `nginx_http_large_client_header_buffers`: additional buffers dynamically allocated when request headers exceed `nginx_http_client_header_buffer_size`. Format is `number size`, for example `4 8k` means up to 4 buffers of 8 KB each. Buffers are freed after the response is sent and the request is logged.
* `nginx_http_client_body_buffer_size`: size of the buffer used to hold the request body.
* `nginx_http_client_max_body_size`: hard limit on the request body size. Requests exceeding this limit are rejected with a `413` error. Defaults to `0`, which disables the limit.

### When request buffers are exceeded

If the total size of the request headers exceeds the combined size of `nginx_http_client_header_buffer_size` and `nginx_http_large_client_header_buffers`, {{site.base_gateway}} returns a `414` or `400` error to the client.

If the request body exceeds `nginx_http_client_body_buffer_size` but falls within `nginx_http_client_max_body_size`, {{site.base_gateway}} spills the excess to disk. If the body exceeds `nginx_http_client_max_body_size`, {{site.base_gateway}} returns a `413` error.

Setting `nginx_http_client_max_body_size` is strongly recommended. Without it, a large request body or many concurrent large requests can exhaust file system storage. For most APIs that don't handle large bodies, `1m` is a good starting point.

{:.warning}
> If a plugin reads the request body and the body exceeds `nginx_http_client_body_buffer_size`, the plugin will fail. See the [PDK documentation](/gateway/pdk/) for details.

## Response buffers

{{site.base_gateway}} uses two configuration options to buffer upstream responses:

* `nginx_http_proxy_buffer_size`: size of the buffer used to hold the response status line and HTTP headers. The default works for most cases.
* `nginx_http_proxy_buffers`: buffers dynamically allocated to hold the response body. Format is `number size`. The first number sets the maximum number of buffers that can be allocated. Increase it as needed while keeping the default `4k` for the buffer size to avoid cache inefficiencies.

### When response buffers are exceeded

If the response headers from the upstream exceed `nginx_http_proxy_buffer_size`, {{site.base_gateway}} returns a `502` error and logs:

```
upstream sent too big header while reading response header from upstream
```

Increasing `nginx_http_proxy_buffer_size` resolves this error.

If the response body exceeds the total size of `nginx_http_proxy_buffers`, {{site.base_gateway}} spills the excess to disk.

## Disk buffering and performance

When {{site.base_gateway}} spills to disk, performance degrades for all concurrent requests, not just the large one. {{site.base_gateway}} uses a non-blocking event loop to handle many requests concurrently on a single thread. Disk I/O is a blocking system call on Linux, so one disk-buffered request stalls the event loop and increases latency for everything running at the same time.

{{site.base_gateway}} logs when disk buffering occurs:

```
a client request body is buffered to a temporary file
an upstream response is buffered to a temporary file
```

Monitor these log messages alongside disk I/O on {{site.base_gateway}} nodes. When they appear consistently, either increase the relevant buffer size or disable buffering for that route.

## Memory considerations

Buffers are allocated per request. At 1,000 concurrent requests, increasing a buffer size by 1 MB adds roughly 1 GB of memory consumption. Test {{site.base_gateway}} under realistic load when tuning buffer sizes. Increasing by a few memory pages at a time, each page being 4 KB, is safer than making large jumps.

## Disabling buffering

For large payloads where buffering is impractical, you can disable it per route:

* `request_buffering: false`: {{site.base_gateway}} streams the request body to the upstream as the client sends it.
* `response_buffering: false`: {{site.base_gateway}} streams the response body to the client as the upstream sends it.

Disabling buffering only applies to the body. Headers are always buffered, but their size is small enough that this is not a concern.

{:.warning}
> Disabling buffering exposes the upstream to slow clients, including [Slowloris attacks](https://en.wikipedia.org/wiki/Slowloris_(computer_security)). Use an authentication or authorization plugin to protect the upstream when buffering is disabled.

## Security considerations

{{site.base_gateway}} treats all clients as untrusted. Strict buffer limits prevent a malicious client from sending oversized requests that cause unbounded consumption of CPU, memory, disk, or network resources. Always set `nginx_http_client_max_body_size` to enforce a hard limit on request body size.

Avoid reading or modifying large request or response bodies inside {{site.base_gateway}} plugins, which adds latency and reduces throughput for all requests regardless of payload size.

## Configuration reference

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
