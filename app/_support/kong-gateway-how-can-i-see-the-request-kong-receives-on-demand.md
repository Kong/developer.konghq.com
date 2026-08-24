---
title: View the request Kong Gateway receives on demand using the Request Termination plugin
content_type: support
description: "Use the Request Termination plugin's `config.echo` and `config.trigger` settings to echo back the full request — headers, body, and matched route/service — on demand for a single request."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Request Termination plugin reference"
    url: "/plugins/request-termination/"
tldr:
  q: How can I see the request Kong receives on-demand?
  a: |
    Enable `config.echo` on the Request Termination plugin to echo back the request Kong receives — headers, body, and matched route/service. Set `config.trigger` to an arbitrary string so only requests carrying that string as a header or query parameter trigger the echo, keeping it non-intrusive for normal traffic.
---

## Problem

When troubleshooting an issue, you may need to see the full request Kong receives — including headers and request body — without exposing that data for every request.

## Solution

The Request Termination plugin allows for this behavior.

By setting `config.echo` to true the Gateway will echo back the following data:

- `node_id`: Node ID of the Kong node that handled the request
- `worker_pid`: nginx worker PID that handled the request
- `hostname`: The hostname of the machine that handled the request
- request scheme: The scheme component of the request's URL.
- `request_host`: The host component of the request's URL, or the value of the "Host" header
- request port: The port component of the request's URL
- `request_headers`: The request headers received by Kong
- `request_query`: The query arguments obtained from the query string
- `request_body`: The request body received by Kong
- `request_method`: The HTTP method of the request.
- `request_path`: The normalized path component of the request's URL
- `matched_route`: The Kong route that matched the request (including route properties such as `path`, `protocols`, `strip_path`, etc.)
- `matched_service`: The Kong service that matched the request (including service properties such as connect/read/write timeouts, etc.)

To set this on-demand, configure the `config.trigger` setting to an arbitrary string. Doing so allows only requests containing this string as a header or query parameter to activate the plugin and echo back the request.

For example: `config.trigger=x-gruber`

```bash
curl -H "x-gruber:1" localhost:8000/echo --data "name":"value"
(output shortened for readability)

"kong": {..."hostname": "kong-node1},
  "message": "Service unavailable",
  "matched_service": {..."read_timeout": 60000,"path": "/anything"},
  "matched_route": {..."path_handling": "v0","paths": ["/echo"],"strip_path": true},
  "request": {
    "path": "/echo",
    "headers": {..."host": "localhost:8000","x-gruber": "1" },
    "port": 8000,
    "host": "localhost",
    "method": "POST",
    "scheme": "http",
    "raw_body": "name:value"
  }
}
```
