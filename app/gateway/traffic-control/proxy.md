---
title: Proxying with {{site.base_gateway}}

description: "Proxying is when {{site.base_gateway}} matches an HTTP request with a [registered route](/gateway/entities/route/) and forwards the request."

content_type: reference
layout: reference

products:
  - gateway

related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: Router Expressions language
    url: /gateway/routing/expressions/
  - text: Expressions repository
    url: https://github.com/Kong/atc-router

breadcrumbs:
  - /gateway/
---

{{ page.description }} This doc explains how {{site.base_gateway}}'s proxying capabilities works in detail.

<!--should the list below be moved to a listeners type page? and then linked here???-->

{{site.base_gateway}} exposes several interfaces which can be tweaked by the following configuration properties:

- `proxy_listen`: Defines a list of addresses/ports on which {{site.base_gateway}} will
  accept **public HTTP (gRPC, WebSocket, etc) traffic** from clients and proxy
  it to your upstream services (`8000` by default).
- `admin_listen`, which also defines a list of addresses and ports, but those
  should be restricted to only be accessed by administrators, as they expose
  Kong's configuration capabilities: the **Admin API** (`8001` by default).
    {:.important}
   > **Important**: If you need to expose the `admin_listen` port to the internet in a production environment,
   > {% if_version lte:2.8.x %}[secure it with authentication](/gateway/{{include.release}}/admin-api/secure-admin-api/).{% endif_version %}{% if_version gte:3.0.x %}[secure it with authentication](/gateway/{{include.release}}/production/running-kong/secure-admin-api/).{% endif_version %}
- `stream_listen`, which is similar to `proxy_listen` but for Layer 4 (TCP, TLS)
  generic proxy. This is turned off by default.

## Overview
<!--list somewhere in here of the order of ops-->
From a high-level perspective, {{site.base_gateway}} listens for HTTP traffic on its configured
proxy port(s) (`8000` and `8443` by default) and L4 traffic on explicitly configured
`stream_listen` ports. {{site.base_gateway}} will evaluate any incoming
HTTP request or L4 connection against the routes you have configured and try to find a matching
one. If a given request matches the rules of a specific route, {{site.base_gateway}} will
process proxying the request.

Because each route may be linked to a service, {{site.base_gateway}} will run the plugins you
have configured on your route and its associated service, and then proxy the
request upstream. You can manage routes via {{site.base_gateway}}'s Admin API. Routes have
special attributes that are used for routing, matching incoming HTTP requests.
Routing attributes differ by subsystem (HTTP/HTTPS, gRPC/gRPCS, and TCP/TLS).

Subsystems and routing attributes:
- `http`: `methods`, `hosts`, `headers`, `paths` (and `snis`, if `https`)
- `tcp`: `sources`, `destinations` (and `snis`, if `tls`)
- `grpc`: `hosts`, `headers`, `paths` (and `snis`, if `grpcs`)

If you attempt to configure a route with a routing attribute it doesn't support
(e.g., an `http` route with `sources` or `destinations` fields), an error message
is reported:

```
HTTP/1.1 400 Bad Request
Content-Type: application/json
Server: kong/<x.x.x>

{
    "code": 2,
    "fields": {
        "sources": "cannot set 'sources' when 'protocols' is 'http' or 'https'"
    },
    "message": "schema violation (sources: cannot set 'sources' when 'protocols' is 'http' or 'https')",
    "name": "schema violation"
}
```

If {{site.base_gateway}} receives a request that it cannot match against any of the configured
routes (or if no routes are configured), it will respond with:

```http
HTTP/1.1 404 Not Found
Content-Type: application/json
Server: kong/<x.x.x>

{
    "message": "no route and no Service found with those values"
}
```

### Load balancing

{{site.base_gateway}} implements load balancing capabilities to distribute proxied
requests across a pool of instances of an upstream service.

You can find more information about configuring load balancing by consulting
the [Load Balancing Reference][load-balancing-reference].

### Plugins execution

{{site.base_gateway}} is extensible via "plugins" that hook themselves in the request/response
lifecycle of the proxied requests. Plugins can perform a variety of operations
in your environment and/or transformations on the proxied request.

Plugins can be configured to run globally (for all proxied traffic) or on
specific routes and services. In both cases, you must create a [plugin
configuration][plugin-configuration-object] via the Admin API.

Once a route has been matched (and its associated service entity), {{site.base_gateway}} will
run plugins associated to either of those entities. Plugins configured on a
route run before plugins configured on a service, but otherwise, the usual
rules of [plugins association][plugin-association-rules] apply.

These configured plugins will run their `access` phase, which you can find more
information about in the [Plugin development guide][plugin-development-guide].

### Proxying and upstream timeouts

Once {{site.base_gateway}} has executed all the necessary logic (including plugins), it is ready
to forward the request to your upstream service. This is done via Nginx's
[`ngx_http_proxy_module`][ngx-http-proxy-module]. You can configure the desired
timeouts for the connection between {{site.base_gateway}} and a given upstream, via the following
properties of a service:

- `connect_timeout`: defines in milliseconds the timeout for
  establishing a connection to your upstream service. Defaults to `60000`.
- `write_timeout`: defines in milliseconds a timeout between two
  successive write operations for transmitting a request to your upstream
  service.  Defaults to `60000`.
- `read_timeout`: defines in milliseconds a timeout between two
  successive read operations for receiving a request from your upstream
  service.  Defaults to `60000`.

{{site.base_gateway}} will send the request over HTTP/1.1, and set the following headers:

<!-- vale off -->
- `Host: <your_upstream_host>`, as previously described in this document.
- `Connection: keep-alive`, to allow for reusing the upstream connections.
- `X-Real-IP: <remote_addr>`, where `$remote_addr` is the variable bearing
  the same name provided by
  [ngx_http_core_module][ngx-remote-addr-variable]. Please note that the
  `$remote_addr` is likely overridden by
  [ngx_http_realip_module][ngx-http-realip-module].
- `X-Forwarded-For: <address>`, where `<address>` is the content of
  `$realip_remote_addr` provided by
  [ngx_http_realip_module][ngx-http-realip-module] appended to the request
  header with the same name.
- `X-Forwarded-Proto: <protocol>`, where `<protocol>` is the protocol used by
  the client. In the case where `$realip_remote_addr` is one of the **trusted**
  addresses, the request header with the same name gets forwarded if provided.
  Otherwise, the value of the `$scheme` variable provided by
  [ngx_http_core_module][ngx-scheme-variable] will be used.
- `X-Forwarded-Host: <host>`, where `<host>` is the host name sent by
  the client. In the case where `$realip_remote_addr` is one of the **trusted**
  addresses, the request header with the same name gets forwarded if provided.
  Otherwise, the value of the `$host` variable provided by
  [ngx_http_core_module][ngx-host-variable] will be used.
- `X-Forwarded-Port: <port>`, where `<port>` is the port of the server which
  accepted a request. In the case where `$realip_remote_addr` is one of the
  **trusted** addresses, the request header with the same name gets forwarded
  if provided. Otherwise, the value of the `$server_port` variable provided by
  [ngx_http_core_module][ngx-server-port-variable] will be used.
- `X-Forwarded-Prefix: <path>`, where `<path>` is the path of the request which
  was accepted by {{site.base_gateway}}. In the case where `$realip_remote_addr` is one of the
  **trusted** addresses, the request header with the same name gets forwarded
  if provided. Otherwise, the value of the `$request_uri` variable (with
  the query string stripped) provided by [ngx_http_core_module][ngx-server-port-variable]
  will be used.
<!-- vale on-->

  {:.note}
  > **Note**: {{site.base_gateway}} returns `"/"` for an empty path, but it doesn't do any other
  > normalization on the request path.

All the other request headers are forwarded as-is by {{site.base_gateway}}.

One exception to this is made when using the WebSocket protocol. If so, {{site.base_gateway}}
sets the following headers to allow for upgrading the protocol between the
client and your upstream services:

- `Connection: Upgrade`
- `Upgrade: websocket`

More information on this topic is covered in the
[Proxy WebSocket traffic][proxy-websocket] section.

### Errors and retries

Whenever an error occurs during proxying, {{site.base_gateway}} uses the underlying
Nginx [retries][ngx-http-proxy-retries] mechanism to pass the request on to
the next upstream.

There are two configurable elements here:

1. The number of retries: this can be configured per service using the
   `retries` property. See the [Admin API][API] for more details on this.

2. What exactly constitutes an error: here {{site.base_gateway}} uses the Nginx defaults, which
   means an error or timeout occurring while establishing a connection with the
   server, passing a request to it, or reading the response headers.

The second option is based on Nginx's 
[`proxy_next_upstream`](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_next_upstream) directive. This option is not
directly configurable through {{site.base_gateway}}, but can be added using a custom Nginx
configuration. See the [configuration reference][configuration-reference] for
more details.

### Response

{{site.base_gateway}} receives the response from the upstream service and sends it back to the
downstream client in a streaming fashion. At this point, {{site.base_gateway}} executes
subsequent plugins added to the route and/or service that implement a hook in
the `header_filter` phase.

Once the `header_filter` phase of all registered plugins has been executed, the
following headers are added by {{site.base_gateway}} and the full set of headers be sent to
the client:

- `Via: kong/x.x.x`, where `x.x.x` is the {{site.base_gateway}} version in use
- `X-Kong-Proxy-Latency: <latency>`, where `latency` is the time in milliseconds
  between {{site.base_gateway}} receiving the request from the client and sending the request to
  your upstream service.
- `X-Kong-Upstream-Latency: <latency>`, where `latency` is the time in
  milliseconds that {{site.base_gateway}} was waiting for the first byte of the upstream service
  response.

Once the headers are sent to the client, {{site.base_gateway}} starts executing
registered plugins for the route and/or service that implement the
`body_filter` hook. This hook may be called multiple times, due to the
streaming nature of Nginx. Each chunk of the upstream response that is
successfully processed by such `body_filter` hooks is sent back to the client.
You can find more information about the `body_filter` hook in the [Plugin
development guide][plugin-development-guide].