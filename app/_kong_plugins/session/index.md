---
title: 'Session'
name: 'Session'

content_type: plugin

publisher: kong-inc
description: 'Support sessions for Kong authentication plugins.'


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: session.png

categories:
  - authentication

search_aliases:
  - sessions

related_resources:
  - text: Authenticate Consumers with the Key Auth and Sessions plugins
    url: /how-to/authenticate-consumers-with-session-and-key-auth/
---

The Session plugin can be used to manage browser sessions for APIs proxied
through the {{site.base_gateway}}. It provides configuration and management for
session data storage, encryption, renewal, expiry, and sending browser cookies.
It is built using
[lua-resty-session](https://github.com/bungle/lua-resty-session).

## How it works

The Session plugin can be configured globally or with an entity (for example, a [Gateway Service](/gateway/entities/service/) or a [Route](/gateway/entities/route/))
and is always used in conjunction with another [{{site.base_gateway}} authentication plugin](/plugins/?category=authentication). This
plugin is intended to work similarly to the [multiple authentication setup](/gateway/authentication/#using-multiple-authentication-methods).

When the Session plugin is enabled in conjunction with an authentication plugin,
it runs before credential verification. If no session is found, then the
authentication plugin runs again and credentials are checked normally. If the
credential verification is successful, then the Session plugin creates a new
session to use for subsequent requests.

When a new request comes in and a session is already present, then the Session
plugin attaches the `ngx.ctx` variables to let the authentication
plugin know that authentication has already occurred via session validation.
As this configuration is a logical `OR` scenario and you likely want to forbid anonymous access, you should configure the [Request Termination](/plugins/request-termination/) plugin on an anonymous Consumer. 
If not configured, unauthorized requests will be allowed through. 
For more information, see [multiple authentication](/gateway/authentication/#using-multiple-authentication-methods) and learn how to [prevent unauthorized access in a multi-auth scenario](/how-to/authenticate-consumers-with-session-and-key-auth/).

## Default settings

By default, the Session plugin favors security using a `Secure`, `HTTPOnly`, and `Samesite=Strict` cookie. [`config.cookie_domain`](/plugins/session/reference/#schema--config-cookie-domain) is automatically set using the Nginx
variable host, but can be overridden.

## Session data storage

The session data can be stored in the cookie itself (encrypted) by setting [`config.storage`](/plugins/session/reference/#schema--config-storage) to `cookie`,
or [inside {{site.base_gateway}} by setting `storage` to `kong`](#kong-storage-adapter). The session data stores these context
variables:

```
ngx.ctx.authenticated_consumer.id
ngx.ctx.authenticated_credential.id
ngx.ctx.authenticated_groups
```

The plugin also sets a `ngx.ctx.authenticated_session` for communication between
the [`access` and `header_filter` phases](/gateway/entities/plugin/#plugin-contexts) in the plugin.

## Authenticated groups

Authenticated groups from other
authentication plugins are stored in `ngx.ctx.authenticated_groups`. The Session plugin will store authenticated groups in the data of
the current session. Since the Session plugin runs before authentication
plugins, it also sets associated `authenticated_groups` headers.

## {{site.base_gateway}} storage adapter

 When `storage` is set to `kong`, the Session plugin extends the functionality of [lua-resty-session](https://github.com/bungle/lua-resty-session)
with its own session data storage adapter. This stores encrypted
session data into the current database strategy, and the cookie doesn't contain
any session data. 

Data stored in the database is encrypted, and the cookie contains only the session ID, expiration time, and HMAC signature. 
Sessions use the built-in {{site.base_gateway}} DAO `ttl` mechanism that destroys sessions after the specified `rolling_timeout` unless renewal occurs during normal browser activity. 
You can log out of the application via a XHR request (or something similar) to manually handle the redirects.

## Logging out

It is typical to provide users the ability to log out (as in, to manually destroy) their
current session. Logging out is possible with either query parameters or `POST` parameters in
the request URL. The [`config.logout_methods`](/plugins/session/reference/#schema--config-logout-methods) allows the plugin to limit logging
out based on the HTTP verb. When [`config.logout_query_arg`](/plugins/session/reference/#schema--config-logout-query-arg) is set, it checks the
presence of the URL query parameter specified. Likewise, when [`config.logout_post_arg`](/plugins/session/reference/#schema--config-logout-post-arg)
is set, it checks for the presence of the specified variable in the request body.

When there's a session
present and the incoming request is a logout request, the Session plugin
returns a 200 before continuing in the plugin run loop, and the request doesn't
continue to the upstream.

## Known limitations

Due to limitations of OpenResty, the `header_filter` phase can't connect to the
database. This poses a problem for initial retrieval of a cookie (fresh session).
There is a small window of time where the cookie is sent to client, but the database
insert hasn't been committed yet because the database call is in a `ngx.timer` thread.

The workaround for this issue is to wait for some interval of time (~100-500ms) after
`Set-Cookie` header is sent to the client before making subsequent requests. This is
_not_ a problem during session renewal period, as renewal happens in the `access` phase.

