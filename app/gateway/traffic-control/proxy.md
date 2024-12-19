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

{{ page.description }} This page details information about how {{site.base_gateway}} handles proxying. The following diagram shows how proxying is handled by {{site.base_gateway}}:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    actor Client
    participant Gateway as Kong Gateway
    participant Router
    participant Plugins as Plugins
    participant LoadBalancer as Load balancer
    participant UpstreamService as Upstream Service

    Client->>Gateway: Sends HTTP request or L4 connection
    Gateway->>Router: Evaluates incoming request against Routes
    Router->>Router: Orders Routes by priority
    Router->>Gateway: Returns highest priority matching Route
    Gateway->>Plugins: Executes plugins the `access` phase
    Gateway->>LoadBalancer: Implements load balancing capabilities
    LoadBalancer->>LoadBalancer: Distributes request across upstream service instances
    LoadBalancer->>UpstreamService: Forwards request to selected instance
    UpstreamService->>Gateway: Sends response
    Gateway->>Plugins: Executes plugins in the `header_filter` phase
    Gateway->>Client: Streams response back to client
{% endmermaid %}
<!--vale on-->

{{site.base_gateway}} handles proxying in the following order:

1. {{site.base_gateway}} listens for HTTP traffic on its configured
proxy port(s) (`8000` and `8443` by default) and L4 traffic on explicitly configured
`stream_listen` ports.
1. {{site.base_gateway}} will evaluate any incoming HTTP request or L4 connection against the Routes you have configured and try to find a matching one. For more details about how {{site.base_gateway}} handles routing, see the [Routes entity](/gateway/entities/route/).
1. If multiple Routes match, the {{site.base_gateway}} router then orders all defined Routes by their priority and uses the highest priority matching Route to handle a request.
1. If a given request matches the rules of a specific route, {{site.base_gateway}} will
run any global, Route, or Service [plugins]() before it proxies the request. Plugins configured on Routes run before those configured on Services. These configured plugins will run their `access` phase, which you can find more
information about in the [Plugin development guide][plugin-development-guide].
1. {{site.base_gateway}} implements [load balancing]() capabilities to distribute proxied
requests across a pool of instances of an upstream service.
1. Once {{site.base_gateway}} has executed all the necessary logic (including plugins), it is ready to forward the request to your upstream service. This is done via Nginx's [`ngx_http_proxy_module`](https://nginx.org/docs/http/ngx_http_proxy_module.html).
1. {{site.base_gateway}} receives the response from the upstream service and sends it back to the
downstream client in a streaming fashion. At this point, {{site.base_gateway}} executes
subsequent plugins added to the route and/or service that implement a hook in
the `header_filter` phase.

## Listeners

From a high-level perspective, {{site.base_gateway}} listens for HTTP traffic on its configured
proxy ports: `8000` and `8443` by default and L4 traffic on explicitly configured
`stream_listen` ports. {{site.base_gateway}} will evaluate any incoming
HTTP request or L4 connection against the routes you have configured and try to find a matching
one.

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

{{site.base_gateway}} is a transparent proxy, and it defaults to forwarding the request to your upstream service untouched, with the exception of various headers such as `Connection`, `Date`, and others as required by the HTTP specifications.

## Proxying

Once {{site.base_gateway}} has executed all the necessary logic (including plugins), it is ready
to forward the request to your upstream service. This is done with Nginx's
[`ngx_http_proxy_module`](https://nginx.org/docs/http/ngx_http_proxy_module.html). 

### Upstream timeouts

You can configure the desired
timeouts for the connection between {{site.base_gateway}} and a given Upstream, using the following properties of a [Service](/gateway/entities/service/):

- `connect_timeout`: Defines, in milliseconds, the timeout for
  establishing a connection to your upstream service. Defaults to `60000`.
- `write_timeout`: Defines, in milliseconds, a timeout between two
  successive write operations for transmitting a request to your upstream
  service.  Defaults to `60000`.
- `read_timeout`: Defines, in milliseconds, a timeout between two
  successive read operations for receiving a request from your upstream
  service.  Defaults to `60000`.

{{site.base_gateway}} will send the request over HTTP/1.1 and set the following headers:

<!--vale off-->

| Header                                  | Description |
|-----------------------------------------|-------------|
| `Host: <your_upstream_host>`            | The host of your Upstream. |
| `Connection: keep-alive`                | Allows for reusing the Upstream connections. |
| `X-Real-IP: <remote_addr>`              | Where `$remote_addr` is the variable bearing the same name provided by [ngx_http_core_module](https://nginx.org/docs/http/ngx_http_core_module.html#var_remote_addr). The `$remote_addr` is likely overridden by [ngx_http_realip_module](https://nginx.org/docs/http/ngx_http_realip_module.html). |
| `X-Forwarded-For: <address>`            | `<address>` is the content of `$realip_remote_addr` provided by [ngx_http_realip_module](https://nginx.org/docs/http/ngx_http_realip_module.html) appended to the request header with the same name. |
| `X-Forwarded-Proto: <protocol>`         | `<protocol>` is the protocol used by the client. If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. Otherwise, the value of the `$scheme` variable provided by [ngx_http_core_module](https://nginx.org/docs/http/ngx_http_core_module.html#var_scheme) will be used. |
| `X-Forwarded-Host: <host>`              | `<host>` is the host name sent by the client. If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. Otherwise, the value of the `$host` variable provided by [ngx_http_core_module](https://nginx.org/docs/http/ngx_http_core_module.html#var_host) will be used. |
| `X-Forwarded-Port: <port>`              | `<port>` is the port of the server which accepted a request. If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. Otherwise, the value of the `$server_port` variable provided by [ngx_http_core_module](https://nginx.org/docs/http/ngx_http_core_module.html#var_server_port) will be used. |
| `X-Forwarded-Prefix: <path>`            | `<path>` is the path of the request which was accepted by {{site.base_gateway}}. If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. Otherwise, the value of the `$request_uri` variable (with the query string stripped) provided by [ngx_http_core_module](https://nginx.org/docs/http/ngx_http_core_module.html#var_server_port) will be used. **Note**: {{site.base_gateway}} returns `"/"` for an empty path, but it doesn't do any other normalization on the request path. |
| All other headers | Forwarded as-is by {{site.base_gateway}} | 
<!--vale on-->

One exception to this is made when using the WebSocket protocol. {{site.base_gateway}}
sets the following headers to allow for upgrading the protocol between the
client and your upstream services:

- `Connection: Upgrade`
- `Upgrade: websocket`

More information on this topic is covered in the
[Proxy WebSocket traffic][proxy-websocket] section.

### Errors and retries during proxying

Whenever an error occurs during proxying, {{site.base_gateway}} uses the underlying
Nginx [retries](https://nginx.org/docs/http/ngx_http_proxy_module.html#proxy_next_upstream_tries) mechanism to pass the request on to
the next upstream.

There are two configurable elements:

1. The number of retries. This can be configured per Service using the
   `retries` property. See the [Admin API][API] for more details on this.

2. What exactly constitutes an error. Here {{site.base_gateway}} uses the Nginx defaults, which means an error or timeout that occurs while establishing a connection with the server, passing a request to it, or reading the response headers.

The second option is based on Nginx's 
[`proxy_next_upstream`](https://nginx.org/docs/http/ngx_http_proxy_module.html#proxy_next_upstream) directive. This option is not
directly configurable through {{site.base_gateway}}, but can be added using a custom Nginx
configuration. See the [configuration reference][configuration-reference] for
more details.

### Response streaming

{{site.base_gateway}} receives the response from the upstream service and sends it back to the
downstream client in a streaming fashion. At this point, {{site.base_gateway}} executes
subsequent plugins added to the route or service that implement a hook in
the `header_filter` phase.

Once the `header_filter` phase of all registered plugins has been executed, the
following headers are added by {{site.base_gateway}} and the full set of headers is sent to
the client:

| Header                                      | Description |
|---------------------------------------------|-------------|
| `Via: kong/x.x.x`                          | `x.x.x` is the {{site.base_gateway}} version in use. |
| `X-Kong-Proxy-Latency: <latency>`           | `latency` is the time, in milliseconds, between {{site.base_gateway}} receiving the request from the client and sending the request to your upstream service. |
| `X-Kong-Upstream-Latency: <latency>`        | `latency` is the time, in milliseconds, that {{site.base_gateway}} was waiting for the first byte of the upstream service response. |

Once the headers are sent to the client, {{site.base_gateway}} starts executing
registered plugins for the route or service that implement the
`body_filter` hook. This hook may be called multiple times, due to the
streaming nature of Nginx. Each chunk of the upstream response that is
successfully processed by such `body_filter` hooks is sent back to the client.
You can find more information about the `body_filter` hook in the [Plugin
development guide][plugin-development-guide].