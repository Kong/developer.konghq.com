---
title: "Kong Gateway: How to get OpenTelemetry Span ID and Trace ID inside the file log plugin"
content_type: support
published: false
description: The OpenTelemetry plugin automatically appends the headers for whichever tracing utility is being utilized.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I get the OpenTelemetry Span ID and Trace ID inside the file-log plugin?
  a: |
    The OpenTelemetry plugin appends a `traceparent` header to the request. Its value has the form `00-<trace_id>-<span_id>-01`, so the first segment is the Trace ID and the second is the Span ID.
    The file-log plugin records request headers, so the `traceparent` header (and therefore both IDs) appears in the logged request headers.
---

## Logging the OpenTelemetry Span ID and Trace ID in the file-log plugin

We are utilizing the OpenTelemetry plugin and the file log plugin. We have a requirement where we need the Span ID and Trace ID inside the file log. How can we log these 2 fields?

The OpenTelemetry plugin automatically appends the headers for whichever tracing utility is being utilized.

For example if Zipkin is being utilized, then you will notice a `traceparent` header being appended.

```json
"traceparent": "00-72a6c1be825f5339cacd16c58254835c-2b1f74d3b0939afd-01"
```

This contains both your TraceID and your SpanID.

The first larger string is your TraceID and the smaller string is your SpanID.

```
traceid = 72a6c1be825f5339cacd16c58254835c
spanid = 2b1f74d3b0939afd
```

Now when we utilize the file log plugin these headers will be appended to the Request Headers section.

```json
    "request": {
        "method": "GET",
        "size": 118,
        "headers": {
            "traceparent": "00-72a6c1be825f5339cacd16c58254835c-2b1f74d3b0939afd-01",
            "accept": "*/*",
            "host": "localhost:8000",
            "user-agent": "insomnia/2023.1.0",
            "kong-debug": "1"
        }
```
