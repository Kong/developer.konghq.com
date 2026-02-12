---
title: Proxying with {{site.base_gateway}}

description: "Proxying is when {{site.base_gateway}} matches an HTTP request with a registered Route and forwards the request."

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
  - text: Traffic control and routing
    url: /gateway/traffic-control-and-routing/

breadcrumbs:
  - /gateway/traffic-control-and-routing/

works_on:
  - on-prem
  - konnect

search_aliases:
  - websocket connections
---

Proxying is when {{site.base_gateway}} matches an HTTP request with a [Route](/gateway/entities/route/) and forwards the request. This page explains how {{site.base_gateway}} handles proxying.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    actor Client
    participant Gateway as Kong Gateway
    participant Router
    participant Plugins as Plugins
    participant LoadBalancer as Load balancer
    participant UpstreamService as Upstream service

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

1. {{site.base_gateway}} listens for HTTP traffic on its configured proxy port(s) (`8000` and `8443` by default) and L4 traffic on explicitly configured
[`stream_listen`](/gateway/configuration/#stream-listen) ports.
1. {{site.base_gateway}} evaluates any incoming HTTP request or L4 connection against the Routes you have configured and tries to find a matching one. 
For more details about how {{site.base_gateway}} handles routing, see the [Routes entity](/gateway/entities/route/).
1. If multiple Routes match, the {{site.base_gateway}} router then orders all defined Routes by their priority and uses the highest priority matching Route to handle a request.
1. If a given request matches the rules of a specific Route, {{site.base_gateway}} runs any global, Route, or Gateway Service [plugins](/gateway/entities/plugin/) before it proxies the request. 
Plugins configured on Routes run before those configured on Services. 
These configured plugins run their `access` phase. 
For more information, see [plugin contexts](/gateway/entities/plugin/#plugin-contexts).
1. {{site.base_gateway}} implements [load balancing](/gateway/traffic-control/load-balancing-reference/) capabilities 
to distribute proxied requests across a pool of instances of an upstream service.
1. Once {{site.base_gateway}} has executed all the necessary logic (including plugins), it's ready to forward the request to your upstream service. 
This is done via Nginx's [`ngx_http_proxy_module`](https://nginx.org/docs/http/ngx_http_proxy_module.html).
1. {{site.base_gateway}} receives the response from the upstream service and sends it back to the downstream client in a streaming fashion. 
At this point, {{site.base_gateway}} executes subsequent plugins added to the Route and/or Service that implement a hook in the `header_filter` phase.

## Listeners

From a high-level perspective, {{site.base_gateway}} listens for HTTP traffic on its configured
proxy ports (`8000` and `8443` by default) and L4 traffic on explicitly configured
`stream_listen` ports. {{site.base_gateway}} will evaluate any incoming
HTTP request or L4 connection against the Routes you have configured and try to find a matching
one.

{{site.base_gateway}} exposes several interfaces which can be configured by the following properties:

- [`proxy_listen`](/gateway/configuration/#proxy-listen): Defines a list of addresses/ports on which {{site.base_gateway}}
  accepts public HTTP (gRPC, WebSocket, etc.) traffic from clients and proxies it to your upstream services (`8000` by default).
- [`admin_listen`](/gateway/configuration/#admin-listen): Also defines a list of addresses and ports, but those
  should be restricted to only administrators, as they expose
  {{site.base_gateway}}'s configuration capabilities via the Admin API (`8001` by default).
    {:.warning}
    > **Important**: If you need to expose the `admin_listen` port to the internet in a production environment,
    > [secure it with authentication](/gateway/secure-the-admin-api/).
- [`stream_listen`](/gateway/configuration/#stream-listen): Similar to `proxy_listen`, but for Layer 4 (TCP, TLS)
  generic proxy. This is turned off by default.

{{site.base_gateway}} is a transparent proxy, and it defaults to forwarding the request to your upstream service untouched, with the exception of various headers such as `Connection`, `Date`, and others as required by the HTTP specifications.

## Proxying and upstream timeouts

You can configure the desired
timeouts for the connection between {{site.base_gateway}} and a given [Upstream](/gateway/entities/upstream/) using the following properties of a [Gateway Service](/gateway/entities/service/):

- `connect_timeout`: Defines, in milliseconds, the timeout for
  establishing a connection to your upstream service. Defaults to `60000`.
- `write_timeout`: Defines, in milliseconds, a timeout between two
  successive write operations for transmitting a request to your upstream
  service.  Defaults to `60000`.
- `read_timeout`: Defines, in milliseconds, a timeout between two
  successive read operations for receiving a request from your upstream
  service.  Defaults to `60000`.

{{site.base_gateway}} sends the request over HTTP/1.1 and sets the following headers:
{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`Host: <your_upstream_host>`"
    description: The host of your Upstream.
  - header: "`Connection: keep-alive`"
    description: Allows for reusing the Upstream connections.
  - header: "`X-Real-IP: <remote_addr>`"  
    description: "`$remote_addr` is the variable bearing the same name provided by [`ngx_http_core_module`](https://nginx.org/docs/http/ngx_http_core_module.html#var_remote_addr). `$remote_addr` is likely overridden by [ngx_http_realip_module](https://nginx.org/docs/http/ngx_http_realip_module.html)."
  - header: "`X-Forwarded-For: <address>`"      
    description: "`<address>` is the content of `$realip_remote_addr` provided by [`ngx_http_realip_module`](https://nginx.org/docs/http/ngx_http_realip_module.html) appended to the request header with the same name."
  - header: "`X-Forwarded-Proto: <protocol>`"
    description: |
      `<protocol>` is the protocol used by the client. 
      If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. 
      Otherwise, the value of the `$scheme` variable provided by [`ngx_http_core_module`](https://nginx.org/docs/http/ngx_http_core_module.html#var_scheme) will be used.
  - header: "`X-Forwarded-Host: <host>`"
    description: |
      `<host>` is the host name sent by the client. 
      If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. Otherwise, the value of the `$host` variable provided by [`ngx_http_core_module`](https://nginx.org/docs/http/ngx_http_core_module.html#var_host) will be used.
  - header: "`X-Forwarded-Port: <port>`"
    description: |
      `<port>` is the port of the server which accepted a request.
      If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. 
      Otherwise, the value of the `$server_port` variable provided by [`ngx_http_core_module`](https://nginx.org/docs/http/ngx_http_core_module.html#var_server_port) will be used.
  - header: "`X-Forwarded-Prefix: <path>`"
    description:  |
      `<path>` is the path of the request which was accepted by {{site.base_gateway}}. 
      If `$realip_remote_addr` is one of the **trusted** addresses, the request header with the same name gets forwarded if provided. 
      Otherwise, the value of the `$request_uri` variable (with the query string stripped) provided by [`ngx_http_core_module`](https://nginx.org/docs/http/ngx_http_core_module.html#var_server_port) will be used. 
      
      {:.info}
      > **Note**: {{site.base_gateway}} returns `"/"` for an empty path, but it doesn't do any other normalization on the request path.
  - header: All other headers
    description: Forwarded as-is by {{site.base_gateway}}.
{% endtable %}

One exception to this is when you're using the WebSocket protocol,{{site.base_gateway}}
sets the following headers to allow for upgrading the protocol between the
client and your upstream services:

- `Connection: Upgrade`
- `Upgrade: websocket`

For more information, see the [Proxy WebSocket traffic](#proxy-websocket-traffic) section.

## Errors and retries

Whenever an error occurs during proxying, {{site.base_gateway}} uses the underlying
Nginx [retries](https://nginx.org/docs/http/ngx_http_proxy_module.html#proxy_next_upstream_tries) mechanism to pass the request on to
the next upstream.

There are two configurable elements:

1. The number of retries. This can be configured per Service using the [`retries`](/gateway/entities/service/#schema-service-retries) property.
1. What exactly constitutes an error. Here {{site.base_gateway}} uses the Nginx defaults, which means an error or timeout that occurs while establishing a connection with the server, passing a request to it, or reading the response headers. 
This is based on Nginx's [`proxy_next_upstream`](https://nginx.org/docs/http/ngx_http_proxy_module.html#proxy_next_upstream) directive. 
This option is not directly configurable through {{site.base_gateway}}, but can be added using a custom Nginx configuration. 
See the [Nginx directives reference](/gateway/nginx-directives/) for more details.

## Response

{{site.base_gateway}} receives the response from the upstream service and sends it back to the downstream client in a streaming fashion. 
At this point, {{site.base_gateway}} executes subsequent plugins added to the Route or Service that implement a hook in the `header_filter` phase.

Once the `header_filter` phase of all registered plugins has been executed and the `latency_token` option {% new_in 3.11 %} is enabled, the following headers are added by {{site.base_gateway}} and the full set of headers is sent to the client:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`Via: kong/x.x.x`"
    description: "`x.x.x` is the {{site.base_gateway}} version in use."
  - header: "`X-Kong-Proxy-Latency: <latency>`"
    description: "`latency` is the time, in milliseconds, between {{site.base_gateway}} receiving the request from the client and sending the request to your upstream service."
  - header: "`X-Kong-Upstream-Latency: <latency>`"
    description: "`latency` is the time, in milliseconds, that {{site.base_gateway}} was waiting for the first byte of the upstream service response."
{% endtable %}

{:.warning}
> **Important:** These latency headers are reported during the `header_filter` phase, which may occur before the full response body has been processed.
<br><br>
> In scenarios where body processing takes significant time, the latency values in these headers might not reflect the complete duration of the request lifecycle. For more accurate and comprehensive latency data, consider using the [Debugger in {{site.konnect_short_name}}](/observability/debugger/), the [Analytics feature in {{site.konnect_short_name}}](/observability/), a metrics plugin like [Prometheus](/plugins/prometheus/), or a [logging plugin](/plugins/?category=logging). 

Once the headers are sent to the client, {{site.base_gateway}} starts executing plugins for the Route or Service that implement the
`body_filter` hook. 
This hook may be called multiple times, due to the streaming nature of Nginx. 
Each chunk of the upstream response that is successfully processed by such `body_filter` hooks is sent back to the client.

You can also use `advanced_latency_tokens` {% new_in 3.11 %} to expose more detailed timing headers, such as total latency, third-party latency, and client latency. 
For more information, see the [Kong configuration reference](/gateway/configuration/#advanced-latency-tokens).

## Proxy WebSocket traffic

{{site.base_gateway}} supports WebSocket traffic thanks to the underlying Nginx implementation.
When you want to establish a WebSocket connection between a client and your upstream services through {{site.base_gateway}}, you must establish a WebSocket handshake.
This is done via the HTTP Upgrade mechanism. 
This is what your client request made to {{site.base_gateway}} would look like:
```
GET / HTTP/1.1
Connection: Upgrade
Host: my-websocket-api.com
Upgrade: WebSocket
```

This configures {{site.base_gateway}} to forward the `Connection` and `Upgrade` headers to your upstream service instead of dismissing them due to the hop-by-hop nature of a standard HTTP proxy.

### WebSocket proxy modes

There are two methods for proxying WebSocket traffic in {{site.base_gateway}}:

* HTTP(S) Services and Routes
* WS(S) Services and Routes

#### HTTP(S) Services and Routes

Services and Routes using the `http` and `https` protocols are fully capable of handling WebSocket connections with no special configuration.
With this method, WebSocket sessions behave identically to regular HTTP requests, and all of the request and response data is treated as an opaque stream of bytes.

Here's a configuration example:
{% entity_example %}
type: service
data:
  name: my-http-websocket-service
  protocol: http
  host: 1.2.3.4
  port: 80
  path: /
  routes:
    - name: my-http-websocket-route
      protocols:
        - http
        - https
formats:
  - deck 
{% endentity_example %}


#### WS(S) Services and Routes

In addition to HTTP Services and Routes, {{site.base_gateway}} includes the `ws` (WebSocket-over-http) and `wss` (WebSocket-over-https) protocols.
Unlike `http` and `https`, `ws` and `wss` Services have full control over the underlying WebSocket connection.
This means that they can use WebSocket plugins and the [WebSocket PDK](/gateway/pdk/reference/kong.websocket.client/) to perform business logic on a per-message basis (message validation, accounting, rate-limiting, etc).

Here's a configuration example:
{% entity_example %}
type: service
data:
  name: my-dedicated-websocket-service
  protocol: ws
  host: 1.2.3.4
  port: 80
  path: /
  routes:
    - name: my-dedicated-websocket-route
      protocols:
        - ws
        - wss
formats:
  - deck 
{% endentity_example %}

{:.info}
> **Note**:
> Decoding and encoding WebSocket messages comes with a non-zero amount of performance overhead when compared with the protocol-agnostic behavior of `http(s)` Services. 
> If your API doesn't need the extra capabilities provided by a `ws(s)` Service, we recommend using an `http(s)` Service instead.

### WebSocket and TLS

Regardless of which Service/Route protocols are in use (`http(s)` or `ws(s)`), {{site.base_gateway}} will accept plain and TLS WebSocket connections on its respective `http` and `https` ports. 
To enforce TLS connections from clients, set the `protocols` property of the [Route](/gateway/entities/route/) to `https` or `wss`
only.

When setting up the [Service](/gateway/entities/service/) to point to your upstream WebSocket service, you should carefully pick the protocol you want to use between {{site.base_gateway}} and the upstream service.

If you want to use TLS, your upstream WebSocket service must be defined using the `https` (or `wss`) protocol in the Gateway Service `protocol` property and the proper port (usually 443). 
To connect without TLS, then the `http` (or `ws`) protocol and port (usually 80) should be used in instead.

If you want {{site.base_gateway}} to terminate TLS, you can accept `https`/`wss` only from the client, but proxy to the upstream service over plain text (`http` or `ws`).

## Proxy gRPC traffic

gRPC proxying is natively supported in {{site.base_gateway}}. 
To manage gRPC Services and proxy gRPC requests with {{site.base_gateway}}, create Services and Routes for your gRPC services.

Only observability and [logging](/plugins/?category=logging) plugins are supported with gRPC. 
Plugins that support gRPC have `grpc` and `grpcs` in the list of compatible protocols. 
This is the case for [File Log](/plugins/file-log/), for example.

## Proxy TCP/TLS traffic

TCP and TLS proxying is natively supported in {{site.base_gateway}}.

In this mode, data of incoming connections reaching the [`stream_listen`](/gateway/configuration/#stream-listen) endpoints will be passed through to the upstream service. 
It's possible to terminate TLS connections from clients using this mode as well.

To use this mode, aside from defining `stream_listen`, you should create the appropriate Route/Service object with the `tcp` or `tls` protocol.

If you want to terminate TLS with {{site.base_gateway}}, the following conditions must be met:
1. The {{site.base_gateway}} port used by the TLS connection to must have the `ssl` flag enabled
1. A certificate/key that can be used for TLS termination must be present inside {{site.base_gateway}}, as shown in [TLS Route configuration](/gateway/entities/route/#tls-route-configuration)

{{site.base_gateway}} will use the connecting client's TLS SNI server name extension to find the appropriate TLS certificate to use.

On the Service side, depending on whether the connection between {{site.base_gateway}} and the upstream
service needs to be encrypted, you can set either the `tcp` or `tls` protocol.
This means the following setup is supported in this mode:

1. Client <- TLS -> {{site.base_gateway}} <- TLS -> Upstream
1. Client <- TLS -> {{site.base_gateway}} <- Cleartext -> Upstream
1. Client <- Cleartext -> {{site.base_gateway}} <- TLS -> Upstream

{:.info}
> **Note**: In L4 proxy mode, only certain plugins support the `tcp` or `tls` protocol. You can find the list of supported protocols for each plugin in the [Plugin Hub](/plugins/).

