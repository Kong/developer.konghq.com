The following functions are used to implement plugin logic at various entry-points of {{site.base_gateway}}'s execution life-cycle:

{% navtabs "requests" %}
{% navtab "HTTP module" %}
The [HTTP module](https://github.com/openresty/lua-nginx-module) is used for plugins written for HTTP/HTTPS requests. It uses the following functions:
{% table %}
columns:
  - title: Function name
    key: function
  - title: "{{site.base_gateway}} phase"
    key: phase
  - title: Nginx directives
    key: nginx
  - title: Request protocols
    key: protocols
  - title: Description
    key: description
rows: 
  - function: "`init_worker`"
    phase: "`init_worker`"
    nginx: "[`init_worker_by_*`](https://github.com/openresty/lua-nginx-module#init_worker_by_lua_block)"
    protocols: All protocols
    description: Executed upon every Nginx worker process's startup.
  - function: "`configure`"
    phase:  |
        * `init_worker`
        * `timer`
    nginx: "[`init_worker_by_*`](https://github.com/openresty/lua-nginx-module#init_worker_by_lua_block) "
    protocols: All protocols
    description: Executed every time the {{ site.base_gateway }} plugin iterator is rebuilt (after changes to configure plugins).
  - function: "`certificate`"
    phase: "`certificate`"
    nginx: "[`ssl_certificate_by_*`](https://github.com/openresty/lua-nginx-module#ssl_certificate_by_lua_block)"
    protocols: |
        * `https`
        * `grpcs`
        * `wss`
    description: Executed during the SSL certificate serving phase of the SSL handshake.
  - function: "`rewrite`"
    phase: "`rewrite`"
    nginx: "[`rewrite_by_*`](https://github.com/openresty/lua-nginx-module#rewrite_by_lua_block)"
    protocols: All protocols
    description: |
        Executed for every request upon its reception from a client as a rewrite phase handler.
        
        In this phase, neither the Service nor the Consumer have been identified, hence this handler will only be executed if the plugin was configured as a global plugin.
  - function: "`access`"
    phase: "`access`"
    nginx: "[`access_by_*`](https://github.com/openresty/lua-nginx-module#access_by_lua_block)"
    protocols: |
        * `http(s)`
        * `grpc(s)`
        * `ws(s)`
    description: Executed for every request from a client and before it is being proxied to the upstream service.
  - function: "`response`"
    phase: "`response`"
    nginx: |
        * [`header_filter_by_*`](https://github.com/openresty/lua-nginx-module#header_filter_by_lua_block)
        * [`body_filter_by_*`](https://github.com/openresty/lua-nginx-module#body_filter_by_lua_block)
    protocols: |
        * `http(s)`
        * `grpc(s)`
    description: Replaces both `header_filter()` and `body_filter()`. Executed after the whole response has been received from the upstream service, but before sending any part of it to the client.
  - function: "`header_filter`"
    phase: "`header_filter`"
    nginx: "[`header_filter_by_*`](https://github.com/openresty/lua-nginx-module#header_filter_by_lua_block)"
    protocols: |
        * `http(s)`
        * `grpc(s)` 
    description: Executed when all response headers bytes have been received from the upstream service.
  - function: "`body_filter`"
    phase: "`body_filter`"
    nginx: "[`body_filter_by_*`](https://github.com/openresty/lua-nginx-module#body_filter_by_lua_block)"
    protocols: |
        * `http(s)`
        * `grpc(s)`
    description: Executed for each chunk of the response body received from the upstream service. Since the response is streamed back to the client, it can exceed the buffer size and be streamed chunk by chunk. This function can be called multiple times if the response is large. See the [`lua-nginx-module`](https://github.com/openresty/lua-nginx-module) documentation for more details.
  - function: "`ws_handshake`"
    phase: "`ws_handshake`"
    nginx: "[`access_by_*`](https://github.com/openresty/lua-nginx-module#access_by_lua_block)"
    protocols: "`ws(s)`"
    description: Executed for every request to a WebSocket service just before completing the WebSocket handshake.
  - function: "`ws_client_frame`"
    phase: "`ws_client_frame`"
    nginx: "[`content_by_*`](https://github.com/openresty/lua-nginx-module#content_by_lua_block)"
    protocols: "`ws(s)`"
    description: Executed for each WebSocket message received from the client.
  - function: "`ws_upstream_frame`"
    phase: "`ws_upstream_frame`"
    nginx: "[`content_by_*`](https://github.com/openresty/lua-nginx-module#content_by_lua_block)"
    protocols: "`ws(s)`"
    description: Executed for each WebSocket message received from the upstream service.
  - function: "`log`"
    phase: "`log`"
    nginx: "[`log_by_*`](https://github.com/openresty/lua-nginx-module#log_by_lua_block)"
    protocols: |
        * `http(s)` 
        * `grpc(s)` 
    description: Executed when the last response byte has been sent to the client.
  - function: "`ws_close`"
    phase: "`ws_close`"
    nginx: "[`log_by_*`](https://github.com/openresty/lua-nginx-module#log_by_lua_block)"
    protocols: "`ws(s)`"
    description: Executed after the WebSocket connection has been terminated.
{% endtable %}
{:.info}
> **Note:** If a module implements the `response` function, {{site.base_gateway}} will automatically activate the "buffered proxy" mode, as if the [`kong.service.request.enable_buffering()` function](/gateway/pdk/reference/kong.service.request/) had been called. Because of a current Nginx limitation, this doesn't work for HTTP/2 or gRPC upstreams.

To reduce unexpected behavior changes, {{site.base_gateway}} does not start if a plugin implements both `response` and either `header_filter` or `body_filter`.
{% endnavtab %}
{% navtab "Stream module" %}
The [Stream module](https://github.com/openresty/stream-lua-nginx-module) is used for Plugins written for TCP and UDP stream connections. It uses the following functions:
{% table %}
columns:
  - title: Function name
    key: function
  - title: "{{site.base_gateway}} phase"
    key: phase
  - title: Nginx directives
    key: nginx
  - title: Description
    key: description
rows: 
  - function: "`init_worker`"
    phase: "`init_worker`"
    nginx: "[`init_worker_by_*`](https://github.com/openresty/lua-nginx-module#init_worker_by_lua_block)"
    description: Executed upon every Nginx worker process's startup.
  - function: "`configure`"
    phase: |
        * `init_worker`
        * `timer`
    nginx: "[`init_worker_by_*`](https://github.com/openresty/lua-nginx-module#init_worker_by_lua_block)"
    description: Executed every time the {{ site.base_gateway }} plugin iterator is rebuilt (after changes to configure plugins).
  - function: "`preread`"
    phase: "`preread`"
    nginx: "[`preread_by_*`](https://github.com/openresty/stream-lua-nginx-module#preread_by_lua_block)"
    description: Executed once for every connection.
  - function: "`log`"
    phase: "`log`"
    nginx: "[`log_by_*`](https://github.com/openresty/lua-nginx-module#log_by_lua_block)"
    description: Executed once for each connection after it has been closed.
  - function: "`certificate`"
    phase: "`certificate`"
    nginx: "[`ssl_certificate_by_*`](https://github.com/openresty/lua-nginx-module#ssl_certificate_by_lua_block)"
    description: Executed during the SSL certificate serving phase of the SSL handshake.
{% endtable %}
{% endnavtab %}
{% endnavtabs %}

All of those functions, except `init_worker` and `configure`, take one parameter which is given
by {{site.base_gateway}} upon its invocation: the configuration of your plugin. This parameter
is a Lua table, and contains values defined by your users, according to your
plugin's schema (described in the `schema.lua` module). The `configure` is called with an array of all the enabled
plugin configurations for the particular plugin (or in case there is no active configurations
to plugin, a `nil` is passed). `init_worker` and `configure` happens outside
requests or frames, while the rest of the phases are bound to incoming request/frame.

Note that UDP streams don't have real connections.  {{site.base_gateway}} will consider all
packets with the same origin and destination host and port as a single
connection.  After a configurable time without any packet, the connection is
considered closed and the `log` function is executed.

{:.info}
> The `configure` handler was added in {{ site.base_gateway }} 3.5, and has been backported to 3.4 LTS. 
We are currently looking feedback for this new phase,
> and there is a slight possibility that its signature might change in a future.