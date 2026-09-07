---
title: How to add any variable to Kong access logs
content_type: support
description: "Using the following configurations, it is possible to add any value that can be set from a `pre-function` plugin to the access logs."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I add a custom variable (like the route name) to Kong's access logs?
  a: |
    Set a temporary Nginx variable (for example `$foo`) via a custom Nginx template, reference it in `nginx_http_log_format`, then populate it from a `pre-function` plugin using `kong.router.get_route()`. That PDK call requires `untrusted_lua: lax`, since Kong Gateway 3.14.0.0 defaults `untrusted_lua` to `strict`, under which `kong.router` is absent from the sandbox and the plugin fails at request time.
related_resources: []
---

## Overview

How can I add extra details to the access log?

## Steps

Using the following configurations, it is possible to add any value that can be set from a `pre-function` plugin, to the access logs.

In this example we will be adding the route name using the `get_route()` function from the Kong PDK.

This function returns a route object which allows access to the various properties of the route.

Specifically we will be using `route.name` to retrieve the route name.

1. Use a custom nginx template to set a temporary variable which will be used later

   The variable that the access log is reading from, needs to exist in the `nginx.conf` file prior to Kong starting, therefore a custom template is needed to set/create the variable first.

   In the Kong proxy block, we add the line: `set $foo 'hellofromnginxtemplate';`

   Example:

   Take Kong's default Nginx template (`kong/templates/nginx.lua`, inlining the contents of `kong/templates/nginx_kong.lua` in place of its `include 'nginx-kong.conf';` line, since that included file is otherwise always regenerated from the stock template and is not itself overridable) and add the `set $foo ...;` line inside the `server { server_name kong; ... }` block that handles the proxy listeners, for example:

   ```nginx
   server {
       server_name kong;
       set $foo 'hellofromnginxtemplate';
   > for _, entry in ipairs(proxy_listeners) do
       listen $(entry.listener);
   > end
       ...
   ```

   Save the full, modified template to a file and start (or restart) Kong with `kong start --nginx-conf /path/to/custom_nginx.template` (or the equivalent `KONG_NGINX_CONF`/`--nginx-conf` mechanism for your deployment) so the variable exists before the access log format below references it.

2. Modify the access log format using the following `kong.conf` directives

   ```ini
   nginx_http_log_format="show_everything '\$time_iso8601 - \$bytes_sent - \$request - \$status - \$foo'"
   proxy_access_log=/dev/stdout show_everything
   ```

3. Restart Kong

4. Create a pre-function plugin and assign the following code to the access phase

   ```lua
   local kong = kong
   local ngx = ngx
   local route = kong.router.get_route()
   ngx.var.foo = route.name
   ```

Note: `kong.router` is only available under `untrusted_lua = lax` (or `on`) — Kong Gateway 3.14.0.0 defaults `untrusted_lua` to `strict`, under which `kong.router` is entirely absent from the sandboxed `kong` table, and the snippet above fails at request time with `attempt to index field 'router' (a nil value)` (a `500` to the client). Set `untrusted_lua: lax` (`KONG_UNTRUSTED_LUA=lax`) before creating this plugin, or the snippet above will not work.
